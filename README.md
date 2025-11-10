# WireGuard VPN Mesh sur Scaleway (Simulation VPC Peering)

Infrastructure as Code (Terraform) déployant une architecture VPN mesh avec WireGuard interconnectant plusieurs VPCs Scaleway.

##  Objectif

Créer une architecture réseau sécurisée permettant à des ressources dans différents VPCs Scaleway de communiquer entre elles via un tunnel VPN WireGuard, avec un hub central gérant le routage NAT vers Internet.

##  Architecture

```
                    ┌──────────────────────────────────┐
                    │             INTERNET             │
                    └──────────────--┬─────────────────┘
                                     │
                    ┌──────────────--┴─────────────────┐
                    │     Public Gateway (Bastion SSH) │
                    │     IP: Public IP                │
                    └──────────────────────────────────┘
                                   
    ┌──────────────────────────────┼────────────────────────────┐
    │                              │                            │
    │                              │                            │
┌───▼────────────┐      ┌──────────▼──────────┐      ┌──────────▼──────────┐
│   VPC HUB      │      │   VPC SPOKE 01      │      │   VPC SPOKE 02      │
│ 172.16.188.0/22│      │  172.16.32.0/22     │      │  172.16.64.0/23     │
│                │      │                     │      │  172.16.66.0/23     │
│ ┌────────────┐ │      │ ┌─────────────────┐ │      │ ┌─────────────────┐ │
│ │WireGuard   │ │      │ │WireGuard        │ │      │ │WireGuard        │ │
│ │Hub (NAT)   │◄├──────┤►│Spoke-01         │ │◄─────┤►│Spoke-02 (NAT)   │ │
│ │192.168.1.1 │ │      │ │192.168.1.2      │ │      │ │192.168.1.3      │ │
│ │            │ │      │ │                 │ │      │ │                 │ │
│ └────────────┘ │      │ └────────┬────────┘ │      │ └─────────────────┘ │
│                │      │          │          │      │          │          │
│                │      │ ┌────────▼────────┐ │      │ ┌────────▼────────┐ │
│                │      │ │PostgreSQL RDB   │ │      │ │Postgres Client  │ │
│                │      │ │(Private only)   │ │      │ │                 │ │
│                │      │ └─────────────────┘ │      │ └─────────────────┘ │
└────────────────┘      └─────────────────────┘      └─────────────────────┘

Légende:
────────  Tunnel WireGuard (192.168.1.0/24)
◄──────► Communication bidirectionnelle
```

##  Composants

### VPCs et Réseaux

- **VPC Hub** (`172.16.188.0/22`) : Point central du mesh, gère le NAT vers Internet
- **VPC Spoke 01** (`172.16.32.0/22`) : Héberge la base de données PostgreSQL
- **VPC Spoke 02** : Deux réseaux privés & Héberge le client (Linux) devant joindre la BDD sur le VPC SPOKE01
  - Réseau A : `172.16.64.0/23`
  - Réseau B : `172.16.66.0/23`

### Instances WireGuard

| Instance | IP VPN | Rôle | Type |
|----------|---------|------|------|
| wireguard-hub | 192.168.1.1 | Gateway NAT central | PLAY2-MICRO |
| wireguard-spoke-01 | 192.168.1.2 | Routeur VPN Spoke 01 | PLAY2-MICRO |
| wireguard-spoke-02 | 192.168.1.3 | Gateway NAT Spoke 02 | PLAY2-MICRO |

### Ressources Applicatives

- **PostgreSQL RDB** : Base de données managée dans VPC Spoke 01 (accessible uniquement via réseau privé)
- **Postgres Client** : Instance dans VPC Spoke 02 accédant à la DB via le tunnel VPN

##  Sécurité

### Groupes de Sécurité

- **sg-wireguard** : Pour les instances WireGuard
  - SSH (TCP/22) depuis Internet
  - WireGuard (UDP/52345) depuis Internet
  - Trafic interne VPC (172.16.0.0/16)
  - Trafic réseau VPN (192.168.1.0/24)

- **sg-client** : Pour les instances clientes
  - SSH (TCP/22) depuis Internet
  - Trafic interne VPC (172.16.0.0/16)
  - Trafic réseau VPN (192.168.1.0/24)

### ACL Base de Données

- Accès autorisé depuis le réseau WireGuard (`192.168.1.0/24`)
- Accès autorisé depuis tous les VPCs privés (`172.16.0.0/16`)

##  Déploiement

### Prérequis
- Terraform >= 1.0
- Compte Scaleway avec credentials configurés
- Clé SSH publique

### Variables Requises

Créer un fichier `terraform.tfvars` :

```hcl
ssh_public_key = "ssh-rsa AAAA..."
zone           = "fr-par-1"
region         = "fr-par"
wireguard_port = 52345
wireguard_mtu  = 1380
```

### Installation

```bash
# Initialiser Terraform
terraform init

# Vérifier le plan
terraform plan

# Déployer l'infrastructure
terraform apply
```

### Accès aux Ressources

```bash
# Récupérer les IPs publiques
terraform output public_ips

# Se connecter aux instances WireGuard
ssh -J BASTIONIP:61000 ubuntu@<PRIVATE_IP>

# Vérifier le statut WireGuard sur une instance
ssh -J BASTIONIP:61000 ubuntu@<PRIVATE_IP>'sudo wg show'

# Se connecter au client PostgreSQL
ssh -J BASTIONIP:61000 ubuntu@<PRIVATE_IP>

# Tester la connexion à la base de données
dbconnect  # Alias configuré automatiquement
```

## Outputs

L'infrastructure expose les outputs suivants :

- `public_ips` : IPs publiques de toutes les instances
- `database_connection` : Informations de connexion PostgreSQL (sensible)
- `database_password` : Mot de passe DB (sensible)
- `ssh_commands` : Commandes SSH prêtes à l'emploi
- `wireguard_network` : Configuration réseau VPN
- `vpn_subnets` : Sous-réseaux accessibles via VPN
- `wireguard_status_commands` : Commandes de diagnostic

##  Configuration Technique

### Routage WireGuard

- **Hub** : Route et NAT tout le trafic des spokes vers Internet
- **Spoke 01** : Route tout le trafic (`0.0.0.0/0`) vers le hub
- **Spoke 02** : Route tout le trafic (`0.0.0.0/0`) vers le hub et NAT les réseaux locaux

### NAT et Forwarding

- IP forwarding activé sur toutes les instances WireGuard
- MASQUERADE configuré pour le NAT sortant
- MSS clamping pour éviter la fragmentation des paquets
- Routes statiques vers les réseaux privés

### Monitoring

- Script `wg-monitor.sh` sur Spoke-01 pour redémarrage automatique
- Script `wg-stats.sh` pour diagnostic réseau
- Logs dans `/var/log/wireguard-*.log`

## Maintenance

### Vérifier la Connectivité

```bash
# Depuis n'importe quelle instance WireGuard
sudo wg show

# Vérifier les routes
ip route

# Tester la connectivité vers un autre VPC
ping <IP_DESTINATION>
```

### Redémarrer WireGuard

```bash
sudo systemctl restart wg-quick@wg0
```

### Consulter les Logs

```bash
# Logs système
sudo journalctl -u wg-quick@wg0 -f

# Logs monitoring (Spoke-01)
tail -f /var/log/wireguard-monitor.log
```

## Notes Importantes

1. **Gateway** : La Public Gateway n'injecte PAS de route par défaut (pas de `push_default_route`)
2. **NAT** : Le NAT est géré exclusivement par WireGuard, pas par la Gateway
3. **MTU** : MTU configuré à 1380 pour éviter la fragmentation dans les tunnels
4. **Keepalive** : PersistentKeepalive à 25s pour maintenir les tunnels actifs
5. **Sécurité** : Reverse path filtering désactivé pour permettre le routage asymétrique

##  Nettoyage

```bash
# Détruire toute l'infrastructure
terraform destroy
```

⚠️ **Attention** : Cette commande supprime définitivement toutes les ressources, y compris la base de données PostgreSQL et ses données.

## Providers Terraform

- **scaleway** (~> 2.60.1) : Ressources Scaleway
- **wireguard** (~> 0.4.0) : Génération de clés WireGuard
- **random** (~> 3.6) : Génération de mots de passe
- **null** (~> 3.2) : Opérations auxiliaires

## Licence

Ce projet est fourni tel quel à des fins de démonstration et d'apprentissage.

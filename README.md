# n8n avec Docker Compose

Configuration Docker Compose pour n8n avec PostgreSQL et timezone Europe/Brussels.

## Prérequis

- Un serveur Linux (Ubuntu 20.04/22.04 ou Debian 11/12 recommandé)
- Accès root ou sudo
- Au moins 2 GB de RAM
- Au moins 10 GB d'espace disque disponible

## Installation de Docker et Docker Compose

### Sur Ubuntu/Debian

```bash
# Mettre à jour les paquets
sudo apt update
sudo apt upgrade -y

# Installer les dépendances
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Ajouter la clé GPG officielle de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Ajouter le dépôt Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installer Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Vérifier l'installation
docker --version
docker compose version

# Ajouter votre utilisateur au groupe docker (optionnel)
sudo usermod -aG docker $USER
newgrp docker
```

### Sur Fedora/CentOS/RHEL

```bash
# Installer les dépendances
sudo dnf -y install dnf-plugins-core

# Ajouter le dépôt Docker
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Installer Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Démarrer Docker
sudo systemctl start docker
sudo systemctl enable docker

# Vérifier l'installation
docker --version
docker compose version
```

## Installation de n8n

### 1. Créer le répertoire du projet

```bash
mkdir -p ~/n8n
cd ~/n8n
```

### 2. Créer les fichiers de configuration

Copiez le contenu de `docker-compose.yml` et `.env.example` dans ce répertoire.

### 3. Configurer les variables d'environnement

```bash
# Copier le fichier d'exemple
cp .env.example .env

# Modifier le fichier .env avec vos paramètres
nano .env
```

**Important:** Changez au minimum le `POSTGRES_PASSWORD` et `DB_POSTGRESDB_PASSWORD` avec un mot de passe sécurisé !

### 4. Démarrer les services

```bash
# Démarrer en mode détaché
docker compose up -d

# Vérifier les logs
docker compose logs -f

# Vérifier le statut
docker compose ps
```

### 5. Générer les certificats SSL (pour HTTPS)

```bash
# Générer les certificats SSL autosignés
./generate-ssl.sh
```

Ce script va créer les certificats SSL nécessaires pour accéder à n8n via HTTPS.

### 6. Configurer le fichier hosts

Ajoutez l'entrée suivante à votre fichier `/etc/hosts` :

```bash
# Linux/macOS
sudo echo "127.0.0.1 n8n.local" >> /etc/hosts

# Windows (en tant qu'administrateur)
echo 127.0.0.1 n8n.local >> C:\Windows\System32\drivers\etc\hosts
```

### 7. Accéder à n8n

Ouvrez votre navigateur et accédez à :
```
https://n8n.local
```

**Note :** Votre navigateur affichera un avertissement de sécurité pour le certificat autosigné. Cliquez sur "Avancé" puis "Accepter le risque" pour continuer.

Pour un accès sans SSL (non recommandé), vous pouvez également accéder via :
```
http://localhost:5678
```

## Configuration HTTPS avec Nginx

Cette configuration inclut un reverse proxy Nginx avec HTTPS pour une utilisation sécurisée de n8n.

### Composants

- **Nginx** : Reverse proxy avec SSL/TLS
- **Certificats SSL** : Autosignés pour le développement local
- **Redirection** : HTTP → HTTPS automatique

### Génération manuelle des certificats

Si vous devez régénérer les certificats :

```bash
# Créer le dossier SSL
mkdir -p nginx/ssl

# Générer la clé privée
openssl genrsa -out nginx/ssl/n8n.local.key 2048

# Générer le certificat autosigné
openssl req -new -x509 -key nginx/ssl/n8n.local.key -out nginx/ssl/n8n.local.crt -days 365 \
    -subj "/C=BE/ST=Brussels/L=Brussels/O=N8N Local/OU=IT Department/CN=n8n.local" \
    -addext "subjectAltName=DNS:n8n.local,DNS:localhost,IP:127.0.0.1"

# Définir les permissions
chmod 644 nginx/ssl/n8n.local.crt
chmod 600 nginx/ssl/n8n.local.key
```

### Structure des fichiers

```
n8n_Docker_compose/
├── docker-compose.yml
├── generate-ssl.sh
├── nginx/
│   ├── nginx.conf
│   └── ssl/
│       ├── n8n.local.crt    # Certificat public
│       └── n8n.local.key    # Clé privée (à protéger)
├── .env
└── README.md
```

## Commandes utiles

Pour plus d'informations, consultez la [documentation officielle Docker de n8n](https://docs.n8n.io/hosting/installation/docker/).

### Mise à jour de n8n avec Docker Compose

Selon la documentation officielle, pour mettre à jour n8n :

```bash
# 1. Naviguer vers le répertoire contenant docker-compose.yml
cd ~/n8n

# 2. Arrêter les conteneurs
docker compose stop

# 3. Télécharger les dernières images
docker compose pull

# 4. Redémarrer avec les nouvelles images
docker compose up -d

# 5. Supprimer les anciennes images (optionnel)
docker image prune
```

### Gérer les conteneurs

```bash
# Arrêter les services
docker compose stop

# Démarrer les services
docker compose start

# Redémarrer les services
docker compose restart

# Arrêter et supprimer les conteneurs
docker compose down

# Arrêter et supprimer les conteneurs + volumes (ATTENTION: supprime les données)
docker compose down -v
```

### Voir les logs

```bash
# Tous les services
docker compose logs -f

# Seulement n8n
docker compose logs -f n8n

# Seulement PostgreSQL
docker compose logs -f postgres
```

### Sauvegardes

```bash
# Sauvegarder la base de données
docker compose exec postgres pg_dump -U n8n n8n > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurer la base de données
docker compose exec -T postgres psql -U n8n n8n < backup_20240101_120000.sql
```

## Dépannage

### Les conteneurs ne démarrent pas

```bash
# Vérifier les logs
docker compose logs

# Vérifier l'état des services
docker compose ps
```

### Problèmes de connexion à PostgreSQL

```bash
# Vérifier que PostgreSQL est accessible
docker compose exec postgres pg_isready -U n8n

# Se connecter à PostgreSQL
docker compose exec postgres psql -U n8n -d n8n
```

### Réinitialiser complètement l'installation

```bash
# ATTENTION: ceci supprime toutes les données
docker compose down -v
docker compose up -d
```

### Tester les certificats SSL

```bash
# Vérifier l'expiration d'un certificat
openssl x509 -in nginx/ssl/n8n.local.crt -text -noout | grep "Not After"

# Tester la connexion SSL
openssl s_client -connect n8n.local:443 -servername n8n.local

# Vérifier la configuration Nginx
docker compose exec nginx nginx -t
```

## Sécurité

- Changez le mot de passe PostgreSQL par défaut
- **HTTPS configuré** : Cette configuration inclut déjà Nginx avec HTTPS
- **Certificats SSL** : Utilisez des certificats valides en production (Let's Encrypt recommandé)
- Limitez l'accès aux ports avec un firewall
- Effectuez des sauvegardes régulières
- **Clés privées** : Les fichiers `.key` sont automatiquement exclus de Git

### Notes de sécurité SSL

⚠️ **Développement uniquement** : Les certificats autosignés ne conviennent que pour le développement local.

✅ **Production** : Utilisez des certificats valides :
- Let's Encrypt (gratuit)
- Certificats d'entreprise
- Certificats commerciaux

### Certificats Let's Encrypt (production)

Pour la production, remplacez les certificats autosignés par des certificats Let's Encrypt :

```bash
# Installer certbot
sudo apt install certbot python3-certbot-nginx

# Obtenir un certificat (remplacez votre-domaine.com)
sudo certbot --nginx -d votre-domaine.com

# Le renouvellement automatique est configuré via cron
```

## Support

- Documentation officielle n8n: https://docs.n8n.io/
- Forum communautaire: https://community.n8n.io/
- GitHub: https://github.com/n8n-io/n8n
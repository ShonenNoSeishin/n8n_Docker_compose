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

### 5. Accéder à n8n

Ouvrez votre navigateur et accédez à :
```
http://localhost:5678
```

Ou remplacez `localhost` par l'adresse IP de votre serveur.

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

## Sécurité

- Changez le mot de passe PostgreSQL par défaut
- Utilisez un reverse proxy (Nginx, Traefik) avec HTTPS en production
- Limitez l'accès au port 5678 avec un firewall
- Effectuez des sauvegardes régulières

## Support

- Documentation officielle n8n: https://docs.n8n.io/
- Forum communautaire: https://community.n8n.io/
- GitHub: https://github.com/n8n-io/n8n
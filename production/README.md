# n8n Production avec Nginx et SSL

Configuration Docker Compose pour n8n en production avec reverse proxy Nginx et certificats SSL Let's Encrypt via Certbot.

## Prérequis

- Un serveur Linux avec une adresse IP publique
- Docker et Docker Compose installés (voir README principal)
- Un nom de domaine pointant vers votre serveur (enregistrement A)
- Ports 80 et 443 ouverts dans votre firewall
- Au moins 2 GB de RAM
- Au moins 20 GB d'espace disque disponible

## Structure des fichiers

```
n8n-production/
├── docker-compose.yml
├── .env
├── .env.example
├── .gitignore
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       └── n8n.conf.template
└── README-PRODUCTION.md
```

## Installation

### 1. Configurer le nom de domaine

Avant de commencer, assurez-vous que votre nom de domaine pointe vers l'IP de votre serveur :

```bash
# Vérifier la résolution DNS
nslookup n8n.votredomaine.com
# ou
dig n8n.votredomaine.com
```

### 2. Créer la structure des dossiers

```bash
mkdir -p ~/n8n-production/nginx/conf.d
cd ~/n8n-production
```

### 3. Configurer les variables d'environnement

```bash
# Copier le fichier d'exemple
cp .env.example .env

# Éditer le fichier .env
nano .env
```

**Variables importantes à configurer :**

- `POSTGRES_PASSWORD` : Mot de passe PostgreSQL sécurisé
- `N8N_DOMAIN` : Votre nom de domaine (ex: n8n.votredomaine.com)
- `CERTBOT_EMAIL` : Votre email pour Let's Encrypt
- `N8N_BASIC_AUTH_USER` et `N8N_BASIC_AUTH_PASSWORD` : Si vous souhaitez ajouter une authentification basique

### 4. Générer la configuration Nginx

```bash
# Remplacer ${N8N_DOMAIN} dans le template par votre domaine
# Lisez d'abord votre domaine depuis .env
source .env

# Générer le fichier de configuration
sed "s/\${N8N_DOMAIN}/$N8N_DOMAIN/g" nginx/conf.d/n8n.conf.template > nginx/conf.d/n8n.conf

# Vérifier le fichier généré
cat nginx/conf.d/n8n.conf
```

### 5. Démarrer n8n sans SSL (première étape)

Avant d'activer Nginx et SSL, démarrez d'abord n8n seul :

```bash
# Démarrer uniquement PostgreSQL et n8n
docker compose up -d postgres n8n

# Vérifier que tout fonctionne
docker compose logs -f
```

### 6. Obtenir le certificat SSL

Une fois n8n démarré, décommentez les sections Nginx et Certbot dans `docker-compose.yml` :

```yaml
# Décommentez ces lignes dans docker-compose.yml :
  nginx:
    # ... (toute la section nginx)
  
  certbot:
    # ... (toute la section certbot)

# Et les volumes :
  certbot_www:
    driver: local
  certbot_conf:
    driver: local
```

Ensuite, obtenez le certificat :

```bash
# Démarrer Nginx (sans SSL pour le moment)
docker compose up -d nginx

# Obtenir le certificat SSL avec Certbot
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email $CERTBOT_EMAIL \
  --agree-tos \
  --no-eff-email \
  -d $N8N_DOMAIN
```

Si la commande réussit, vous verrez un message confirmant la création du certificat.

### 7. Activer SSL dans Nginx

Une fois le certificat obtenu, rechargez Nginx :

```bash
# Redémarrer Nginx pour charger le certificat
docker compose restart nginx

# Vérifier les logs
docker compose logs nginx
```

### 8. Tester l'accès

Ouvrez votre navigateur et accédez à :
```
https://n8n.votredomaine.com
```

Vous devriez voir l'interface n8n avec un certificat SSL valide (cadenas vert).

## Renouvellement automatique du certificat

Le conteneur Certbot est configuré pour renouveler automatiquement le certificat tous les 12 heures. Les certificats Let's Encrypt sont valides 90 jours, et Certbot les renouvelle automatiquement 30 jours avant expiration.

Pour forcer un renouvellement manuel :

```bash
# Renouveler le certificat manuellement
docker compose run --rm certbot renew

# Recharger Nginx pour utiliser le nouveau certificat
docker compose exec nginx nginx -s reload
```

## Commandes utiles

### Gérer les services

```bash
# Arrêter tous les services
docker compose stop

# Démarrer tous les services
docker compose start

# Redémarrer tous les services
docker compose restart

# Voir l'état des services
docker compose ps
```

### Logs

```bash
# Tous les services
docker compose logs -f

# Service spécifique
docker compose logs -f nginx
docker compose logs -f n8n
docker compose logs -f postgres
```

### Mise à jour

```bash
# Arrêter les services
docker compose stop

# Télécharger les nouvelles images
docker compose pull

# Redémarrer avec les nouvelles images
docker compose up -d

# Nettoyer les anciennes images
docker image prune -f
```

### Vérifier le certificat SSL

```bash
# Voir les détails du certificat
docker compose exec certbot certbot certificates

# Tester le renouvellement sans vraiment renouveler
docker compose run --rm certbot renew --dry-run
```

## Sauvegardes

### Base de données

```bash
# Créer une sauvegarde
docker compose exec postgres pg_dump -U n8n n8n > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurer une sauvegarde
docker compose exec -T postgres psql -U n8n n8n < backup_20240101_120000.sql
```

### Données n8n et certificats SSL

```bash
# Sauvegarder les volumes Docker
docker run --rm \
  -v n8n-production_n8n_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/n8n_data_$(date +%Y%m%d).tar.gz -C /data .

docker run --rm \
  -v n8n-production_certbot_conf:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/certbot_$(date +%Y%m%d).tar.gz -C /data .
```

## Dépannage

### Nginx ne démarre pas

```bash
# Vérifier la configuration Nginx
docker compose exec nginx nginx -t

# Voir les logs d'erreur
docker compose logs nginx
```

### Certificat SSL non valide

```bash
# Vérifier que le certificat existe
docker compose exec certbot ls -la /etc/letsencrypt/live/

# Vérifier les logs Certbot
docker compose logs certbot
```

### Erreur "too many requests" de Let's Encrypt

Let's Encrypt a des limites de taux. Si vous avez trop de tentatives échouées :
- Attendez 1 heure avant de réessayer
- Utilisez `--dry-run` pour tester sans consommer votre quota
- Vérifiez que votre DNS est correctement configuré avant de demander un certificat

### n8n n'est pas accessible

```bash
# Vérifier que tous les conteneurs fonctionnent
docker compose ps

# Vérifier que n8n répond en interne
docker compose exec nginx curl -I http://n8n:5678

# Vérifier les logs n8n
docker compose logs n8n
```

## Sécurité supplémentaire

### Configurer le firewall (UFW)

```bash
# Installer UFW si nécessaire
sudo apt install ufw

# Autoriser SSH (IMPORTANT avant d'activer le firewall !)
sudo ufw allow 22/tcp

# Autoriser HTTP et HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Activer le firewall
sudo ufw enable

# Vérifier le statut
sudo ufw status
```

### Fail2ban pour protection SSH

```bash
# Installer fail2ban
sudo apt install fail2ban

# Créer une configuration locale
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Éditer et activer la protection SSH
sudo nano /etc/fail2ban/jail.local

# Démarrer fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
```

### Authentification basique n8n

Décommentez dans `.env` :

```bash
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=votre_mot_de_passe_tres_securise
```

Puis décommentez les lignes correspondantes dans `docker-compose.yml` et redémarrez :

```bash
docker compose restart n8n
```

## Surveillance

### Vérifier l'utilisation des ressources

```bash
# Voir l'utilisation CPU/RAM de chaque conteneur
docker stats

# Voir l'espace disque utilisé par Docker
docker system df -v
```

### Logs de monitoring

```bash
# Surveiller les logs Nginx en temps réel
docker compose logs -f nginx

# Surveiller les logs n8n
docker compose logs -f n8n | grep -i error
```

## Migration vers ce setup

Si vous migrez depuis une installation existante :

1. Sauvegardez votre base de données actuelle
2. Sauvegardez le dossier `/home/node/.n8n`
3. Arrêtez votre ancienne installation
4. Suivez ce guide d'installation
5. Restaurez votre base de données et données n8n

## Support et documentation

- [Documentation n8n](https://docs.n8n.io/)
- [Documentation Nginx](https://nginx.org/en/docs/)
- [Documentation Certbot](https://certbot.eff.org/docs/)
- [Forum n8n](https://community.n8n.io/)

## Notes importantes

- Les certificats Let's Encrypt sont valides 90 jours
- Le renouvellement automatique est configuré dans le conteneur Certbot
- Gardez votre email à jour pour recevoir les notifications d'expiration
- Faites des sauvegardes régulières de votre base de données et du dossier n8n
- Surveillez les logs pour détecter les problèmes rapidement
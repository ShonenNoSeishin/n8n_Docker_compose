#!/bin/bash

# Script d'installation automatique pour n8n en production
# Usage: ./setup.sh

set -e

echo "=========================================="
echo "Installation de n8n en Production"
echo "=========================================="
echo ""

# Vérifier que le script est exécuté en tant que root ou avec sudo
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
   echo "Ce script nécessite les privilèges sudo. Veuillez l'exécuter avec sudo ou en tant que root."
   exit 1
fi

# Vérifier que le fichier .env existe
if [ ! -f .env ]; then
    echo "❌ Erreur: Le fichier .env n'existe pas."
    echo "Copiez .env.example vers .env et configurez-le avant de continuer."
    exit 1
fi

# Charger les variables d'environnement
source .env

# Vérifier que les variables critiques sont définies
if [ -z "$N8N_DOMAIN" ] || [ "$N8N_DOMAIN" = "n8n.votredomaine.com" ]; then
    echo "❌ Erreur: N8N_DOMAIN n'est pas configuré dans .env"
    echo "Veuillez définir votre nom de domaine avant de continuer."
    exit 1
fi

if [ -z "$CERTBOT_EMAIL" ] || [ "$CERTBOT_EMAIL" = "votre.email@exemple.com" ]; then
    echo "❌ Erreur: CERTBOT_EMAIL n'est pas configuré dans .env"
    echo "Veuillez définir votre email avant de continuer."
    exit 1
fi

if [ "$POSTGRES_PASSWORD" = "CHANGEZ_CE_MOT_DE_PASSE_TRES_SECURISE" ]; then
    echo "⚠️  Attention: Vous utilisez le mot de passe PostgreSQL par défaut!"
    read -p "Voulez-vous continuer quand même? (pas recommandé) [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ Configuration validée"
echo ""
echo "Domaine: $N8N_DOMAIN"
echo "Email: $CERTBOT_EMAIL"
echo ""

# Créer les dossiers nécessaires
echo "📁 Création des dossiers..."
mkdir -p nginx/conf.d

# Générer la configuration Nginx depuis le template
echo "⚙️  Génération de la configuration Nginx..."
if [ -f nginx/conf.d/n8n.conf.template ]; then
    sed "s/\${N8N_DOMAIN}/$N8N_DOMAIN/g" nginx/conf.d/n8n.conf.template > nginx/conf.d/n8n.conf
    echo "✅ Configuration Nginx générée: nginx/conf.d/n8n.conf"
else
    echo "❌ Erreur: Template nginx/conf.d/n8n.conf.template introuvable"
    exit 1
fi

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Installez-le d'abord."
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé. Installez-le d'abord."
    exit 1
fi

# Étape 1: Démarrer PostgreSQL et n8n
echo ""
echo "🚀 Étape 1: Démarrage de PostgreSQL et n8n..."
docker compose up -d postgres n8n

echo "⏳ Attente du démarrage des services (30 secondes)..."
sleep 30

# Vérifier que les services sont en cours d'exécution
if ! docker compose ps | grep -q "n8n.*Up"; then
    echo "❌ Erreur: n8n n'a pas démarré correctement"
    docker compose logs n8n
    exit 1
fi

echo "✅ PostgreSQL et n8n sont démarrés"

# Étape 2: Démarrer Nginx (sans SSL)
echo ""
echo "🚀 Étape 2: Démarrage de Nginx..."
docker compose up -d nginx

sleep 5

# Vérifier que Nginx fonctionne
if ! docker compose ps | grep -q "nginx.*Up"; then
    echo "❌ Erreur: Nginx n'a pas démarré correctement"
    docker compose logs nginx
    exit 1
fi

echo "✅ Nginx est démarré"

# Étape 3: Obtenir le certificat SSL
echo ""
echo "🔒 Étape 3: Obtention du certificat SSL..."
echo "Cela peut prendre quelques minutes..."

docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email "$CERTBOT_EMAIL" \
  --agree-tos \
  --no-eff-email \
  -d "$N8N_DOMAIN"

if [ $? -eq 0 ]; then
    echo "✅ Certificat SSL obtenu avec succès"
else
    echo "❌ Erreur lors de l'obtention du certificat SSL"
    echo "Vérifiez que:"
    echo "  1. Votre domaine pointe vers ce serveur"
    echo "  2. Les ports 80 et 443 sont ouverts"
    echo "  3. Vous n'avez pas dépassé les limites de Let's Encrypt"
    exit 1
fi

# Étape 4: Redémarrer Nginx avec SSL
echo ""
echo "🔄 Étape 4: Activation du SSL..."
docker compose restart nginx

sleep 5

# Vérification finale
echo ""
echo "=========================================="
echo "✅ Installation terminée avec succès!"
echo "=========================================="
echo ""
echo "Votre instance n8n est accessible à:"
echo "👉 https://$N8N_DOMAIN"
echo ""
echo "Commandes utiles:"
echo "  - Voir les logs: docker compose logs -f"
echo "  - Arrêter: docker compose stop"
echo "  - Redémarrer: docker compose restart"
echo ""
echo "Le certificat SSL sera renouvelé automatiquement."
echo ""
echo "⚠️  N'oubliez pas de:"
echo "  1. Configurer un firewall (ufw)"
echo "  2. Faire des sauvegardes régulières"
echo "  3. Surveiller les logs"
echo ""
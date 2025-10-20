#!/bin/bash

# Script pour générer des certificats SSL autosignés pour n8n.local

set -e

DOMAIN="n8n.local"
SSL_DIR="./nginx/ssl"
KEY_FILE="$SSL_DIR/$DOMAIN.key"
CERT_FILE="$SSL_DIR/$DOMAIN.crt"

echo "🔐 Génération des certificats SSL autosignés pour $DOMAIN"

# Créer le dossier SSL s'il n'existe pas
mkdir -p "$SSL_DIR"

# Générer la clé privée
echo "📝 Génération de la clé privée..."
openssl genrsa -out "$KEY_FILE" 2048

# Générer le certificat autosigné
echo "📜 Génération du certificat autosigné..."
openssl req -new -x509 -key "$KEY_FILE" -out "$CERT_FILE" -days 365 \
    -subj "/C=BE/ST=Brussels/L=Brussels/O=N8N Local/OU=IT Department/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:$DOMAIN,DNS:localhost,IP:127.0.0.1"

# Définir les permissions appropriées
chmod 644 "$CERT_FILE"
chmod 600 "$KEY_FILE"

echo "✅ Certificats SSL générés avec succès !"
echo "   - Certificat : $CERT_FILE"
echo "   - Clé privée : $KEY_FILE"
echo ""
echo "🏠 N'oubliez pas d'ajouter $DOMAIN à votre fichier /etc/hosts :"
echo "   127.0.0.1 $DOMAIN"
echo ""
echo "🚀 Vous pouvez maintenant démarrer n8n avec :"
echo "   docker compose up -d"
echo ""
echo "🌐 Accédez à n8n via : https://$DOMAIN"
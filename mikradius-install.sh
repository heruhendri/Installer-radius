#!/bin/bash

echo "=========================================="
echo "     MikRadius Auto Installer (Nginx)"
echo "=========================================="

# Input manual domain
read -p "Masukkan domain untuk DaloRADIUS (contoh: radius.domain.com): " DOMAIN
read -p "Masukkan email untuk SSL Certbot: " EMAIL
read -p "Masukkan password DB Radius (Enter untuk default: radius123): " DBPASS

DBPASS=${DBPASS:-radius123}

echo "Domain      : $DOMAIN"
echo "Email SSL   : $EMAIL"
echo "DB Password : $DBPASS"
echo "------------------------------------------"
sleep 2

# Update & dependencies
apt update -y
apt upgrade -y
apt install -y nginx mariadb-server php php-fpm php-mysql php-xml php-gd php-curl php-mbstring php-pear php-db certbot python3-certbot-nginx git unzip freeradius freeradius-mysql freeradius-utils ufw

# Firewall
ufw allow OpenSSH
ufw allow http
ufw allow https
echo "y" | ufw enable

# Setup MariaDB
mysql -u root <<EOF
CREATE DATABASE radius;
GRANT ALL PRIVILEGES ON radius.* TO 'radius'@'localhost' IDENTIFIED BY '$DBPASS';
FLUSH PRIVILEGES;
EOF

# Import radius schema
mysql -u root radius < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql

# Aktifkan SQL di FreeRADIUS
ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/

# Edit SQL config
sed -i "s|login = \"radius\"|login = \"radius\"|g" /etc/freeradius/3.0/mods-enabled/sql
sed -i "s|password = \"radpass\"|password = \"$DBPASS\"|g" /etc/freeradius/3.0/mods-enabled/sql

# Restart FreeRADIUS
systemctl restart freeradius
systemctl enable freeradius

# Install DaloRADIUS
cd /var/www/
git clone https://github.com/lirantal/daloradius.git
cd daloradius
cp library/daloradius.conf.php.sample library/daloradius.conf.php
sed -i "s|\$configValues\['CONFIG_DB_PASS'\] = ''|\$configValues['CONFIG_DB_PASS'] = '$DBPASS'|g" library/daloradius.conf.php

# Set permission
chown -R www-data:www-data /var/www/daloradius

# Nginx config
cat >/etc/nginx/sites-available/mikradius.conf <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/daloradius;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
EOF

ln -s /etc/nginx/sites-available/mikradius.conf /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

systemctl restart nginx

# HTTPS Certbot
certbot --nginx -d $DOMAIN --email $EMAIL --agree-tos --redirect

echo "=========================================="
echo "  Instalasi MikRadius Selesai!"
echo "=========================================="
echo "Login DaloRADIUS: https://$DOMAIN"
echo "User: administrator"
echo "Pass: radius"

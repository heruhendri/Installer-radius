#!/bin/bash
clear
echo "=============================================="
echo "       AUTO INSTALL RADIUS (NGINX + SSL)      "
echo " FreeRADIUS + MariaDB + daloRADIUS + HTTPS    "
echo "=============================================="

# ===============================================
# 1. INPUT DOMAIN
# ===============================================
read -p "Masukkan domain untuk panel (contoh: radius.domain.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo "Domain tidak boleh kosong!"
    exit 1
fi

# ===============================================
# 2. UPDATE SYSTEM
# ===============================================
echo "[1] Update system..."
apt update -y && apt upgrade -y

# ===============================================
# 3. INSTALL DEPENDENCIES
# ===============================================
echo "[2] Install packages..."
apt install -y freeradius freeradius-mysql freeradius-utils \
               mariadb-server nginx php-fpm php-mysql php-gd php-curl \
               php-xml php-zip php-mbstring php-cli git unzip certbot python3-certbot-nginx

systemctl enable mariadb
systemctl start mariadb

# ===============================================
# 4. DATABASE CONFIG
# ===============================================
echo "[3] Setup database radius..."

DB_NAME="radius"
DB_USER="radius"
DB_PASS="radius123"

mysql -e "CREATE DATABASE $DB_NAME;"
mysql -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "FLUSH PRIVILEGES;"

mysql $DB_NAME < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql

# ===============================================
# 5. ENABLE SQL MODULE
# ===============================================
echo "[4] Konfigurasi SQL FreeRADIUS..."

ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql 2>/dev/null

sed -i 's/dialect = "sqlite"/dialect = "mysql"/' /etc/freeradius/3.0/mods-available/sql
sed -i "s/radpass/$DB_PASS/" /etc/freeradius/3.0/mods-available/sql

sed -i 's/-sql/sql/' /etc/freeradius/3.0/sites-enabled/default
sed -i 's/-sql/sql/' /etc/freeradius/3.0/sites-enabled/inner-tunnel

# ===============================================
# 6. INSTALL DALORADIUS
# ===============================================
echo "[5] Installing daloRADIUS..."

mkdir -p /var/www
cd /var/www
git clone https://github.com/lirantal/daloradius.git dalo

cd dalo
cp -R contrib/* .
mysql $DB_NAME < daloradius.sql

cp library/daloradius.conf.php.sample library/daloradius.conf.php

sed -i "s/'DALORADIUS_DB_USER'.*/'DALORADIUS_DB_USER'] = '$DB_USER';/" library/daloradius.conf.php
sed -i "s/'DALORADIUS_DB_PASS'.*/'DALORADIUS_DB_PASS'] = '$DB_PASS';/" library/daloradius.conf.php
sed -i "s/'DALORADIUS_DB_NAME'.*/'DALORADIUS_DB_NAME'] = '$DB_NAME';/" library/daloradius.conf.php

chown -R www-data:www-data /var/www/dalo

# ===============================================
# 7. NGINX CONFIG (HTTP)
# ===============================================
echo "[6] Configure NGINX..."

cat > /etc/nginx/sites-available/radius <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/dalo;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
EOF

ln -s /etc/nginx/sites-available/radius /etc/nginx/sites-enabled/radius 2>/dev/null
rm -f /etc/nginx/sites-enabled/default

systemctl restart nginx

# ===============================================
# 8. INSTALL SSL LET'S ENCRYPT
# ===============================================
echo "[7] Install SSL..."

certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

# ===============================================
# 9. FIREWALL
# ===============================================
echo "[8] Buka port firewall..."
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 1812/udp
ufw allow 1813/udp

# ===============================================
# 10. RESTART SERVICES
# ===============================================
systemctl restart freeradius
systemctl enable freeradius

echo "=============================================="
echo "           INSTALL COMPLETE (HTTPS)"
echo "=============================================="
echo "Panel URL: https://$DOMAIN/"
echo "Login daloRADIUS:"
echo "User: administrator"
echo "Pass: radius"
echo "=============================================="

# Installer MikRadius – NATVPS
Auto Installer FreeRADIUS + DaloRADIUS + MariaDB + HTTPS (Certbot)  
Mendukung Multi Domain, Multi Radius, dan Firewall Security.

## ✨ Fitur
- Install FreeRADIUS 3 + Modul MySQL
- Install MariaDB & otomatis import schema
- Install DaloRADIUS + auto konfigurasi database
- Support HTTPS (Let’s Encrypt / Certbot)
- Support Multi Radius (beberapa instance radius dalam 1 VPS)
- Support Multi Domain untuk panel DaloRADIUS
- Hardening Firewall (UFW)
- Auto detect OS (Ubuntu 20/22/24)
- Fully NATVPS Compatible

---

## 🚀 Cara Install
Copy-paste command ini di VPS:

```bash
bash <(curl -s https://raw.githubusercontent.com/USER/REPO/main/install-mikradius.sh)
````



## 📌 Default Login DaloRADIUS

* URL: `https://domainkamu.com/daloradius`
* Username: `administrator`
* Password: `radius`

---

## 📡 Direktori Penting

* **FreeRADIUS config:** `/etc/freeradius/3.0/`
* **DaloRADIUS:** `/var/www/html/daloradius/`
* **Database:** `radius`

---

## 🔐 Fitur Keamanan

Installer menyediakan:

* Firewall otomatis (UFW)
* Block semua port kecuali: `22, 80, 443, 1812, 1813`
* Auto restart & auto enable service

---

## 🛠 Perintah Berguna

Cek status FreeRADIUS:

```bash
systemctl status freeradius
```

Tes autentikasi user:

```bash
radtest admin 1234 localhost 0 testing123
```

Restart FreeRADIUS:

```bash
systemctl restart freeradius
```

---

## 👨‍💻 Kontributor

* **Hendri** — NATVPS Indonesia
* ChatGPT Assistant

---

## 📜 License

MIT License.

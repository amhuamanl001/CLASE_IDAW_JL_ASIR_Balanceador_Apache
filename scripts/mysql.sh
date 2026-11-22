#!/bin/bash

# Detener el script si ocurre un error
set -eu

# Evitar preguntas durante la instalación
export DEBIAN_FRONTEND=noninteractive

# Actualizar repositorios
apt-get update

# Instalar herramientas necesarias
apt-get install -y wget ca-certificates gnupg openssl nftables

# Añadir el repositorio oficial de MySQL

wget -q https://dev.mysql.com/get/mysql-apt-config_0.8.40-1_all.deb -O /tmp/mysql-apt-config.deb

echo "mysql-apt-config mysql-apt-config/select-server select mysql-8.4-lts" | debconf-set-selections

dpkg -i /tmp/mysql-apt-config.deb

# Actualizar repositorios e instalar MySQL
apt-get update
apt-get install -y mysql-server

# Activar MySQL
systemctl enable --now mysql

# Configurar MySQL para escuchar en la red interna
printf '[mysqld]\nbind-address = 192.168.58.20\nskip-name-resolve\n' > /etc/mysql/mysql.conf.d/99-lamp.cnf

# Reiniciar MySQL para aplicar el cambio
systemctl restart mysql

# Crear una carpeta para guardar la contraseña de la aplicación
umask 077
mkdir -p /vagrant/.secretos

# Generar una contraseña si todavía no existe
if [ ! -s /vagrant/.secretos/mysql_password ]; then
    openssl rand -hex 16 > /vagrant/.secretos/mysql_password
fi

# Leer la contraseña guardada
CLAVE=$(tr -d '\r\n' < /vagrant/.secretos/mysql_password)

# Creo la base de datos y doy acceso a cada servidor web por su IP privada.
mysql -e 'CREATE DATABASE IF NOT EXISTS lamp_db CHARACTER SET utf8mb4;'

for ip in 192.168.58.11 192.168.58.12; do
    mysql <<SQL
CREATE USER IF NOT EXISTS 'lamp_app'@'$ip' IDENTIFIED BY '$CLAVE';
ALTER USER 'lamp_app'@'$ip' IDENTIFIED BY '$CLAVE';
GRANT SELECT, INSERT, UPDATE, DELETE ON lamp_db.* TO 'lamp_app'@'$ip';
SQL
done

# Importar la tabla del archivo original si todavía no existe
if ! mysql -Nse "SHOW TABLES FROM lamp_db LIKE 'users';" | grep -q '^users$'; then
    mysql lamp_db < /vagrant/recursos/db/database.sql
fi

# Mostrar las tablas creadas
mysql -e "SHOW TABLES FROM lamp_db;"
#!/bin/bash

# Detener el script si ocurre un error
set -eu

# Evitar preguntas durante la instalación
export DEBIAN_FRONTEND=noninteractive

# Actualizar los repositorios
apt-get update

# Instalar Apache, PHP y la extensión de MySQL
apt-get install -y apache2 php libapache2-mod-php php-mysql nftables

# Comprobar que MySQL ha generado la contraseña
if [ ! -s /vagrant/.secretos/mysql_password ]; then
    echo "Primero debes aprovisionar el servidor MySQL."
    exit 1
fi

# Leer la contraseña de la aplicación
CLAVE=$(tr -d '\r\n' < /vagrant/.secretos/mysql_password)

# Copiar los archivos PHP y HTML
cp -a /vagrant/recursos/src/. /var/www/html/

# Configurar la conexión con MySQL
sed -i \
    -e "s/'localhost'/'192.168.58.20'/" \
    -e "s/'database_name_here'/'lamp_db'/" \
    -e "s/'username_here'/'lamp_app'/" \
    -e "s/'password_here'/'$CLAVE'/" \
    /var/www/html/config.php

# Quitar la página de ejemplo de Apache
rm -f /var/www/html/index.html

# Proteger el archivo con los datos de conexión
chown root:www-data /var/www/html/config.php
chmod 640 /var/www/html/config.php

# Identifico el servidor que atendió la petición para comprobar el reparto.
a2enmod headers
printf 'Header always set X-Servidor "%s"\n' "$1" > /etc/apache2/conf-available/backend.conf
a2enconf backend
apache2ctl configtest

# Iniciar Apache y activar su arranque automático
systemctl enable --now apache2
systemctl restart apache2
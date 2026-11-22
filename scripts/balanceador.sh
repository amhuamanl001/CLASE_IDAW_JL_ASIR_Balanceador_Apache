#!/bin/bash
set -eu

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y apache2 certbot python3-certbot-apache nftables

# Configuro los dos servidores a los que Apache puede enviar peticiones.
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests

cat > /etc/apache2/sites-available/balanceador.conf <<APACHE
<VirtualHost *:80>
    ServerName $1
    ProxyRequests Off

    <Proxy "balancer://aplicacion">
        BalancerMember "http://192.168.57.11"
        BalancerMember "http://192.168.57.12"
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPass "/" "balancer://aplicacion/"
    ProxyPassReverse "/" "balancer://aplicacion/"
</VirtualHost>
APACHE

a2ensite balanceador.conf
a2dissite 000-default.conf
apache2ctl configtest
systemctl enable --now apache2
systemctl reload apache2

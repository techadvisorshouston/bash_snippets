#!/bin/bash

################################################################
# VARIABLES
################################################################
APACHE_LOG_DIR=/var/log/apache2/
UBUNTU_VERSION=$(cat /etc/issue)
PASS=$(perl -e 'print crypt($ARGV[0], "password")' $USER_PW)

################################################################
# USER DEFINED VARIABLES - SET THESE BEFORE RUNNING SCRIPT
################################################################
# APACHE
DOMAIN_NAME= # example.com
ADMIN_EMAIL= # admin@example.com
WEB_ROOT_DIR= # /var/www/html/example
VHOST_IP=* # Only change if your server has multiple ip addresses and you will be running multiple vhosts
SSL= # Setup a SSL Certificate for your vhost? Enter Y or N here

# PHP
PHP_VER= # Enter the php version you wish to install. (8.0,7.4,7.3) Note that phpmyadmin does not work with version 8.0 yet 

# SSH
PASS_AUTH= # Enable or Disable password authentication for SSH Server. Enter Y or N.
ROOT_LOGIN= # Allow Root login via SSH. Enter Y or N
NEW_USER= # Enter a username that will be used for the newly created sudo user
USER_PW= # Sudo user password

# MYSQL-SERVER
MYSQL_ROOT_PW= # Root Password for mysql
MYSQL_USER= # New Mysql User
MYSQL_USER_PW= # New Mysql Use Password

# Install PHPMYADMIN
PHPMYADMIN_INSTALL= # Enter Y or N
################################################################
# FUNCTIONS
################################################################
CHECK_ROOT()
{
    if [[ $EUID != 0 ]]; then
        echo "Script must be ran with root privileges!"
        sleep 2
        exit 1
    fi
}
RUN_SSL()
{
    # Secure Domain with Let's Encrypt
echo "Installing Certbot.."
apt install certbot -y &>/dev/null


# Generate Diffie Hellman
echo "Generating Diffie Helman.."
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 &>/dev/null

mkdir -p /var/lib/letsencrypt/.well-known
chgrp www-data /var/lib/letsencrypt
chmod g+s /var/lib/letsencrypt

# Create Letsencrypt.conf
cat << _EOF_ > /etc/apache2/conf-available/letsencrypt.conf
Alias /.well-known/acme-challenge/ "/var/lib/letsencrypt/.well-known/acme-challenge/"
<Directory "/var/lib/letsencrypt/">
    AllowOverride None
    Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
    Require method GET POST OPTIONS
</Directory>
_EOF_

# Create SSL-Params.conf
cat << _EOF_ > /etc/apache2/conf-available/ssl-params.conf
SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder     off
SSLSessionTickets       off

SSLUseStapling On
SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"

Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set X-Frame-Options SAMEORIGIN
Header always set X-Content-Type-Options nosniff

SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"
_EOF_

# Enable Apache Modules
echo "Enabling Apache Modules.."
a2enmod ssl headers http2 &>/dev/null

# Enable newly created configurations
echo "Enabling Apache Configurations.."
a2enconf letsencrypt ssl-params &>/dev/null

# Reload Apache
echo "Reloading Apache.."
systemctl reload apache2 &>/dev/null

# Create SSL Cert
echo "Creating SSL Cert.."
certbot certonly --agree-tos --email $ADMIN_EMAIL --webroot -w /var/lib/letsencrypt/ -d $DOMAIN_NAME -d www.$DOMAIN_NAME &>/dev/null

# Add Redirect to https in Vhost
sed -i "9i Redirect permanent / https://$DOMAIN_NAME/" /etc/apache2/sites-available/$DOMAIN_NAME.conf

# Generate SSL Vhost
cat <<_EOF_>> /etc/apache2/sites-available/$DOMAIN_NAME.conf
<VirtualHost $VHOST_IP:443>
  ServerName $DOMAIN_NAME
  ServerAlias www.$DOMAIN_NAME

  Protocols h2 http/1.1

  <If "%{HTTP_HOST} == 'www.$DOMAIN_NAME'">
    Redirect permanent / https://$DOMAIN_NAME/
  </If>

  DocumentRoot $WEB_ROOT_DIR
  ErrorLog ${APACHE_LOG_DIR}/$DOMAIN_NAME-error.log
  CustomLog ${APACHE_LOG_DIR}/$DOMAIN_NAME-access.log combined

  SSLEngine On
  SSLCertificateFile /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem

</VirtualHost>
_EOF_

# Reload Apache
echo "Reloading Apache.."
systemctl reload apache2 &>/dev/null
}
USER_ADD()
{
    egrep "^$NEW_USER" /etc/passwd >/dev/null
        if [[ $? -eq 0 ]]; then
            echo "$NEW_USER already exists!"
            exit 1
        else
    useradd -m -p "$PASS" "$NEW_USER"
        [ $? == 0 ] && echo "$NEW_USER added successfully!" || echo "Failed to add $NEW_USER.."
    fi
    usermod -aG sudo $NEW_USER
}
################################################################
# SCRIPT
################################################################

CHECK_ROOT

# Update the system
echo "Updating the system.."
apt update &>/dev/null

# Add New User
USER_ADD

# Make a copy of SSHD_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Check for Generated Keypair
if [[ ! -f /root/.ssh/id_rsa ]]; then
    echo "No keypair was detected for SSH. Do you want to generate a new keypair to use for Passwordless Authentication via SSH?"
    read answer
    case $answer in
        Y|y|yes|Yes)
            echo "Generating new keypair at /root/.ssh/id_rsa. BE SURE TO COPY TO LOCAL SYSTEM IF YOU DISABLED PASSWORD AUTHENTICATION!"
            ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1
            ;;
        N|n|no|No)
            ;;
            *)
                echo "$answer was not a valid choice. Exiting now.."
                sleep 3
                exit 1
                ;;
    esac
fi

# Disable PW Auth via SSH
if [[ $PASS_AUTH = N ]]; then
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
fi

# Install apache
echo "Installing apache2.."
apt install apache2 apache2-utils -y &>/dev/null

# Enable and start
echo "Enabling and starting apache2.."
systemctl enable apache2 &>/dev/null && systemctl start apache2 &>/dev/null

# Create Servername.conf
echo "Creating servername.conf.."
echo "ServerName localhost">>/etc/apache2/conf-available/servername.conf &>/dev/null
a2enconf servername.conf &>/dev/null

# Create Web Root Directory, Fix permissions and ownership
echo "Creating Web Root Directory and fixing ownership.."
mkdir $WEB_ROOT_DIR 
chown www-data:www-data $WEB_ROOT_DIR -R

# Create Virtual Host File and Disable default Vhost
echo "Generating VirtualHost file for $DOMAIN_NAME.."
cat <<_EOF_>> /etc/apache2/sites-available/$DOMAIN_NAME.conf
<VirtualHost $VHOST_IP:80>
    ServerName $DOMAIN_NAME
    ServerAlias www.$DOMAIN_NAME

    DocumentRoot $WEB_ROOT_DIR

    ErrorLog ${APACHE_LOG_DIR}${DOMAIN}-error.log
    CustomLog ${APACHE_LOG_DIR}${DOMAIN}-access.log combined
</VirtualHost>
_EOF_

echo "Enabling $DOMAIN_NAME.."
a2ensite $DOMAIN_NAME.conf &>/dev/null
echo "Disabling default virtual host.."
a2dissite 000-default.conf &>/dev/null

# Reload Apache
echo "Reloading apache.."
systemctl reload apache2 &>/dev/null

# Add Env Var to Apache
echo "export DOMAIN_NAME=$DOMAIN_NAME">>/etc/apache2/apache2.conf
echo "export DOMAIN_NAME=$DOMAIN_NAME">>/root/.bashrc

# Disable Indexing
echo "Disabling Indexing of Web Root Directory.."
sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf

# Install PHP
echo "Installing PHP.."
add-apt-repository ppa:ondrej/php -y &>/dev/null && apt update &>/dev/null

echo "Installing PHP modules.."
apt install php$PHP_VER php$PHP_VER-fpm php$PHP_VER-mysql php$PHP_VER-cli -y &>/dev/null

# Disable php7.4 and enable php-fpm
echo "Enabling PHP-FPM.."
a2dismod php$PHP_VER &>/dev/null
a2enconf proxy_fcgi setenvif &>/dev/null
a2enconf php$PHP_VER-fpm &>/dev/null

# Start and enable php-fpm
systemctl enable php$PHP_VER-fpm &>/dev/null && systemctl start php$PHP_VER-fpm &>/dev/null

# Reload Apache
echo "Reloading apache.."
systemctl reload apache2 &>/dev/null

if [[ $SSL == Y ]]; then
    RUN_SSL
fi

# Install Mysql Server
echo "Installing MYSQL Server.."
apt install mysql-server -y &>/dev/null

# Start and Enable Mysql-server
systemctl enable mysql-server &>/dev/null && systemctl start mysql-server &>/dev/null

# Automatically Run Mysql_secure_installation
mysql <<BASH_QUERY
SET PASSWORD FOR root@localhost = PASSWORD('$MYSQL_ROOT_PW');FLUSH PRIVILEGES;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE test;DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_USER_PW';GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost';FLUSH PRIVILEGES;
BASH_QUERY

if [[ $PHPMYADMIN_INSTALL == Y ]]; then
    echo "Installing phpmyadmin.."
    apt install phpmyadmin -y
fi

echo "Script Complete.."
sleep 3
echo ""
echo "*****     https://github.com/ryanc410     *****"
sleep 5

#!/usr/bin/env bash

HASH=`curl -sS https://composer.github.io/installer.sig`

verify() {
    php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('/tmp/composer-setup.php'); } echo PHP_EOL;"
}

sudo apt update
sudo apt install php-cli unzip -y

which curl &>/dev/null
if [[ $? - == 1]]; then
    sudo apt install curl -y
fi
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
verify
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -rf /tmp/composer-setup.php
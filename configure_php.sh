#!/bin/bash

sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/fpm/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/cli/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/apache2/php.ini

sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/g' /etc/php/7.4/fpm/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/g' /etc/php/7.4/cli/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/g' /etc/php/7.4/apache2/php.ini

sed -i 's|;date.timezone =|date.timezone = America/Chicago|g' /etc/php/7.4/fpm/php.ini
sed -i 's|;date.timezone =|date.timezone = America/Chicago|g' /etc/php/7.4/cli/php.ini
sed -i 's|;date.timezone =|date.timezone = America/Chicago|g' /etc/php/7.4/apache2/php.ini

sed -i 's|;sendmail_path =|sendmail_path = /usr/sbin/sendmail|g' /etc/php/7.4/fpm/php.ini
sed -i 's|;sendmail_path =|sendmail_path = /usr/sbin/sendmail|g' /etc/php/7.4/cli/php.ini
sed -i 's|;sendmail_path =|sendmail_path = /usr/sbin/sendmail|g' /etc/php/7.4/apache2/php.ini

sed -i 's|mysqli.default_socket =|mysqli.default_socket = /var/run/mysqld/mysqld.sock|g' /etc/php/7.4/fpm/php.ini
sed -i 's|mysqli.default_socket =|mysqli.default_socket = /var/run/mysqld/mysqld.sock|g' /etc/php/7.4/cli/php.ini
sed -i 's|mysqli.default_socket =|mysqli.default_socket = /var/run/mysqld/mysqld.sock|g' /etc/php/7.4/apache2/php.ini

sed -i 's/mysqli.default_host =/mysqli.default_host = localhost/g' /etc/php/7.4/fpm/php.ini
sed -i 's/mysqli.default_host =/mysqli.default_host = localhost/g' /etc/php/7.4/cli/php.ini
sed -i 's/mysqli.default_host =/mysqli.default_host = localhost/g' /etc/php/7.4/apache2/php.ini

sed -i 's/mysqli.default_user =/mysqli.default_user = root/g' /etc/php/7.4/fpm/php.ini
sed -i 's/mysqli.default_user =/mysqli.default_user = root/g' /etc/php/7.4/cli/php.ini
sed -i 's/mysqli.default_user =/mysqli.default_user = root/g' /etc/php/7.4/apache2/php.ini

sed -i 's/mysqli.default_pw =/mysqli.default_pw = /g' /etc/php/7.4/fpm/php.ini
sed -i 's/mysqli.default_pw =/mysqli.default_pw = /g' /etc/php/7.4/cli/php.ini
sed -i 's/mysqli.default_pw =/mysqli.default_pw = /g' /etc/php/7.4/apache2/php.ini

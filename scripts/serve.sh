#!/usr/bin/env bash

if [ -z "$3" ]; then
    phperr=$(php -r "echo $3;")
    php_options="php_value error_reporting $phperr"
fi

block="<VirtualHost *:80>
    ServerName $1
    DocumentRoot $2

    # PHP options if any ...
    $php_options

    <Directory $2>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        Allow from all

        # for compatibility with Apache 2.4
        Require all granted
    </Directory>
</VirtualHost>
"

echo "$block" > "/etc/httpd/conf.d/50-$1.conf"
service httpd restart

#!/usr/bin/env bash
echo "Args: 1[$1] 2[$2] 3[$3] 4[$4] 5[$5]"
vhost_conf="/etc/httpd/vhosts.d/$1.conf"
if [ -e $vhost_conf ]; then
  echo "vhost Config File for $1 exists - abort"
  exit
fi

if [ ! -z "$3" ]; then
    alias_name=$(php -r "echo \"$3\";")
    alias_path=$(php -r "echo \"$4\";")
    alias_option="Alias $alias_name  $alias_path"
    alias_dir="<Directory $alias_path>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        Allow from all
    </Directory>"
fi

if [ ! -z "$5" ]; then
    phperr=$(php -r "echo $5;")
    php_options="php_value error_reporting $phperr"
fi

block="<VirtualHost *:80>
    ServerName $1
    DocumentRoot $2

    # Alias, if any
    $alias_option

    # PHP options if any ...
    $php_options

    <Directory $2>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        Allow from all
    </Directory>

    $alias_dir
</VirtualHost>
"

echo "$block" > "$vhost_conf"

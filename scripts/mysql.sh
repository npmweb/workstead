#!/usr/bin/env bash

DBNAME=$1
DBEXISTS=$(mysql --batch --skip-column-names -e "SHOW DATABASES LIKE '"$DBNAME"';" | grep "$DBNAME" > /dev/null; echo "$?")
if [ $DBEXISTS -eq 0 ];then
    echo "A database with the name $DBNAME already exists."
else
    echo " database $DBNAME does not exist."
    mysqladmin create $1;
    mysql -u root -Bse "CREATE USER '$2'@'localhost' IDENTIFIED BY '$3'; GRANT ALL ON $DBNAME.* to '$2'@'localhost';"
    mysql -u root -Bse "CREATE USER '$2'@'%' IDENTIFIED BY '$3'; GRANT ALL ON $DBNAME.* to '$2'@'%';"
fi

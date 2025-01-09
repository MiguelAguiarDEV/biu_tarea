#!/bin/bash

#Leemos el archivo de tablas para poderle aplicar el  import
for table in $(cat tablas.txt); do
  echo "Importando tabla: $table"
  sqoop import \
    --connect jdbc:mariadb://192.168.1.58:3307/moviebind \
    --username root \
    --password 'root' \
    --table $table \
    --target-dir /user/hadoop/texto_datos/$table \
    --as-textfile \
    --driver org.mariadb.jdbc.Driver
done

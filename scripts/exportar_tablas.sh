for table in $(cat tablas.txt); do
  echo "Exportando tabla: $table"
  sqoop export \
    --connect jdbc:mariadb://192.168.1.58:3307/moviebind \
    --username root \
    --password 'root' \
    --table $table \
    --export-dir /user/hadoop/texto_datos/$table \
    --input-fields-terminated-by ',' \
    --input-lines-terminated-by '\n' \
    --driver org.mariadb.jdbc.Driver
done

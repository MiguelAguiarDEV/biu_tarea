#!/bin/bash

# Definir variables
DB_USER="root"
DB_PASS="root"
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="MovieBind"
VENV_DIR=".venv"

# Exportar las variables como entorno para el script Python
export DB_USER
export DB_PASS
export DB_HOST
export DB_PORT
export DB_NAME


# Funciones para cada operación
setupEnv() {
    echo "Configurando el entorno virtual..."

    # Crear el entorno virtual si no existe
    if [ ! -d "$VENV_DIR" ]; then
        echo "Creando el entorno virtual..."
        python3 -m venv $VENV_DIR
    else
        echo "El entorno virtual ya existe."
    fi

    # Activar el entorno virtual
    source $VENV_DIR/bin/activate

    # Instalar las dependencias
    if [ -f "requirements.txt" ]; then
        echo "Instalando dependencias desde requirements.txt..."
        pip install -r requirements.txt
    else
        echo "Archivo requirements.txt no encontrado. No se instalaron dependencias."
    fi

    echo "Entorno virtual configurado."
}

# Done
createDB() {
    echo "Creando la base de datos..."
    mysql -u $DB_USER -p$DB_PASS < scripts/moviebind.sql
    echo "Base de datos creada."
}

# Done
loadData() {
    echo "Cargando datos iniciales en la base de datos..."
    python3 scripts/inserciones.py
    echo "Datos cargados en la base de datos."
}

deleteDB() {
    echo "Borrando todas las tablas de la base de datos..."
    mysql -u $DB_USER -p$DB_PASS -e "DROP DATABASE $DB_NAME;"
    echo "Base de datos borrada."
}


importData() {
    read -p "Introduce el nombre de la tabla que deseas importar: " table
    echo "Importando datos de la tabla '$table' a HDFS..."
    sqoop import --connect jdbc:mariadb://$DB_HOST:$DB_PORT/$DB_NAME --username $DB_USER --password $DB_PASS --table $table --target-dir $HDFS_PATH/$table
    echo "Datos importados a HDFS desde la tabla '$table'."
}

importFilters() {
    read -p "Introduce el nombre de la tabla que deseas importar: " table
    read -p "Introduce la condición para filtrar los datos (por ejemplo, 'id > 10'): " condition
    echo "Importando datos de la tabla '$table' a HDFS con la condición '$condition'..."
    sqoop import sqoop import --connect jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME --username $DB_USER --password $DB_PASS --table $table --where "$condition" --target-dir $HDFS_PATH/$table
    echo "Datos importados con filtros de la tabla '$table'."
}

importAvro() {
    read -p "Introduce el nombre de la tabla que deseas importar en formato Avro: " table
    echo "Importando datos de la tabla '$table' a HDFS en formato Avro..."
    sqoop import sqoop import --connect jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME --username $DB_USER --password $DB_PASS --table $table --as-avrodatafile --target-dir $HDFS_PATH/$table
    echo "Datos de la tabla '$table' importados en formato Avro."
    echo "Leyendo datos en formato Avro en Hadoop..."
    hadoop jar /path/to/avro-tools.jar tojson $HDFS_PATH/$table
}

importParquet() {
    read -p "Introduce el nombre de la tabla que deseas importar en formato Parquet: " table
    echo "Importando datos de la tabla '$table' a HDFS en formato Parquet..."
    sqoop import sqoop import --connect jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME --username $DB_USER --password $DB_PASS --table $table --as-parquetfile --target-dir $HDFS_PATH/$table
    echo "Datos de la tabla '$table' importados en formato Parquet."
    echo "Leyendo datos en formato Parquet en Hadoop..."
    hadoop fs -cat $HDFS_PATH/$table
}

importSnappy() {
    read -p "Introduce el nombre de la tabla que deseas importar en formato comprimido con Snappy: " table
    echo "Importando datos de la tabla '$table' a HDFS en formato comprimido con Snappy..."
    sqoop import sqoop import --connect jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME --username $DB_USER --password $DB_PASS --table $table --as-parquetfile --compression-codec snappy --target-dir $HDFS_PATH/$table
    echo "Datos comprimidos con Snappy de la tabla '$table' importados."
}

importHive() {
    read -p "Introduce el nombre de la tabla que deseas importar en Hive: " table
    echo "Importando datos de la tabla '$table' a HDFS para Apache Hive..."
    sqoop import sqoop import --connect jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME --username $DB_USER --password $DB_PASS --table $table --hive-import --create-hive-table --hive-table $table
    echo "Datos importados a Hive desde la tabla '$table'."
}

exportData() {
    read -p "Introduce el nombre de la tabla que deseas exportar desde HDFS a MariaDB: " table
    echo "Exportando datos desde HDFS a la tabla '$table' en MariaDB..."
    sqoop export sqoop import --connect jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME --username $DB_USER --password $DB_PASS --table $table --export-dir $HDFS_PATH/$table
    echo "Datos exportados a la tabla '$table' en MariaDB."
}

exportTables() {
    for table in $(cat tablas.txt); do
        echo "Exportando tabla: $table"
        sqoop export \
            sqoop import --connect jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME --username $DB_USER --password $DB_PASS
            --username root \
            --password 'root' \
            --table $table \
            --export-dir /user/hadoop/text_data/$table \
            --input-fields-terminated-by ',' \
            --input-lines-terminated-by '\n' \
            --driver org.mariadb.jdbc.Driver
    done
}

importTables() {
    for table in $(cat tablas.txt); do
        echo "Importando tabla: $table"
        sqoop import \
            sqoop import --connect jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME --username $DB_USER --password $DB_PASS
            --username root \
            --password 'root' \
            --table $table \
            --target-dir /user/hadoop/text_data/$table \
            --as-textfile \
            --driver org.mariadb.jdbc.Driver
    done
}

# Parsear el flag proporcionado
case $1 in
    -setupEnv)
        setupEnv
        ;;
    -createDB)
        createDB
        ;;
    -loadData)
        loadData
        ;;
    -deleteDB)
        deleteDB
        ;;
    -import)
        importData
        ;;
    -importFilters)
        importFilters
        ;;
    -importAvro)
        importAvro
        ;;
    -importParquet)
        importParquet
        ;;
    -importSnappy)
        importSnappy
        ;;
    -importHive)
        importHive
        ;;
    -export)
        exportData
        ;;
    *)
        echo "Uso: $0 {-setupEnv|-createDB|-loadData|-deleteDB|-import|-importFilters|-importAvro|-importParquet|-importSnappy|-importHive|-export}"
        exit 1
        ;;
esac


#!/bin/bash

# Definir variables
DB_USER="root"
DB_PASS="root"
DB_HOST="192.168.216.120"
DB_PORT="3307"
DB_NAME="moviebind"
VENV_DIR=".venv"
HDFS_PATH="/user/hadoop/text_data"
TABLES_LIST="Usuarios Contratos PalabrasClave Pelicula_PalabrasClave Perfiles Visualizaciones Generos Pelicula_Generos Peliculas"

# Exportar las variables como entorno para el script Python
export DB_USER
export DB_PASS
export DB_HOST
export DB_PORT
export DB_NAME

# Funciones para cada operación
init() {
    # Comprueba e instala Python3, pip y venv si es necesario

    # Comprueba si apt-get está disponible
    echo "Comprobando si apt-get está disponible..."
    if ! command -v apt-get &> /dev/null; then
        echo "Este script requiere apt-get para instalar paquetes. Por favor, usa una distribución basada en Debian."
        exit 1
    else
        echo "apt-get está disponible."
    fi

    # Comprueba e instala Python3
    echo "Comprobando si Python3 está instalado..."
    if ! command -v python3 &> /dev/null; then
        echo "Python3 no está instalado. Instalando Python3..."
        sudo apt-get update
        sudo apt-get install -y python3
    else
        echo "Python3 ya está instalado."
    fi

    # Comprueba e instala pip
    echo "Comprobando si pip está instalado..."
    if ! command -v pip &> /dev/null; then
        echo "pip no está instalado. Instalando pip..."
        sudo apt-get update
        sudo apt-get install -y python3-pip
    else
        echo "pip ya está instalado."
    fi

    # Comprueba e instala venv
    echo "Comprobando si venv está instalado..."
    if ! python3 -m venv --help &> /dev/null; then
        echo "venv no está instalado. Instalando venv..."
        sudo apt-get update
        sudo apt-get install -y python3-venv
    else
        echo "venv ya está instalado."
    fi

    # Crea y configura el entorno virtual

    echo "Configurando el entorno virtual..."
    # Crear el entorno virtual si no existe
    if [ ! -d "$VENV_DIR" ]; then
        echo "Creando el entorno virtual..."
        python3 -m venv $VENV_DIR
    else
        echo "El entorno virtual ya existe."
    fi

    # Activar el entorno virtual
    echo "Activando el entorno virtual..."
    source $VENV_DIR/bin/activate
    if [ $? -eq 0 ]; then
        echo "Entorno virtual activado."
    else
        echo "Hubo un error al activar el entorno virtual."
        exit 1
    fi
    
    # Instalar las dependencias
    if [ -f "requirements.txt" ]; then
        echo "Instalando dependencias desde requirements.txt..."
        pip install -r requirements.txt
    else
        echo "Archivo requirements.txt no encontrado. No se instalaron dependencias."
    fi

    echo "Entorno virtual configurado."

    echo "Uso: $0 {-init|-createDB|-loadData|-deleteDB|-import|-importFilters|-importAvro|-importParquet|-importSnappy|-importHive|-export|-importTables}"
}

createDB() {
    echo "Creando la base de datos..."
    mariadb -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS < scripts/moviebind.sql
    echo "Base de datos creada."
}

loadData() {
    echo "Cargando datos iniciales en la base de datos..."
    python3 scripts/inserciones.py
    echo "Datos cargados en la base de datos."
}

deleteDB() {
    echo "Borrando todas las tablas de la base de datos..."
    mariadb -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS \
        -e "DROP DATABASE $DB_NAME;"
    echo "Base de datos borrada."
}

import() {
    read -p "Introduce el nombre de la tabla que deseas importar: " table
    echo "Importando datos de la tabla '$table' a HDFS..."
    sqoop import --connect jdbc:mariadb://$DB_HOST:$DB_PORT/$DB_NAME \
        --username $DB_USER \
        --password $DB_PASS \
        --table $table \
        --target-dir $HDFS_PATH/imported_data/$table \
        --as-textfile \
        --driver org.mariadb.jdbc.Driver
    echo "Datos importados a HDFS desde la tabla '$table' en $HDFS_PATH/imported_data/$table."
}

importFilters() {
    read -p "Introduce el nombre de la tabla que deseas importar: " table
    read -p "Introduce las columnas (por ejemplo: id_usuario,nickname): " columns
    read -p "Introduce la condición para filtrar los datos (por ejemplo, 'id_usuario > 5'): " condition
    if [[ -z "$condition" ]]; then
        echo "La condición de filtro no puede estar vacía. Inténtalo de nuevo."
        exit 1
    fi
    echo "Importando datos de la tabla '$table' a HDFS con la condición '$condition'..."
    sqoop import --connect jdbc:mariadb://$DB_HOST:$DB_PORT/$DB_NAME \
        --username $DB_USER \
        --password $DB_PASS \
        --table $table \
        --columns "$columns" \
        --where "$condition" \
        --target-dir $HDFS_PATH/filtered_data/$table \
        --as-textfile \
        --driver org.mariadb.jdbc.Driver
    echo "Datos importados con filtros de la tabla '$table' en $HDFS_PATH/filtered_data/$table."
}

importAvro() {
    read -p "Introduce el nombre de la tabla que deseas importar en formato Avro: " table
    echo "Importando datos de la tabla '$table' a HDFS en formato Avro..."
    sqoop import --connect jdbc:mariadb://$DB_HOST:$DB_PORT/$DB_NAME \
        --username $DB_USER \
        --password $DB_PASS \
        --table $table \
        --as-avrodatafile \
        --target-dir $HDFS_PATH/avro_data/$table \
        --driver org.mariadb.jdbc.Driver
    echo "Datos de la tabla '$table' importados en formato Avro en $HDFS_PATH/avro_data/$table."
}

importParquet() {
    read -p "Introduce el nombre de la tabla que deseas importar en formato Parquet: " table
    echo "Importando datos de la tabla '$table' a HDFS en formato Parquet..."
    sqoop import --connect jdbc:mariadb://$DB_HOST:$DB_PORT/$DB_NAME \
        --username $DB_USER \
        --password $DB_PASS \
        --table $table \
        --as-parquetfile \
        --target-dir $HDFS_PATH/parquet_data/$table \
        --driver org.mariadb.jdbc.Driver
    echo "Datos de la tabla '$table' importados en formato Parquet en $HDFS_PATH/parquet_data/$table."
}

importSnappy() {
    read -p "Introduce el nombre de la tabla que deseas importar en formato comprimido con Snappy: " table
    echo "Importando datos de la tabla '$table' a HDFS en formato comprimido con Snappy..."
    sqoop import --connect jdbc:mariadb://$DB_HOST:$DB_PORT/$DB_NAME \
        --username $DB_USER \
        --password $DB_PASS \
        --table $table \
        --as-textfile \
        --target-dir $HDFS_PATH/snapy_data/$table \
        --compression-codec org.apache.hadoop.io.compress.SnappyCodec \
        --driver org.mariadb.jdbc.Driver 
    echo "Datos comprimidos con Snappy de la tabla '$table' importados en $HDFS_PATH/snapy_data/$table."
}

importHive() {
    read -p "Introduce el nombre de la tabla que deseas importar en Hive: " table
    echo "Importando datos de la tabla '$table' a HDFS para Apache Hive..."
    sqoop import --connect jdbc:mariadb://$DB_HOST:$DB_PORT/$DB_NAME \
        --username $DB_USER \
        --password $DB_PASS \
        --table $table \
        --target-dir $HDFS_PATH/hive_data/$table \
        --as-avrodatafile \
        --compression-codec org.apache.hadoop.io.compress.SnappyCodec \
        --driver org.mariadb.jdbc.Driver 
    echo "Datos importados a Hive desde la tabla '$table' importados en $HDFS_PATH/hive_data/$table."
}

export() {
    # Comentar o descomentar dependiendo de lo que diga Tony
    #deleteData()

    for table in $TABLES_LIST; do
        mariadb -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS \
            -e "use $DB_NAME;truncate table $table;"
    done

    for table in $TABLES_LIST; do
        echo "Exportando tabla: $table"
        sqoop export \
            --connect jdbc:mariadb://$DB_HOST:$DB_PORT/$DB_NAME \
            --username $DB_USER \
            --password $DB_PASS \
            --table $table \
            --export-dir $HDFS_PATH/allTables/$table \
            --driver org.mariadb.jdbc.Driver
    done
}

importTables() {
    echo "Importando todas las tablas"
    
    for table in $TABLES_LIST; do
            sqoop import \
            --connect jdbc:mariadb://$DB_HOST:$DB_PORT/$DB_NAME \
            --username $DB_USER \
            --password $DB_PASS \
            --query "SELECT * FROM $table WHERE \$CONDITIONS" \
            --target-dir $HDFS_PATH/allTables/$table \
            --as-textfile \
            --num-mappers 1 \
            --driver org.mariadb.jdbc.Driver
    done

    echo "Tablas importadas en $HDFS_PATH/allTables/"
}

deleteData() {
    for table in $TABLES_LIST; do
        mariadb -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS \
            -e "use databse $DB_NAME;TRUNCATE TABLE $table;;"
    done
}


help(){
    echo "Script de Gestión de Base de Datos y HDFS con Sqoop"
    echo "Uso: $0 {opción}"
    echo "Opciones disponibles:"
    echo "  -help             Muestra este mensaje de ayuda."
    echo "  -init             Configura el entorno inicial para el script (si es necesario)."
    echo "  -createDB         Crea la base de datos utilizando el archivo SQL especificado."
    echo "  -loadData         Carga datos iniciales en la base de datos desde un script Python que genera datos aleatorios."
    echo "  -deleteDB         Borra la base de datos y todas sus tablas."
    echo "  -import           Importa datos desde una tabla específica de la base de datos a HDFS."
    echo "  -importFilters    Importa datos desde una tabla aplicando filtros definidos por el usuario."
    echo "  -importAvro       Importa datos desde una tabla en formato Avro hacia HDFS."
    echo "  -importParquet    Importa datos desde una tabla en formato Parquet hacia HDFS."
    echo "  -importSnappy     Importa datos comprimidos con Snappy desde una tabla hacia HDFS."
    echo "  -importHive       Importa datos desde una tabla para ser utilizados con Apache Hive."
    echo "  -export           Exporta datos desde HDFS hacia tablas de la base de datos."
    echo "  -importTables     Importa todas las tablas listadas en un archivo hacia HDFS."
    echo "  -deleteData       Borra todos los datos de las tablas listadas en un archivo."
    echo ""
}

# Parsear el flag proporcionado
case $1 in
    -init)
        init
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
        import
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
        export
        ;;
    -importTables)
        importTables
        ;;
    -deleteData)
        deleteData
        ;;
    -help)
        help
        ;;
    *)
        echo "Uso: $0 {-help|-init|-createDB|-loadData|-deleteDB|-import|-importFilters|-importAvro|-importParquet|-importSnappy|-importHive|-export|-importTables|-deleteData}"
        exit 1
        ;;
esac

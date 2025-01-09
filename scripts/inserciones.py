from faker import Faker
from sqlalchemy import create_engine, text, Column, Integer, String, Boolean, ForeignKey, Table, DateTime, Float, DECIMAL, Text, Date
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
import random, os

# Leer las variables de entorno
db_user = os.getenv('DB_USER', 'root')
db_pass = os.getenv('DB_PASS', '')
db_host = os.getenv('DB_HOST', 'localhost')
db_port = os.getenv('DB_PORT', '3306')
db_name = os.getenv('DB_NAME', 'MovieBind')

# Crear la cadena de conexión con las variables del entorno
connection_string = f"mariadb+pymysql://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}"

# Configurar Faker
fake = Faker()

# Configurar SQLAlchemy
Base = declarative_base()

# Tablas intermedias para relaciones muchos a muchos
pelicula_generos = Table(
    'pelicula_generos', Base.metadata,
    Column('id_pelicula', Integer, ForeignKey('peliculas.id_pelicula')),
    Column('id_genero', Integer, ForeignKey('generos.id_genero'))
)

pelicula_palabras_clave = Table(
    'pelicula_palabrasclave', Base.metadata,
    Column('id_pelicula', Integer, ForeignKey('peliculas.id_pelicula')),
    Column('id_palabra', Integer, ForeignKey('palabrasclave.id_palabra'))
)

# Definir Tablas
class Usuario(Base):
    __tablename__ = 'usuarios'
    id_usuario = Column(Integer, primary_key=True, autoincrement=True)
    nickname = Column(String(50), unique=True, nullable=False)
    contrasena = Column(String(255), nullable=False)
    correo_electronico = Column(String(100), unique=True, nullable=False)

    perfil = relationship("Perfil", back_populates="usuario", uselist=False)
    contratos = relationship("Contrato", back_populates="usuario")

class Perfil(Base):
    __tablename__ = 'perfiles'
    id_perfil = Column(Integer, primary_key=True, autoincrement=True)
    id_usuario = Column(Integer, ForeignKey('usuarios.id_usuario'))
    nombre = Column(String(50))
    apellidos = Column(String(100))
    edad = Column(Integer)
    numero_movil = Column(String(15))
    dni = Column(String(20), unique=True, nullable=False)
    fecha_nacimiento = Column(Date)

    usuario = relationship("Usuario", back_populates="perfil")

class Contrato(Base):
    __tablename__ = 'contratos'
    id_contrato = Column(Integer, primary_key=True, autoincrement=True)
    id_usuario = Column(Integer, ForeignKey('usuarios.id_usuario'))
    tipo_contrato = Column(String(50))
    direccion_postal = Column(String(255))
    ciudad = Column(String(100))
    codigo_postal = Column(String(10))
    pais = Column(String(50))  # Ajustado según la definición de la base de datos
    fecha_contrato = Column(DateTime)
    fecha_fin_contrato = Column(DateTime)

    usuario = relationship("Usuario", back_populates="contratos")
    visualizaciones = relationship("Visualizacion", back_populates="contrato")

class Pelicula(Base):
    __tablename__ = 'peliculas'
    id_pelicula = Column(Integer, primary_key=True, autoincrement=True)
    titulo = Column(String(255))
    director = Column(String(100))
    reparto = Column(Text)
    duracion = Column(Integer)
    color = Column(Boolean)
    relacion_aspecto = Column(String(10))
    anio_estreno = Column(Integer)
    calificacion_edad = Column(String(20))
    pais_produccion = Column(String(50))
    idioma_vo = Column(String(50))
    presupuesto = Column(DECIMAL(15, 2))
    ingresos_brutos = Column(DECIMAL(15, 2))
    link_imdb = Column(String(255))

    visualizaciones = relationship("Visualizacion", back_populates="pelicula")
    generos = relationship("Genero", secondary=pelicula_generos, back_populates="peliculas")
    palabras_clave = relationship("PalabraClave", secondary=pelicula_palabras_clave, back_populates="peliculas")

class Genero(Base):
    __tablename__ = 'generos'
    id_genero = Column(Integer, primary_key=True, autoincrement=True)
    nombre_genero = Column(String(50), unique=True)

    peliculas = relationship("Pelicula", secondary=pelicula_generos, back_populates="generos")

class PalabraClave(Base):
    __tablename__ = 'palabrasclave'
    id_palabra = Column(Integer, primary_key=True, autoincrement=True)
    palabra = Column(String(50), unique=True)

    peliculas = relationship("Pelicula", secondary=pelicula_palabras_clave, back_populates="palabras_clave")

class Visualizacion(Base):
    __tablename__ = 'visualizaciones'
    id_visualizacion = Column(Integer, primary_key=True, autoincrement=True)
    id_contrato = Column(Integer, ForeignKey('contratos.id_contrato'))
    id_pelicula = Column(Integer, ForeignKey('peliculas.id_pelicula'))
    fecha_visualizacion = Column(DateTime)

    contrato = relationship("Contrato", back_populates="visualizaciones")
    pelicula = relationship("Pelicula", back_populates="visualizaciones")

# Crear conexión a la base de datos
temp_engine = create_engine(connection_string)
with temp_engine.connect() as conn:
    conn.execute(text("DROP DATABASE IF EXISTS MovieBind"))
    conn.execute(text("CREATE DATABASE IF NOT EXISTS MovieBind"))
    conn.execute(text("USE MovieBind"))

# Crear la conexión a la base de datos definitiva
engine = create_engine(connection_string)
Base.metadata.create_all(engine)

# Crear sesión para interactuar con la base de datos
Session = sessionmaker(bind=engine)
session = Session()

# Función para generar datos de prueba
def generate_fake_data(session):
    try:
        print("Iniciando la generación de datos...")

        # Crear géneros y palabras clave
        generos = [Genero(nombre_genero=fake.unique.word()[:50]) for _ in range(5)]
        palabras_clave = [PalabraClave(palabra=fake.unique.word()[:50]) for _ in range(10)]
        session.add_all(generos + palabras_clave)
        session.commit()
        print("Géneros y palabras clave insertados.")

        # Crear usuarios, perfiles y contratos
        for i in range(10):
            usuario = Usuario(
                nickname=fake.unique.user_name()[:50],
                contrasena=fake.password()[:255],
                correo_electronico=fake.unique.email()[:100]
            )
            session.add(usuario)
            session.flush()  # Obtener ID generado
            print(f"Usuario {i + 1} creado.")

            perfil = Perfil(
                id_usuario=usuario.id_usuario,
                nombre=fake.first_name()[:50],
                apellidos=fake.last_name()[:100],
                edad=random.randint(18, 60),
                numero_movil=fake.numerify("###########")[:15],
                dni=fake.unique.ssn()[:20],
                fecha_nacimiento=fake.date_of_birth()
            )
            session.add(perfil)

            for j in range(random.randint(1, 3)):
                contrato = Contrato(
                    id_usuario=usuario.id_usuario,
                    tipo_contrato=fake.word()[:50],
                    direccion_postal=fake.address()[:255],
                    ciudad=fake.city()[:100],
                    codigo_postal=fake.zipcode()[:10],
                    pais=fake.country()[:50],
                    fecha_contrato=fake.date_time_this_year(),
                    fecha_fin_contrato=fake.date_time_this_year()
                )
                session.add(contrato)
                session.flush()
                print(f"Contrato {j + 1} creado para el usuario {i + 1}.")

                for k in range(random.randint(1, 5)):
                    pelicula = Pelicula(
                        titulo=fake.sentence(nb_words=3)[:255],
                        director=fake.name()[:100],
                        reparto=fake.name(),
                        duracion=random.randint(80, 180),
                        color=bool(random.getrandbits(1)),
                        relacion_aspecto="16:9",
                        anio_estreno=random.randint(1980, 2023),
                        calificacion_edad=fake.word()[:20],
                        pais_produccion=fake.country()[:50],
                        idioma_vo=fake.language_name()[:50],
                        presupuesto=round(random.uniform(1_000_000, 100_000_000), 2),
                        ingresos_brutos=round(random.uniform(1_000_000, 200_000_000), 2),
                        link_imdb=fake.url()[:255]
                    )
                    pelicula.generos = random.sample(generos, random.randint(1, 3))
                    pelicula.palabras_clave = random.sample(palabras_clave, random.randint(1, 3))
                    session.add(pelicula)
                    session.flush()

                    visualizacion = Visualizacion(
                        id_contrato=contrato.id_contrato,
                        id_pelicula=pelicula.id_pelicula,
                        fecha_visualizacion=fake.date_time_this_year()
                    )
                    session.add(visualizacion)
                    print(f"Visualización {k + 1} creada para el contrato {j + 1} del usuario {i + 1}.")

        session.commit()
        print("Inserciones completadas exitosamente.")

    except Exception as e:
        print(f"Error durante la inserción de datos: {e}")
        session.rollback()

# Llamar a la función pasando la sesión
generate_fake_data(session)

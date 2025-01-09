-- Crear base de datos
CREATE DATABASE MovieBind;
USE MovieBind;

-- Tabla para usuarios
CREATE TABLE Usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nickname VARCHAR(50) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL CHECK (CHAR_LENGTH(contrasena) >= 8),
    correo_electronico VARCHAR(100) UNIQUE NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabla para perfiles de usuarios
CREATE TABLE Perfiles (
    id_perfil INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT UNIQUE NOT NULL,
    nombre VARCHAR(50),
    apellidos VARCHAR(100),
    edad INT CHECK (edad >= 0),
    numero_movil VARCHAR(15),
    dni VARCHAR(20) UNIQUE NOT NULL,
    fecha_nacimiento DATE,
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabla para géneros
CREATE TABLE Generos (
    id_genero INT AUTO_INCREMENT PRIMARY KEY,
    nombre_genero VARCHAR(50) UNIQUE NOT NULL
) ENGINE=InnoDB;

-- Tabla para películas
CREATE TABLE Peliculas (
    id_pelicula INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    director VARCHAR(100) NOT NULL,
    reparto TEXT,
    duracion INT CHECK (duracion > 0),
    color BOOLEAN NOT NULL,
    relacion_aspecto VARCHAR(10),
    anio_estreno YEAR,
    calificacion_edad VARCHAR(20),
    pais_produccion VARCHAR(50),
    idioma_vo VARCHAR(50),
    presupuesto DECIMAL(15,2),
    ingresos_brutos DECIMAL(15,2),
    link_imdb VARCHAR(255)
) ENGINE=InnoDB;

-- Tabla para géneros asociados a películas
CREATE TABLE Pelicula_Generos (
    id_pelicula INT NOT NULL,
    id_genero INT NOT NULL,
    PRIMARY KEY (id_pelicula, id_genero),
    FOREIGN KEY (id_pelicula) REFERENCES Peliculas(id_pelicula) ON DELETE CASCADE,
    FOREIGN KEY (id_genero) REFERENCES Generos(id_genero) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabla para palabras clave asociadas a películas
CREATE TABLE PalabrasClave (
    id_palabra INT AUTO_INCREMENT PRIMARY KEY,
    palabra VARCHAR(50) UNIQUE NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Pelicula_PalabrasClave (
    id_pelicula INT NOT NULL,
    id_palabra INT NOT NULL,
    PRIMARY KEY (id_pelicula, id_palabra),
    FOREIGN KEY (id_pelicula) REFERENCES Peliculas(id_pelicula) ON DELETE CASCADE,
    FOREIGN KEY (id_palabra) REFERENCES PalabrasClave(id_palabra) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabla para contratos
CREATE TABLE Contratos (
    id_contrato INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    tipo_contrato VARCHAR(50) NOT NULL,
    direccion_postal VARCHAR(255),
    ciudad VARCHAR(100),
    codigo_postal VARCHAR(10),
    pais VARCHAR(50),
    fecha_contratacion DATE NOT NULL,
    fecha_fin DATE,
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabla para visualización de contenidos
CREATE TABLE Visualizaciones (
    id_visualizacion INT AUTO_INCREMENT PRIMARY KEY,
    id_contrato INT NOT NULL,
    id_pelicula INT NOT NULL,
    fecha_visualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_contrato) REFERENCES Contratos(id_contrato) ON DELETE CASCADE,
    FOREIGN KEY (id_pelicula) REFERENCES Peliculas(id_pelicula) ON DELETE CASCADE
) ENGINE=InnoDB;

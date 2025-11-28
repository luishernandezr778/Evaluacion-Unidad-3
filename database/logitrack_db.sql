CREATE DATABASE logitrack_db;

USE logitrack_db;

-- Tabla de conductores
CREATE TABLE conductores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(50) UNIQUE NOT NULL,
    clave_md5 VARCHAR(100) NOT NULL,
    nombre_completo VARCHAR(100)
);

-- Tabla de envios
CREATE TABLE envios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    conductor_id INT,
    direccion_destino TEXT NOT NULL,
    latitud DOUBLE,
    longitud DOUBLE,
    estatus ENUM('activo', 'finalizado') DEFAULT 'activo',
    url_evidencia VARCHAR(255),
    fecha_entrega DATETIME,
    gps_real VARCHAR(100),
    FOREIGN KEY (conductor_id) REFERENCES conductores (id)
);

INSERT INTO
    conductores (
        usuario,
        clave_md5,
        nombre_completo
    )
VALUES (
        'luis',
        'e2fc714c4727ee9395f324cd2e7f331f',
        'Luis Hernandez'
    );

INSERT INTO
    envios (
        conductor_id,
        direccion_destino,
        latitud,
        longitud
    )
VALUES (
        1,
        'Plaza de Armas, Centro',
        20.5928,
        -100.3900
    ),
    (
        1,
        'Terminal de Autobuses TAQ',
        20.5699,
        -100.3644
    );

(
    1,
    'Los Arcos, Calzada de los Arcos',
    20.5936,
    -100.3756
),
(
    1,
    'Plaza Antea Lifestyle Center',
    20.6693,
    -100.4357
),
(
    1,
    'Universidad Tecnologica (UTEQ)',
    20.6471,
    -100.4059
),
(
    1,
    'Parque Industrial Benito Juarez',
    20.6329,
    -100.4578
);
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import mysql.connector
import hashlib
import os
from datetime import datetime

app = FastAPI(title="API LogiTrack")

# Permisos para que no falle en Chrome/Móvil
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuración de Conexión
CONFIG_BD = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'logitrack_db'
}

class ModeloLogin(BaseModel):
    usuario: str
    clave: str

# 1. Login (Autenticación)
@app.post("/autenticar")
def login_conductor(datos: ModeloLogin):
    conn = mysql.connector.connect(**CONFIG_BD)
    cursor = conn.cursor(dictionary=True)
    
    # Convertir a MD5
    hash_clave = hashlib.md5(datos.clave.encode()).hexdigest()
    
    sql = "SELECT id, nombre_completo FROM conductores WHERE usuario = %s AND clave_md5 = %s"
    cursor.execute(sql, (datos.usuario, hash_clave))
    usuario_encontrado = cursor.fetchone()
    conn.close()
    
    if usuario_encontrado:
        return {"resultado": "ok", "id": usuario_encontrado['id'], "nombre": usuario_encontrado['nombre_completo']}
    else:
        raise HTTPException(status_code=401, detail="Usuario no valido")

# 2. Obtener Ruta
@app.get("/mi-ruta/{id_conductor}")
def obtener_ruta(id_conductor: int):
    conn = mysql.connector.connect(**CONFIG_BD)
    cursor = conn.cursor(dictionary=True)
    # Buscamos solo los 'activo'
    cursor.execute("SELECT * FROM envios WHERE conductor_id = %s AND estatus = 'activo'", (id_conductor,))
    lista = cursor.fetchall()
    conn.close()
    return lista

# 3. Finalizar Entrega
@app.post("/terminar")
async def terminar_envio(
    id_envio: int = Form(...),
    gps: str = Form(...),
    foto: UploadFile = File(...)
):
    # Guardar archivo con nombre único
    nombre_archivo = f"evidencia_{id_envio}_{int(datetime.now().timestamp())}.jpg"
    carpeta = "evidencias"
    os.makedirs(carpeta, exist_ok=True)
    ruta_completa = f"{carpeta}/{nombre_archivo}"
    
    with open(ruta_completa, "wb") as buffer:
        buffer.write(await foto.read())
    
    # Actualizar BD
    conn = mysql.connector.connect(**CONFIG_BD)
    cursor = conn.cursor()
    sql = """
        UPDATE envios 
        SET estatus = 'finalizado', 
            url_evidencia = %s, 
            gps_real = %s, 
            fecha_entrega = %s 
        WHERE id = %s
    """
    cursor.execute(sql, (ruta_completa, gps, datetime.now(), id_envio))
    conn.commit()
    conn.close()
    
    return {"estado": "guardado"}
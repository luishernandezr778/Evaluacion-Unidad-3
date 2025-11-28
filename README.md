# Evaluación Unidad 3 - LogiTrack 🚛

Sistema de seguimiento logístico y evidencia de entregas desarrollado para la materia de Aplicaciones Móviles.

## 👤 Alumno
**Luis Hernández**

## 🛠️ Arquitectura del Proyecto
El sistema se compone de tres módulos principales:

* 📂 **`mobile/`**: Aplicación cliente desarrollada en **Flutter** (Dart) con diseño Material Design 3.
* 📂 **`backend/`**: API RESTful desarrollada en **Python** (FastAPI).
* 📂 **`database/`**: Scripts de base de datos **MySQL**.

---

## 🔑 Datos de Acceso (Credenciales)
Para realizar las pruebas de funcionalidad, utilice el siguiente usuario conductor registrado en la base de datos:

| Campo | Valor |
| :--- | :--- |
| **Usuario** | `luis` |
| **Contraseña** | `abcd` |

> *Nota: La contraseña se almacena encriptada (MD5) en la base de datos, pero debe ingresarse como `abcd` en la aplicación.*

---

## 🚀 Guía de Instalación Rápida

### 1. Base de Datos
1.  Crear una base de datos en MySQL (XAMPP) llamada `logitrack_db`.
2.  Importar el script SQL ubicado en `database/schema.sql`.

### 2. Backend (Servidor API)
Abrir una terminal en la carpeta `backend` y ejecutar:

```bash
# Instalación de dependencias
pip install fastapi uvicorn mysql-connector-python python-multipart

# Ejecutar servidor
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
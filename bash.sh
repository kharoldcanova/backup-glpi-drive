#!/bin/sh

# ================================
# Cargar .env
# ================================
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | grep '=')
else
    echo "No se encontró el archivo .env"
    exit 1
fi

# ================================
# Defaults para rclone / Drive
# ================================
: "${RCLONE_REMOTE:=gdrive}"
: "${DRIVE_PATH:=backups-glpi}"

# ================================
# Config portátil de rclone
# ================================
RCLONE_CONFIG="./rclone.conf"

if [ ! -f "$RCLONE_CONFIG" ]; then
    echo "Falta $RCLONE_CONFIG"
    echo ""
    echo "Crealo con:"
    echo "  rclone --config $RCLONE_CONFIG config"
    echo ""
    echo "Después elegí 'Google Drive' como tipo de almacenamiento."
    echo "Cuando pregunte 'team_drive', pegá el ID del Shared Drive."
    echo "Pasos detallados en INSTRUCTIONS.md"
    exit 1
fi

# ================================
# Verificar que rclone esté instalado
# ================================
if ! command -v rclone >/dev/null 2>&1; then
    echo "rclone no está instalado. Instalalo con: sudo apt install rclone"
    exit 1
fi

# ================================
# Verificar que mysqldump exista
# ================================
if ! command -v mysqldump >/dev/null 2>&1; then
    echo "mysqldump no está instalado."
    exit 1
fi

# ================================
# Preparar carpetas locales
# ================================
mkdir -p "$BACKUP_DIR"

# ================================
# Preparar nombres y rutas
# ================================
FECHA=$(date +"%Y-%m-%d_%H-%M-%S")

ARCHIVO_LOCAL="$BACKUP_DIR/backup_$FECHA.sql"
CRED="$BACKUP_DIR/mysqldump_$FECHA.cnf"

# ================================
# Crear archivo temporal de credenciales
# ================================
(
  umask 077
  cat > "$CRED" <<EOF
[client]
user=$DB_USER
password=$DB_PASS
host=$DB_HOST
port=$DB_PORT
EOF
)

# ================================
# Ejecutar mysqldump LOCAL
# ================================
echo "Generando respaldo de la base de datos..."

mysqldump \
    --defaults-extra-file="$CRED" \
    --ssl=0 \
    "$DB_NAME" > "$ARCHIVO_LOCAL"

STATUS=$?

# Eliminar credenciales temporales
rm -f "$CRED"

if [ $STATUS -ne 0 ]; then
    echo "Error generando el respaldo."
    exit 1
fi

# ================================
# Validar que NO esté vacío
# ================================
if [ ! -s "$ARCHIVO_LOCAL" ]; then
    echo "El archivo generado está vacío."
    exit 1
fi

# ================================
# Comprimir respaldo local
# ================================
echo "Comprimiendo respaldo..."

gzip -f "$ARCHIVO_LOCAL"

ARCHIVO_LOCAL_GZ="${ARCHIVO_LOCAL}.gz"

if [ ! -s "$ARCHIVO_LOCAL_GZ" ]; then
    echo "Error comprimiendo el respaldo."
    exit 1
fi

# ================================
# Subir a Google Drive
# ================================
echo "Subiendo a Google Drive: $RCLONE_REMOTE:$DRIVE_PATH/"

rclone --config "$RCLONE_CONFIG" copy "$ARCHIVO_LOCAL_GZ" "$RCLONE_REMOTE:$DRIVE_PATH/"

if [ $? -ne 0 ]; then
    echo "Error subiendo el respaldo a Google Drive."
    exit 1
fi

echo "Respaldo completado correctamente:"
echo "$ARCHIVO_LOCAL_GZ"
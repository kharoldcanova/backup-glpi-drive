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
# Preparar carpetas locales
# ================================
mkdir -p "$BACKUP_DIR"

mkdir -p ~/.ssh
chmod 700 ~/.ssh

KEY_PATH="$HOME/.ssh/id_backup"

# ================================
# Generar llave si no existe
# ================================
if [ ! -f "$KEY_PATH" ]; then
    echo "Generando llave SSH..."
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" >/dev/null
fi

# ================================
# Instalar clave SSH si no está autorizada
# ================================
if ! ssh -p "$SSH_PORT" -i "$KEY_PATH" -o BatchMode=yes -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" "exit" 2>/dev/null; then
    echo "Instalando clave SSH en el servidor..."
    ssh-copy-id -i "$KEY_PATH.pub" -p "$SSH_PORT" "$SSH_USER@$SSH_HOST"
fi

# ================================
# Preparar nombres y rutas
# ================================
FECHA=$(date +"%Y-%m-%d_%H-%M-%S")

ARCHIVO_REMOTO="$REMOTE_TMP_DIR/backup_$FECHA.sql"
CRED="$REMOTE_TMP_DIR/mysqldump_$FECHA.cnf"

# ================================
# Ejecutar mysqldump remoto usando sh limpio
# ================================
ssh -i "$KEY_PATH" -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" "env -i sh -s" <<EOF
# Crear archivo de credenciales
echo "[client]" > "$CRED"
echo "user=$DB_USER" >> "$CRED"
echo "password=$DB_PASS" >> "$CRED"
echo "host=$DB_HOST" >> "$CRED"
echo "port=$DB_PORT" >> "$CRED"

# Ejecutar mysqldump por TCP, sin SSL ni variables raras
mysqldump --defaults-extra-file="$CRED" \
          --ssl=0 \
          "$DB_NAME" > "$ARCHIVO_REMOTO"
STATUS=$?

rm -f "$CRED"

exit \$STATUS
EOF

# ================================
# Verificar éxito del dump
# ================================
if [ $? -ne 0 ]; then
    echo "Error generando el respaldo remoto."
    exit 1
fi

# ================================
# Descargar respaldo
# ================================
ARCHIVO_LOCAL="$BACKUP_DIR/backup_$FECHA.sql"

scp -i "$KEY_PATH" -P "$SSH_PORT" "$SSH_USER@$SSH_HOST:$ARCHIVO_REMOTO" "$ARCHIVO_LOCAL"

if [ $? -ne 0 ]; then
    echo "Error descargando el respaldo."
    exit 1
fi

# ================================
# Validar que NO esté vacío
# ================================
if [ ! -s "$ARCHIVO_LOCAL" ]; then
    echo "El archivo descargado está vacío. Algo falló en el mysqldump."
    exit 1
fi

# ================================
# Limpiar archivo remoto
# ================================
ssh -i "$KEY_PATH" -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "rm -f $ARCHIVO_REMOTO"

echo "Respaldo completado correctamente: $ARCHIVO_LOCAL"
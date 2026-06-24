# Instrucciones

## Setup inicial (una sola vez)

### 1. Instalar rclone (en el servidor)

```bash
sudo apt install rclone    # Debian/Ubuntu
# o seguí https://rclone.org/install/ para otras distros
```

### 2. Obtener el ID del Shared Drive

1. Andá a [drive.google.com](https://drive.google.com/)
2. Abrí el Shared Drive **"Mil Mujeres"** (o donde quieras dejar los backups)
3. En la barra del navegador fijate en la URL
4. Es algo como `https://drive.google.com/drive/folders/0ABCDEF123456789?resourcekey=...`
5. El ID es el texto entre `/folders/` y `?` → `0ABCDEF123456789`
6. Copialo, lo vas a necesitar en el paso siguiente

### 3. Configurar rclone

Ejecutá el asistente:

```bash
rclone --config ./rclone.conf config
```

Respuestas del asistente:

| Paso | Respuesta |
|---|---|
| `n)` New remote | `n` |
| **name** | `gdrive` |
| **Storage** | Elegí el número de `Google Drive` |
| **client_id** | Enter (vacío) |
| **client_secret** | Enter (vacío) |
| **scope** | `1` (`drive.file`) |
| **root_folder_id** | Enter (vacío) |
| **service_account_file** | Enter (vacío) |
| **Edit advanced config** | `n` |
| **Use auto config?** | `n` → Te va a mostrar una URL larga |
| | Copiá la URL, abrila en **tu máquina local** o celular |
| | Iniciá sesión con tu usuario de Google, aceptá los permisos |
| | Te va a dar un código de verificación → lo pegás en el terminal |
| **Configure this as a Shared Drive?** | `y` |
| **team_drive ID** | Pegá el ID que copiaste en el paso 2 |
| **Keep this remote?** | `y` |
| **q)** Quit | `q` |

### 4. Crear carpeta en Drive

1. Dentro del Shared Drive "Mil Mujeres", creá una carpeta `backups-glpi`
2. No hace falta compartirla con nadie — el usuario con el que te autenticaste ya tiene acceso

> Si cambiás `DRIVE_PATH` en el `.env`, creá la carpeta con ese nombre en el Shared Drive.

### 5. Configurar `.env`

```bash
cp .env.example .env
```

Completá con los datos de tu base de datos:

```env
DB_USER=glpi
DB_PASS=password_segura
DB_HOST=localhost
DB_PORT=3306
DB_NAME=glpi
BACKUP_DIR=/var/backups/glpi
```

Opcionales (tienen defaults):

```env
RCLONE_REMOTE=gdrive
DRIVE_PATH=backups-glpi
```

### 6. Probar

```bash
chmod +x bash.sh
./bash.sh
```

Si todo funciona, el backup aparece en `$BACKUP_DIR` y en Drive dentro de `backups-glpi/`.

---

## Ejecución diaria con cron

```bash
crontab -e
```

Agregá esta línea (ejecuta todos los días a las 3 AM):

```
0 3 * * * /ruta/completa/hasta/backup-glpi-drive/bash.sh >> /var/log/backup-glpi.log 2>&1
```

**Importante**: usá la ruta **absoluta** a `bash.sh` porque cron no corre desde el mismo directorio que tu terminal.

Reemplazá `/ruta/completa/hasta/` por la ruta real del proyecto (usá `pwd` para obtenerla si no estás seguro).

Para ver los logs:

```bash
tail -f /var/log/backup-glpi.log
```

Para listar los backups programados:

```bash
crontab -l
```

---

## Restauración de un backup

```bash
gunzip -c /var/backups/glpi/backup_2026-06-24_03-00-00.sql.gz | mysql -u glpi -p glpi
```

O descomprimilo primero:

```bash
gunzip /var/backups/glpi/backup_2026-06-24_03-00-00.sql.gz
mysql -u glpi -p glpi < /var/backups/glpi/backup_2026-06-24_03-00-00.sql
```

---

## Descargar un backup desde Drive

Con rclone instalado en cualquier máquina:

```bash
rclone config   # configurar el mismo remote si no está
rclone copy gdrive:backups-glpi/backup_2026-06-24_03-00-00.sql.gz ./
```

---

## Troubleshooting

| Problema | Causa probable | Solución |
|---|---|---|---|
| `Falta rclone.conf` | No se configuró rclone | `rclone --config ./rclone.conf config` |
| `rclone no está instalado` | Falta instalar rclone | `sudo apt install rclone` |
| `Error subiendo a Google Drive` | El usuario no tiene acceso al Shared Drive | Verificá que el usuario con el que te autenticaste tenga acceso al Shared Drive |
| `team_drive` no se pregunta | No se respondió `y` en "Configure as a Shared Drive?" | Borrá el remote y volvé a configurar |
| `Error generando el respaldo` | Credenciales de DB incorrectas | Revisá `.env` |
| El backup se sube pero no se ve en Drive | Ruta de carpeta incorrecta | Verificá `DRIVE_PATH` y que exista en el Shared Drive |
| Cron no ejecuta el script | Ruta relativa en crontab | Usá la ruta absoluta al script |

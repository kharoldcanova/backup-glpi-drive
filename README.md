# backup-glpi-drive

Respaldo automatizado de bases de datos MySQL/MariaDB con subida a Google Drive.

## Pipeline

```
mysqldump → .sql → gzip → .sql.gz → rclone → Google Drive
                                      └── queda copia local
```

## Requisitos

- `mysqldump` (incluido con MySQL/MariaDB)
- `rclone` ([instalación](https://rclone.org/install/))
- `gzip`
- Usuario de Google con acceso al Shared Drive donde se guardarán los backups

## Variables de entorno (`.env`)

| Variable | Default | Obligatoria | Descripción |
|---|---|---|---|
| `DB_USER` | — | sí | Usuario de base de datos |
| `DB_PASS` | — | sí | Contraseña |
| `DB_HOST` | — | sí | Host de la base de datos |
| `DB_PORT` | — | sí | Puerto |
| `DB_NAME` | — | sí | Nombre de la base de datos |
| `BACKUP_DIR` | — | sí | Carpeta local de backups |
| `RCLONE_REMOTE` | `gdrive` | no | Nombre del remote en rclone |
| `DRIVE_PATH` | `backups-glpi` | no | Carpeta destino en Google Drive |

## Uso rápido

```bash
cp .env.example .env        # crear y completar .env
chmod +x bash.sh
rclone --config ./rclone.conf config   # configurar remote (ver INSTRUCTIONS.md)
./bash.sh
```

## Archivos

| Archivo | Descripción |
|---|---|
| `bash.sh` | Script principal de backup |
| `rclone.conf` | Config de rclone (se genera con `rclone --config ./rclone.conf config`) |
| `.env` | Variables de entorno |
| `INSTRUCTIONS.md` | Setup detallado, cron y restauración |

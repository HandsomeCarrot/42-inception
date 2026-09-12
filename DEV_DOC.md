# Developer Documentation

First-time environment setup, Makefile/Compose usage, layout, and internals.

Daily start/stop, URLs, and credentials: [USER_DOC.md](USER_DOC.md). Project overview, short design table, resources, and AI usage: [README.md](README.md).

## Prerequisites

- Git
- Docker Engine
- Docker Compose v2 / Compose plugin
- Docker Buildx (`docker buildx version`)
- GNU Make (required for the documented workflow)
- Permission to run Docker (`sudo` or membership of the Docker group)

The Makefile, `/etc/hosts` steps, and default data paths are Linux-oriented.

## First-time setup

From the repository root:

```sh
git clone https://github.com/HandsomeCarrot/42-inception.git
cd 42-inception
make setup
```

`make setup` creates `srcs/.env` (commented template), the host data directories, and empty files under `srcs/secrets/`. Fill those before the first start. Do not put passwords in `srcs/.env` or the process environment, and do not commit generated credentials.

1. In `srcs/.env`, uncomment and set at least `WORDPRESS_DOMAIN` (required) and `DATA_ROOT_PATH` (default is `/home/vpoka/data`). Other variables may stay commented; Compose defaults apply. Details: [Configuration and secrets](#configuration-and-secrets).
2. Put one password (no quotes, no extra lines) in each of:

   - `srcs/secrets/mariadb_root_password.txt`
   - `srcs/secrets/mariadb_user_password.txt`
   - `srcs/secrets/wordpress_admin_password.txt`
   - `srcs/secrets/wordpress_user_password.txt`

3. Map the domain on Linux:

   ```text
   127.0.0.1  <domain-name>
   ```

   in `/etc/hosts` (administrator privileges). Other operating systems use a different hosts file.

4. Build and start:

   ```sh
   make
   ```

5. Check `make ps`, then open `https://<domain-name>`.

## Configuration and secrets

### Environment configuration

Expected location: `srcs/.env`, next to `srcs/docker-compose.yml`. Compose loads that file automatically. `make setup` writes every variable commented out at its default, grouped by domain, database, WordPress, ports, and volumes. Uncomment a line to override a default.

A variable already set in the process environment overrides `srcs/.env`. Do not put passwords in either place.

`WORDPRESS_DOMAIN` is required (`${WORDPRESS_DOMAIN:?}`). If it is unset or empty, Compose refuses to start. Every other Compose variable has a default in `srcs/docker-compose.yml`.

Values marked **first install only** are written into persistent storage. Changing them later has no effect on an already initialized site; that needs `make fclean`, then setup and start again.

| Variable | Default | Change? | Used by | Applied |
| --- | --- | --- | --- | --- |
| `WORDPRESS_DOMAIN` | none (required) | Set to your `login.42.fr` domain | wordpress, nginx | First install (site URL); NGINX vhost on every start |
| `WORDPRESS_DB_NAME` | `wordpress` | Leave default | mariadb, wordpress | First install only |
| `WORDPRESS_DB_USER` | `wordpress` | Leave default | mariadb, wordpress | First install only |
| `WORDPRESS_DB_TABLE_PREFIX` | `wordpress_` | Leave default | wordpress | First install only |
| `DB_CHARSET` | `utf8mb4` | Leave default | mariadb, wordpress | First install only |
| `DB_COLLATE` | `utf8mb4_uca1400_ai_ci` | Leave default | mariadb, wordpress | First install only |
| `WORDPRESS_VERSION` | `7.0.4` | Leave default unless you pin another release | wordpress | First install only |
| `WORDPRESS_TITLE` | `Inception` | Optional site title | wordpress | First install only |
| `WORDPRESS_ADMIN_NAME` | `owner` | Optional; do not use a name containing `admin` | wordpress | First install only |
| `WORDPRESS_ADMIN_EMAIL` | `admin@invalid.email` | Optional dummy address | wordpress | First install only |
| `WORDPRESS_USER_NAME` | `author` | Optional extra user | wordpress | First install only |
| `WORDPRESS_USER_EMAIL` | `author@invalid.email` | Optional dummy address | wordpress | First install only |
| `NGINX_PORT` | `443` | Leave default (published HTTPS port) | nginx, wordpress | First install (site URL); port publish on every start |
| `MARIADB_PORT` | `3306` | Leave default (internal) | mariadb, wordpress | First install only |
| `WORDPRESS_FPM_PORT` | `9000` | Leave default unless it conflicts | wordpress, nginx | Every start |
| `DATA_ROOT_PATH` | `/home/vpoka/data` | Set to your storage parent directory | Compose volume devices, Makefile (`setup-dirs` / `rm-dirs`) | Every start |
| `DATA_DRIVE_DIR` | `database` | Directory name of the MariaDB storage | Compose volume `data-drive`, Makefile | Every start |
| `WEB_DRIVE_DIR` | `website` | Directory name of the WordPress storage | Compose volume `web-drive`, Makefile | Every start |

The Makefile reads `srcs/.env` and exports the volume variables so `setup-dirs` / `rm-dirs` use the same paths as Compose. Full host paths are `DATA_ROOT_PATH/DATA_DRIVE_DIR` and `DATA_ROOT_PATH/WEB_DRIVE_DIR`. `rm-dirs` removes `DATA_ROOT_PATH` entirely.

Compose also injects secret *path* variables into containers. These are fixed mount paths, not passwords. Do not set them in `srcs/.env`:

| Variable | Value inside the container |
| --- | --- |
| `MARIADB_ROOT_PASSWORD_FILE` | `/run/secrets/mariadb_root_password` |
| `MARIADB_USER_PASSWORD_FILE` | `/run/secrets/mariadb_user_password` |
| `WORDPRESS_ADMIN_PASSWORD_FILE` | `/run/secrets/wordpress_admin_password` |
| `WORDPRESS_USER_PASSWORD_FILE` | `/run/secrets/wordpress_user_password` |

### Docker secrets

`make setup` creates empty placeholders under `srcs/secrets`. Each file must contain a single password before the first start. Compose maps them as Docker secrets; containers see them under `/run/secrets/<secret-name>` (no `.txt` suffix).

| Host file | Compose secret name | Mounted as | Consumed by |
| --- | --- | --- | --- |
| `srcs/secrets/mariadb_root_password.txt` | `mariadb_root_password` | `/run/secrets/mariadb_root_password` | mariadb |
| `srcs/secrets/mariadb_user_password.txt` | `mariadb_user_password` | `/run/secrets/mariadb_user_password` | mariadb, wordpress |
| `srcs/secrets/wordpress_admin_password.txt` | `wordpress_admin_password` | `/run/secrets/wordpress_admin_password` | wordpress |
| `srcs/secrets/wordpress_user_password.txt` | `wordpress_user_password` | `/run/secrets/wordpress_user_password` | wordpress |

A secret should be read from its mounted file by the startup script, held only as long as needed, and never printed. Do not use `ARG`, `ENV`, `COPY`, or command-line arguments to embed secret values in an image.

Where operators find login names and which file is which password: [Credentials](USER_DOC.md#credentials).

### Cleanup implications

`fclean` depends on `clean`, `rm-env`, `rm-secrets`, and `rm-dirs`. It removes environment configuration, secret files, and persistent storage, including `DATA_ROOT_PATH`. Intentional and destructive.

When changing a secret name, environment variable, path, or setup script, update Compose, the consuming entry scripts, Makefile setup/cleanup rules, and the documentation together.

## Project layout

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs/
    ├── .env                          # generated by `make setup`; not committed
    ├── docker-compose.yml
    ├── secrets/                      # generated by `make setup`; not committed
    │   ├── mariadb_root_password.txt
    │   ├── mariadb_user_password.txt
    │   ├── wordpress_admin_password.txt
    │   └── wordpress_user_password.txt
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── config/
        │       ├── entry.sh
        │       ├── my.cnf
        │       └── setup.sql
        ├── nginx/
        │   ├── Dockerfile
        │   └── config/
        │       ├── entry.sh
        │       ├── nginx.conf
        │       ├── nginx_security_headers.conf
        │       └── nginx_expected_key.txt
        └── wordpress/
            ├── Dockerfile
            └── config/
                ├── entry.sh
                ├── php-fpm.conf
                ├── php.ini
                └── wp-cli.yml
```

Each Dockerfile builds one service image. Config files define daemon behavior. Each `entry.sh` does runtime work that cannot be finished at image build. MariaDB uses `setup.sql` for database/user provisioning. WordPress uses WP-CLI for install automation. NGINX keeps its expected signing key in a separate file used only while installing NGINX.

The stack is declared in `srcs/docker-compose.yml`. The Makefile always calls:

```make
COMPOSE := docker compose -f srcs/docker-compose.yml
```

## Design decisions

### Virtual Machines vs Docker

A virtual machine emulates hardware and runs a full guest operating system. Docker containers share the host kernel and isolate processes, filesystems, networking, and dependencies at the service level.

Docker fits because NGINX, WordPress/PHP-FPM, and MariaDB have separate responsibilities and lifecycles. Each image is built and configured on its own; Compose declares how they connect and starts the set reproducibly. Containers are not equivalent to VMs as isolation boundaries; they are a lighter way to deploy services.

### Secrets vs environment variables

Confidential credentials are separated from ordinary configuration:

- Docker secrets hold passwords and are mounted as files in the containers that need them.
- Environment variables hold non-sensitive settings (charset, collation, names, domain).
- MariaDB is given paths such as `/run/secrets/mariadb_root_password`, not the password values themselves as env vars.

That avoids baking credentials into Dockerfiles or image layers and reduces the chance they appear in configuration dumps or logs.

Generated secret files live under `srcs/secrets`. Do not commit them or copy their values into `srcs/.env`.

### Docker network vs host network

Services communicate on Compose networks, not the host network. Compose DNS lets a service reach another by service name without publishing every port.

Host networking would skip container network isolation and make PHP-FPM and MariaDB reachable from the host. NGINX is the only ingress. This project uses two bridge networks: `data-net` (MariaDB ↔ WordPress) and `web-net` (NGINX ↔ WordPress). The database is not on `web-net`.

### Docker volumes vs bind mounts

A named volume is managed by Docker. A bind mount maps a chosen host path into a container. Here, Compose declares named volumes (`data-drive`, `web-drive`) whose local driver uses `type: none`, `o: bind`, and a `device` path under `DATA_ROOT_PATH`. That is Docker volume syntax with predictable host-backed storage.

WordPress files and MariaDB data are kept out of each container’s writable layer so a restart or recreate does not force a new install. The two datasets have different ownership and recovery needs, so they are separate volumes. Changing storage declarations, host paths, or permissions affects initialization and retention — test those changes carefully.

## Implementation

All mandatory service Dockerfiles use `alpine:3.23`. Alpine keeps the package set small. It also means BusyBox and `musl` rather than glibc: command behavior, library compatibility, package names, and debugging can differ from Debian-based images.

```text
Host browser
    │ HTTPS :443
    ▼
NGINX
    │ FastCGI over web-net
    ▼
WordPress + PHP-FPM
    │ MariaDB protocol over data-net
    ▼
MariaDB
```

NGINX is the only host-facing service. It terminates HTTPS and forwards PHP to WordPress/PHP-FPM. WordPress talks to MariaDB by service name. Neither WordPress nor MariaDB publishes a port to the host.

### NGINX image

The NGINX Dockerfile installs NGINX from its official repository and checks the expected signing key first. The key is bind-mounted at build time so it is not left in an image layer.

The image gets the NGINX config, security-header config, and entry script. The entry script prepares TLS material at runtime, then runs NGINX in the foreground.

### WordPress image

The WordPress image installs PHP-FPM and a verified WP-CLI package, plus PHP-FPM/PHP/WP-CLI config and an entry script.

The entry script connects configuration to the initialized database, leaves an existing install alone, and starts PHP-FPM in the foreground. Installation checks must stay idempotent so a persistent WordPress directory is not overwritten on every start.

### MariaDB image

The MariaDB image includes MariaDB, `my.cnf`, `setup.sql`, and its entry script. Passwords come from secret-file paths. Compose defines a health check that WordPress waits on (`depends_on: condition: service_healthy`).

The entry script initializes a new data directory only when needed, applies setup SQL, then starts MariaDB in the foreground.

### Service initialization

**MariaDB** must be safe against both an empty and an already initialized data directory:

1. Prepare or detect the data directory.
2. Initialize only when no database state exists.
3. Read root and WordPress-user passwords from their secret files.
4. Apply `setup.sql`.
5. Start MariaDB as the foreground process.

`setup.sql` creates the WordPress database and user if needed and grants privileges. It uses `IF NOT EXISTS` so a later start does not recreate them.

**WordPress** waits until MariaDB is reachable. On first run it creates configuration and installation state (WP-CLI). Later starts must detect the persistent install and not replace config, uploads, themes, plugins, or database state. PHP-FPM stays in the foreground so Docker supervises the container.

**NGINX** owns the HTTPS endpoint: virtual host, TLS, document root, security headers, FastCGI to PHP-FPM. TLS material is runtime work in `entry.sh`. NGINX then runs in the foreground so the container exits if the web server exits.

## Networking and persistent storage

| Volume | Host path | Container path | Contents |
| --- | --- | --- | --- |
| `data-drive` | `$DATA_ROOT_PATH/$DATA_DRIVE_DIR` (default `/home/vpoka/data/database`) | `/home/data-drive` in mariadb | MariaDB tables |
| `web-drive` | `$DATA_ROOT_PATH/$WEB_DRIVE_DIR` (default `/home/vpoka/data/website`) | `/home/web-drive` in wordpress (rw) and nginx (ro) | WordPress files |

Survives `make stop`, `make down`, `make up`, image rebuilds, and container recreate.

Removed by `make fclean` / `make rm-dirs` (the whole `DATA_ROOT_PATH` tree). `make clean` runs `docker compose down --volumes --rmi all --remove-orphans`, which drops the named volumes from Compose’s point of view; the host directories themselves are deleted only by `rm-dirs`.

Wrong owner or mode on those host directories can block MariaDB init or WordPress writes. Inspect host permissions as well as the mount paths inside the container.

Hostname mapping needed to hit NGINX with the configured domain: [First-time setup](#first-time-setup). Operator warning about `fclean`: [Data](USER_DOC.md#data).

## Makefile and Docker Compose

From the repository root, `make <target>` is `docker compose -f srcs/docker-compose.yml` plus arguments. You can run either. `make help` prints the current target list.

`S` limits a command to `nginx`, `wordpress`, or `mariadb`. `C` is the command for `exec` / `run`.

| Make | Docker Compose | Notes |
| --- | --- | --- |
| `make` / `make all` | `docker compose -f srcs/docker-compose.yml up --build -d` | Build and start detached |
| `make up` | `… up -d` | Start, no rebuild |
| `make attached` | `… up` | Foreground |
| `make down` | `… down` | Stop and remove containers; keep images, host data, secrets |
| `make start` / `stop` / `restart` | `… start\|stop\|restart` | Existing containers; optional `S=` |
| `make build` | `… build` | Images only |
| `make ps` | `… ps -a` | Optional `S=` |
| `make logs` | `… logs` | Optional `S=` |
| `make pause` / `unpause` | `… pause\|unpause` | Optional `S=` |
| `make exec` | `… exec <service> <cmd or ash>` | Running container; `S` required |
| `make run` | `… run --rm <service> <cmd>` | One-off container; `S` required |
| `make clean` | `… down --volumes --rmi all --remove-orphans` | Also drops Compose volumes and project images |
| `make re` | `make clean` then `make all` | Rebuilds stack; keeps `.env`, secrets, host dirs |
| `make fclean` | `make clean` plus delete `.env`, secrets, and `DATA_ROOT_PATH` | Not a Compose command |

Setup helpers have no Compose equivalent: `make setup`, `make setup-env`, `make setup-dirs`, `make setup-secrets`, and the matching `rm-*` targets.

Examples:

```sh
make logs S=nginx
docker compose -f srcs/docker-compose.yml logs nginx

make exec S=wordpress
docker compose -f srcs/docker-compose.yml exec wordpress ash

make exec S=mariadb C="mariadb -u wordpress -p"
docker compose -f srcs/docker-compose.yml exec wordpress mariadb -u wordpress -p

make run S=wordpress C="wp --info"
docker compose -f srcs/docker-compose.yml run --rm wordpress wp --info
```

Day-to-day start/stop for an already running stack: [USER_DOC.md](USER_DOC.md#start-and-stop).

| Change | Typical action |
| --- | --- |
| Dockerfile, package, or entry script | Rebuild the image, then recreate the service |
| NGINX, PHP-FPM, PHP, or MariaDB config copied into the image | Rebuild/recreate |
| Compose environment or secret declaration | Recreate the affected service after checking the new config |
| Persistent-data path or volume declaration | Stop the stack and back up data first |

## Debugging and maintenance

```sh
make ps
make logs
```

Use `make exec S=<service>` (or `make help`) for a shell in a running container. Order of checks:

1. Docker, Compose, and Buildx are available.
2. `srcs/.env` exists, `WORDPRESS_DOMAIN` is set, and the four secret files are non-empty.
3. Container status and logs.
4. NGINX is serving `https://<domain>` (not `localhost`).
5. WordPress/PHP-FPM can reach MariaDB by service name on `data-net`.
6. Host data paths, ownership, and permissions.
7. Init stayed idempotent and did not try to recreate existing state.

Back up WordPress files and MariaDB data before changing storage or running `make fclean`. Operator-level symptoms (cert warning, domain not in hosts): [USER_DOC.md](USER_DOC.md#troubleshooting).

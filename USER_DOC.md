# User Documentation

How to run, reach, and check an already configured Inception stack.

First-time setup (clone, `.env`, secrets, data directories, hostname): [DEV_DOC.md](DEV_DOC.md#first-time-setup). What the project is and why it is built this way: [README.md](README.md).

## Services

Once the stack is up you get:

- A WordPress site over HTTPS
- The WordPress administration panel
- A MariaDB database used only by WordPress (not published to the host)

NGINX is the only process the host can connect to. WordPress/PHP-FPM and MariaDB stay on the private Docker networks.

## Access

Website:

```text
https://<domain-name>
```

Administration panel:

```text
https://<domain-name>/wp-admin
```

Use the domain from `WORDPRESS_DOMAIN` in `srcs/.env`, not `localhost`. A browser warning for a locally generated TLS certificate is expected.

If the name does not resolve, the first-time hostname mapping is missing — see [DEV_DOC.md](DEV_DOC.md#first-time-setup).

## Credentials

Usernames and dummy emails live in `srcs/.env` (`WORDPRESS_ADMIN_NAME`, `WORDPRESS_USER_NAME`, and the matching `*_EMAIL` variables). Passwords are **not** in `.env`. They are one value per file under `srcs/secrets/`:

| File | Used for |
| --- | --- |
| `srcs/secrets/wordpress_admin_password.txt` | WordPress administrator (`/wp-admin`) |
| `srcs/secrets/wordpress_user_password.txt` | Extra WordPress user |
| `srcs/secrets/mariadb_user_password.txt` | WordPress database user |
| `srcs/secrets/mariadb_root_password.txt` | MariaDB root |

Do not commit these files or put their contents in the shell environment.

After the first successful install, WordPress account passwords are in the database. Change them from `/wp-admin` (Users). Editing the secret files later does not rotate an already installed site. Database passwords are applied when MariaDB first initializes its data directory; changing those files on a running or already-initialized database does not update the live accounts. Wiring and first-install rules: [Configuration and secrets](DEV_DOC.md#configuration-and-secrets).

## Start and stop

Run these from the repository root. Every `make` target below wraps `docker compose -f srcs/docker-compose.yml`.

| Task | Make | Docker Compose |
| --- | --- | --- |
| Start (no rebuild) | `make up` | `docker compose -f srcs/docker-compose.yml up -d` |
| Stop and remove containers | `make down` | `docker compose -f srcs/docker-compose.yml down` |
| Stop, keep containers | `make stop` | `docker compose -f srcs/docker-compose.yml stop` |
| Start existing containers | `make start` | `docker compose -f srcs/docker-compose.yml start` |
| Restart | `make restart` | `docker compose -f srcs/docker-compose.yml restart` |

Limit a command to one service with `S=nginx`, `S=wordpress`, or `S=mariadb`:

```sh
make stop S=nginx
docker compose -f srcs/docker-compose.yml stop nginx
```

`make down` removes containers and the Compose networks. It does not delete WordPress files, the database, images, or secrets. Rebuilds, `exec`, and cleanup: [Makefile and Docker Compose](DEV_DOC.md#makefile-and-docker-compose).

## Checking that services are running

```sh
make ps
make logs
```

Same with Compose:

```sh
docker compose -f srcs/docker-compose.yml ps -a
docker compose -f srcs/docker-compose.yml logs
```

One service:

```sh
make logs S=nginx
docker compose -f srcs/docker-compose.yml logs nginx
```

Healthy means `make ps` shows the three services running (and healthy, when the health check has passed), logs are not in a restart loop, and `https://<domain-name>` loads. `make help` lists every target.

## Data

WordPress files and MariaDB data live on the host, so ordinary `make stop` / `make down` / `make up` keep the site.

`make fclean` is destructive: it removes containers, images, `srcs/.env`, secret files, and the host data directory. Back up first if you care about the site. Paths and what each cleanup deletes: [Networking and persistent storage](DEV_DOC.md#networking-and-persistent-storage).

## Troubleshooting

### Docker command fails

The daemon must be running, and your account must be allowed to talk to it (`docker ps`, with `sudo` if needed).

### The domain does not open

Confirm `WORDPRESS_DOMAIN` and that NGINX is up (`make ps`). The domain must resolve to this machine (see first-time setup in DEV_DOC).

### HTTPS shows a warning

Expected for a local certificate. Open the configured domain, not `localhost`.

### A container exits during startup

`make logs` (or `make logs S=<service>`). Missing or empty secret files and an unset `WORDPRESS_DOMAIN` are the usual causes. `make check` verifies `.env`, secrets, domain, and host data directories. Deeper checks: [Debugging and maintenance](DEV_DOC.md#debugging-and-maintenance).

### A full cleanup removed my site

Expected after `make fclean`. Restore a backup, or set the project up again from [DEV_DOC.md](DEV_DOC.md#first-time-setup).

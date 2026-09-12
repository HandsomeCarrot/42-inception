*This project has been created as part of the 42 curriculum by vpoka.*

# Inception

## Description

Inception is a local WordPress deployment built from three Docker images and orchestrated with Docker Compose. The goal is a reproducible HTTPS site whose services are isolated from one another, built locally, and restarted without losing data.

| Service | Role | Reachable from the host |
| --- | --- | --- |
| NGINX | HTTPS entry point and reverse proxy | Yes — port 443 |
| WordPress + PHP-FPM | Application and PHP execution | No — internal network only |
| MariaDB | WordPress database | No — internal network only |

`Browser → NGINX (HTTPS) → WordPress/PHP-FPM → MariaDB`

Docker is used so each service is a container with its own filesystem, process tree, and lifecycle, without a full guest operating system per service. Compose declares the network, volumes, secrets, and startup order. Only NGINX publishes a port; WordPress and MariaDB stay on private Compose networks.

The images are not pulled from Docker Hub as ready-made WordPress, NGINX, or MariaDB images. Each service is built from sources in this repository: a Dockerfile plus config and an entry script under `srcs/requirements/nginx`, `srcs/requirements/wordpress`, and `srcs/requirements/mariadb`. Compose (`srcs/docker-compose.yml`) and the root `Makefile` wire those images into one stack.

### Design choices

| Topic | Choice | Rationale |
| --- | --- | --- |
| Virtual Machines vs Docker | Docker containers | Isolation at service level without a guest OS per service. Compose makes the whole stack one reproducible unit. |
| Secrets vs Environment Variables | Docker secrets for passwords; environment variables for the rest | Credentials are mounted as files, not baked into images or dumped with ordinary env. Names, domain, and charset stay in `srcs/.env`. |
| Docker Network vs Host Network | Private Compose networks | Services talk by name on isolated networks. Only NGINX is published to the host. |
| Docker Volumes vs Bind Mounts | Compose volumes backed by host directories | WordPress files and MariaDB data outlive containers. Host paths stay predictable via `DATA_ROOT_PATH`, `DATA_DRIVE_DIR`, and `WEB_DRIVE_DIR`. |

Longer comparisons and how this repo implements them: [DEV_DOC.md](DEV_DOC.md#design-decisions).

## Documentation

- [USER_DOC.md](USER_DOC.md) — operate an already configured stack (start/stop, URLs, credentials, health).
- [DEV_DOC.md](DEV_DOC.md) — first-time setup, Makefile/Compose commands, layout, and internals.

## Instructions

Needs Docker Engine, Docker Compose v2, and (for the documented workflow) GNU Make on Linux. Full tool list and first-time setup: [DEV_DOC.md](DEV_DOC.md#prerequisites).

1. Clone the repository and enter it:

   ```sh
   git clone https://github.com/HandsomeCarrot/42-inception.git
   cd 42-inception
   ```

2. First time only: create and fill configuration, secrets, and the local hostname — [First-time setup](DEV_DOC.md#first-time-setup).
3. Build and start: `make`
4. Open `https://<your-domain>`
5. Afterwards, start and stop with the commands in [USER_DOC.md](USER_DOC.md#start-and-stop). `make help` lists every target.

## Resources

### Docker

- [Docker CLI](https://docs.docker.com/reference/cli/docker/)
- [Compose CLI](https://docs.docker.com/reference/cli/docker/compose/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Compose secrets](https://docs.docker.com/reference/compose-file/secrets/)
- [Dockerfile best practices](https://docs.docker.com/build/building/best-practices/)

### NGINX, TLS

- [NGINX documentation](https://nginx.org/en/docs/)
- [NGINX configuration](https://nginx.org/en/docs/beginners_guide.html)
- [FastCGI module](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)
- [SSL module](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)
- [SSL termination](https://docs.nginx.com/nginx/admin-guide/security-controls/terminating-ssl-http/)
- [`openssl req` (certificates)](https://docs.openssl.org/master/man1/openssl-req/)

### WordPress, PHP-FPM, PHP

- [WordPress documentation](https://wordpress.org/documentation/)
- [WP-CLI handbook](https://make.wordpress.org/cli/handbook/)
- [`wp core install`](https://developer.wordpress.org/cli/commands/core/install/)
- [PHP-FPM](https://www.php.net/manual/en/install.fpm.php)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [php.ini](https://www.php.net/manual/en/configuration.file.php)

### MariaDB, SQL

- [MariaDB documentation](https://mariadb.org/documentation/)
- [SQL statements](https://mariadb.com/docs/server/reference/sql-statements/)
- [Option files (`my.cnf`)](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/configuring-mariadb/configuring-mariadb-with-option-files)

### AI usage

AI tools were used as research, learning, and documentation aids. They helped clarify Docker, container networking, NGINX, WordPress, MariaDB, shell-scripting, and current technical standards; compare design options such as secrets versus environment variables; and discuss the separation of Dockerfile and entrypoint-script responsibilities.

AI assistance was also used to help draft documentation, review design questions, improve some scripts, and explore Dockerfile design choices. The infrastructure design, implementation, integration, review, adaptation, and local testing were performed by me. AI-generated suggestions were treated as input for review rather than accepted without verification.

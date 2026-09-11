# Inception

A containerized WordPress stack built with Docker Compose. It runs NGINX, WordPress with PHP-FPM, and MariaDB as separate services: NGINX is the HTTPS entry point, WordPress serves the application internally, and MariaDB provides persistent database storage.

The infrastructure follows the constraints of the 42 Inception project: services are built locally, isolated from one another, and orchestrated as a reproducible local deployment.

## Overview

| Service | Role | Accessible from the host |
| --- | --- | --- |
| NGINX | HTTPS entry point and reverse proxy for WordPress | Yes — HTTPS on port 443 |
| WordPress + PHP-FPM | WordPress application and PHP execution | No — internal network only |
| MariaDB | Persistent database for WordPress | No — internal network only |

`Browser → NGINX (HTTPS) → WordPress/PHP-FPM → MariaDB`

Only NGINX is exposed to the host. WordPress and MariaDB communicate through the private Docker network and are not directly available from outside the Compose stack.

## Design choices

| Topic | Choice | Rationale |
| --- | --- | --- |
| Virtual Machines vs Docker | Docker containers | Containers provide service isolation without requiring a full guest operating system for every service. Docker Compose also makes the complete stack reproducible and straightforward to orchestrate. |
| Secrets vs Environment Variables | Docker secrets for credentials; environment variables for non-sensitive settings | Passwords and other credentials are supplied through Docker secrets rather than ordinary environment variables. Non-sensitive configuration, such as names and domain-related settings, remains easier to manage in an environment file. |
| Docker Network vs Host Network | A private Docker network | The services can communicate by service name on an isolated internal network. Only NGINX publishes an HTTPS port to the host. |
| Docker Volumes vs Bind Mounts | Persistent Docker storage backed by host directories | WordPress files and MariaDB data are persisted outside their containers so that recreating a container does not require reinstalling WordPress or rebuilding the database. Host-backed storage also keeps the project data in a predictable local location. |

The service images use Alpine Linux as a minimal base. This keeps the images focused on the packages needed for their single responsibility and avoids including unnecessary software.

For the complete rationale and implementation details—including Dockerfiles, entrypoint scripts, Compose configuration, secrets flow, network setup, persistence, and maintenance—see [DEV_DOC.md](DEV_DOC.md).

## Documentation

- [USER_DOC.md](USER_DOC.md) — Instructions for configuring, starting, accessing, operating, stopping, and resetting the deployment.
- [DEV_DOC.md](DEV_DOC.md) — Technical documentation for understanding, developing, modifying, and maintaining the infrastructure.

## Prerequisites

This project can run on systems that support Docker and Docker Compose. The supplied Makefile workflow is designed for Linux, however, so its rules may not work unchanged on macOS, Windows, or other platforms.

- Git, to clone the repository
- Docker Engine
- Docker Compose v2 / Docker Compose plugin
- `make` — optional, but recommended on Linux for the intended convenience workflow
- Permission to run Docker commands, through either `sudo` or membership of the local Docker group
- A hostname mapping for the configured project domain

The documented hostname setup uses Linux conventions, including editing `/etc/hosts`. Other operating systems may use a different process or require different permissions. More generally, paths, permissions, shell commands, and the Makefile automation may be Linux-specific; consult [USER_DOC.md](USER_DOC.md) for the supported setup steps and platform notes.

## Getting started

1. Clone this repository with Git.
2. Prepare the required non-sensitive environment configuration and Docker secret files.
3. Configure the local hostname for the project domain.
4. Build and start the infrastructure using the documented workflow.
5. Open the configured domain with `https://`.

See [USER_DOC.md](USER_DOC.md) for the complete setup, configuration, operation, cleanup, and troubleshooting instructions. The user documentation is the source of truth for commands and should be followed instead of this brief overview.

## Resources and AI usage

### Resources

The project was developed with the following documentation as primary references:

#### General Inception

- [Inception tutorial](https://dev.to/alejiri/docker-nginx-wordpress-mariadb-tutorial-inception42-1eok)
- [Inception tutorial 2](https://sizgunan.medium.com/building-a-robust-web-infrastructure-with-docker-a-deep-dive-into-mariadb-nginx-and-wordpress-cc56bbaa04d1)
- [Man-pages for shell commands](https://man7.org/linux/man-pages/index.html)

#### Docker

- [Docker interpolation](https://docs.docker.com/reference/compose-file/interpolation)
- [Docker entrypoint guide](https://www.geeksforgeeks.org/devops/what-is-entrypoint-in-dockerfile/)
- [Heredocs in Dockerfiles](https://www.docker.com/blog/introduction-to-heredocs-in-dockerfiles/)
- [Dockerfile references](https://docs.docker.com/reference/dockerfile/)
- [Docker compose services](https://docs.docker.com/reference/compose-file/services/)
- [Dockerfile best practices](https://docs.docker.com/build/building/best-practices/)
- [Writing a dockerfile](https://docs.docker.com/get-started/docker-concepts/building-images/writing-a-dockerfile/)

#### Alpine Linux

- [Setting up a user](https://wiki.alpinelinux.org/wiki/Setting_up_a_new_user)
- [Shell management](https://wiki.alpinelinux.org/wiki/Shell_management?__goaway_challenge=cookie&__goaway_id=8b695c5bd090dad394694a7946810bc3&__goaway_referer=https%3A%2F%2Fwiki.alpinelinux.org%2Fwiki%2FBusyBox#Ash_shell)
- [Enable and start services](https://www.cyberciti.biz/faq/how-to-enable-and-start-services-on-alpine-linux/)

#### MariaDB

- [Create database for wordpress](https://developer.wordpress.org/advanced-administration/before-install/creating-database/)
- [SQL quotation rules](https://www.geeksforgeeks.org/sql/when-to-use-single-quotes-double-quotes-and-backticks-in-sql/)
- [Set Character sets and Collations](https://mariadb.com/docs/server/reference/data-types/string-data-types/character-sets/setting-character-sets-and-collations)
- [Basic SQL commands](https://www.geeksforgeeks.org/sql/basic-sql-commands/)
- [Secure mariadb installation](https://technoroots.org/insights/how-to-secure-mariadb-after-installation-on-ubuntu-GfeCf)
- [mariadb on alpine linux](https://wiki.alpinelinux.org/wiki/MariaDB)
- [remote client access guide](https://mariadb.com/docs/server/mariadb-quickstart-guides/mariadb-remote-connection-guide)
- [mariadb-install-db script docs](https://mariadb.com/docs/server/clients-and-utilities/deployment-tools/mariadb-install-db)
- [configuring with option files](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/configuring-mariadb/configuring-mariadb-with-option-files#default-option-file-hierarchy)
- [Docs](https://mariadb.org/documentation/)
- [server system variable list](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#port)
- [options](https://mariadb.com/docs/server/server-management/starting-and-stopping-mariadb/mariadbd-options)
- [primer guide](https://mariadb.com/docs/server/mariadb-quickstart-guides/mariadb-usage-guide)
- [DockerHub official image](https://hub.docker.com/_/mariadb)

#### WordPress

- [Check php-fpm health](https://stackoverflow.com/questions/14915147/how-to-check-if-php-fpm-is-running-properly)
- [php-fpm process manager modes](https://stackharbor.com/en/knowledge-base/php-fpm-process-manager-static-vs-dynamic/)
- [install wp-cli](https://make.wordpress.org/cli/handbook/guides/installing/)
- [wp-cli command 'core install'](https://developer.wordpress.org/cli/commands/core/install/)
- [WordPress software compatibility list](https://make.wordpress.org/hosting/handbook/compatibility/#wordpress-php-mysql-mariadb-versions)
- [WordPress server environment](https://make.wordpress.org/hosting/handbook/server-environment/)
- [WordPress docs](https://wordpress.org/documentation/)
- [DockerHub official image](https://hub.docker.com/_/wordpress)
- [WordPress on Alpine Linux](https://wiki.alpinelinux.org/wiki/WordPress)

#### nginx

- [ssl certificate key lengths](https://stackoverflow.com/questions/589834/what-rsa-key-length-should-i-use-for-my-ssl-certificates)
- [openssl command docs](https://docs.openssl.org/1.1.1/man1/)
- [install nginx open-source](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#repository-contents)
- [NGINX SSL Termination](https://docs.nginx.com/nginx/admin-guide/security-controls/terminating-ssl-http/)
- [nginx on alpine linux](https://wiki.alpinelinux.org/wiki/Nginx)
- [DockerHub official image](https://hub.docker.com/_/nginx)

### AI usage

AI tools were used as research, learning, and documentation aids. They helped clarify Docker, container networking, NGINX, WordPress, MariaDB, shell-scripting, and current technical standards; compare design options such as secrets versus environment variables; and discuss the separation of Dockerfile and entrypoint-script responsibilities.

AI assistance was also used to help draft documentation, review design questions, improve some scripts, and explore Dockerfile design choices. The infrastructure design, implementation, integration, review, adaptation, and local testing were performed by me. AI-generated suggestions were treated as input for review rather than accepted without verification.

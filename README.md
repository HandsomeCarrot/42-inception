# Inception

A containerized WordPress stack built with Docker Compose. It runs **NGINX**, WordPress with PHP-FPM, and MariaDB as separate services: NGINX is the HTTPS entry point, WordPress serves the application internally, and MariaDB provides persistent database storage.

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

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Docker secrets documentation](https://docs.docker.com/engine/swarm/secrets/)
- [Docker networking documentation](https://docs.docker.com/engine/network/)
- [Docker volumes and bind mounts documentation](https://docs.docker.com/engine/storage/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [WordPress documentation](https://wordpress.org/documentation/)
- [WP-CLI documentation](https://wp-cli.org/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [Alpine Linux documentation](https://docs.alpinelinux.org/)

### AI usage

AI tools were used as research, learning, and documentation aids. They helped clarify Docker, container networking, NGINX, WordPress, MariaDB, shell-scripting, and current technical standards; compare design options such as secrets versus environment variables; and discuss the separation of Dockerfile and entrypoint-script responsibilities.

AI assistance was also used to help draft documentation, review design questions, improve some scripts, and explore Dockerfile design choices. The infrastructure design, implementation, integration, review, adaptation, and local testing were performed by me. AI-generated suggestions were treated as input for review rather than accepted without verification.

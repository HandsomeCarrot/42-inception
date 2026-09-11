# User Documentation

This document explains how to run, access, stop, and reset the Inception WordPress deployment.

For a project overview and the required high-level design comparisons, see [README.md](README.md). For first-time environment and secret setup, container internals, and advanced debugging, see [DEV_DOC.md](DEV_DOC.md).

## Platform and prerequisites

The stack can run on systems that support Docker, Docker Compose, and Docker Buildx. The supplied Makefile workflow is designed for Linux, however, and is the supported workflow documented here.

On macOS, Windows, and other platforms, Docker may work but the Makefile rules, shell behavior, permissions, storage paths, and hostname setup can require adaptation.

Install or make available the following tools:

- Git
- Docker Engine
- Docker Compose v2 / Docker Compose plugin
- Docker Buildx
- GNU Make (recommended; required for the documented workflow)

You must also be allowed to run Docker commands, either through `sudo` or membership of the local Docker group.

## Get the project

Clone the repository and enter its directory:

```sh
git clone https://github.com/HandsomeCarrot/42-inception.git
cd 42-inception
```

Use the Makefile help target to view the commands supported by the checked-out version:

```sh
make help
```

## Initial configuration

Before the first build:

```sh
make setup
```

That creates `srcs/.env`, the persistent host directories, and empty secret files. Fill them before starting. Do not put passwords in `srcs/.env` or the process environment, and do not commit generated credentials.

Required variables, recommended changes, exact secret filenames, and expected paths are in [Configuration and secrets](DEV_DOC.md#configuration-and-secrets).

## Configure the local domain

NGINX serves the project under the domain configured in the local environment configuration. On Linux, map that domain to the local machine by editing the `/etc/hosts` file with administrator privileges:

```text
127.0.0.1  <domain-name>
```

Replace `<domain-name>` with the domain configured for this project. For example, if the configured domain is `example.42.fr`, add:

```text
127.0.0.1  example.42.fr
```

The `/etc/hosts` method and the commands shown here are Linux-oriented. Other operating systems may use a different process or require different permissions.

## Build and start

After completing configuration, build the service images and start the stack in detached mode:

```sh
make
```

The default target invokes Docker Compose with `srcs/docker-compose.yml`, builds the service images, and starts the containers in the background. The first launch can take longer because images and persistent service state may need to be initialized.

Check that the services are running:

```sh
make ps
```

If a service does not start, read the logs first:

```sh
make logs
```

## Access WordPress

Open the configured domain in a browser using HTTPS:

```text
https://<domain-name>
```

NGINX is the only service exposed to the host and is the entry point for browser traffic. WordPress/PHP-FPM and MariaDB are intentionally internal-only services.

If the stack uses a locally generated or self-signed TLS certificate, the browser can display a certificate warning. This is expected for a local development deployment; it is not a publicly trusted certificate.

The standard WordPress administration path is:

```text
https://<domain-name>/wp-admin
```

## Operations

The Makefile is the supported Linux command interface. Run `make help` to see the commands available in the current revision.

| Command | Purpose |
| --- | --- |
| `make` or `make all` | Build images and start the Compose services in detached mode |
| `make setup` | Create local environment configuration, persistent directories, and secret files |
| `make up` / `make down` | Start or stop the Compose stack |
| `make start` / `make stop` / `make restart` | Control the running services |
| `make build` | Build the service images |
| `make attached` | Start the stack attached to the terminal, when interactive output is wanted |
| `make ps` | Show service status |
| `make logs` | Show service logs |
| `make exec` / `make run` | Use the Makefile's container execution helpers; consult `make help` for their arguments |
| `make pause` / `make unpause` | Pause or resume services |
| `make clean` | Remove the non-persistent Compose resources defined by the Makefile |
| `make fclean` | Perform a full destructive cleanup; see the warning below |
| `make re` | Recreate the environment using the Makefile's rebuild workflow |
| `make help` | Print supported targets and usage information |

## Persistence and reset

WordPress files and MariaDB data are stored outside the containers. Normal service restarts, container recreation, and image rebuilds should therefore preserve the site installation and database state.

`make fclean` is deliberately destructive. It runs the normal cleanup and then removes the local environment configuration, Docker secret files, and the persistent storage directories, including their parent directory (`DATA_ROOT_PATH`). After it completes, configure the project again with `make setup` before starting it.

Back up WordPress files and database data before running `make fclean` if they contain anything you want to keep.

For the storage design and lifecycle details, see [Networking and persistent storage](DEV_DOC.md#networking-and-persistent-storage).

## Troubleshooting

### Docker command fails

Confirm that the Docker daemon is running and that your account has permission to communicate with it. Try `docker ps`; if it needs `sudo`, either use `sudo` consistently or configure Docker-group access according to your Linux distribution's guidance.

### Docker Buildx is unavailable

Install or enable the Docker Buildx plugin, then confirm it with `docker buildx version`. The documented build environment requires it.

### The domain does not open

Check the configured domain and make sure the matching `127.0.0.1  <domain-name>` line exists in `/etc/hosts`. Also check that NGINX is running with `make ps`.

### HTTPS shows a warning

For a locally generated/self-signed certificate, a browser warning is expected. Verify that you opened the exact configured domain rather than `localhost` or an unrelated hostname.

### A container exits during startup

Run `make logs` and check that the environment configuration and all required secret files exist and contain valid values. If needed, review the initialization and advanced debugging guidance in [DEV_DOC.md](DEV_DOC.md#debugging-and-maintenance).

### A full cleanup removed my site

This is expected after `make fclean`, which removes the project's local directories along with environment and secret files. Restore a backup if one exists; otherwise, run `make setup` and initialize the stack again.

# fzdocker Project Agent

This file captures the project conventions, service folder structure, and example patterns used across the `fzdocker` repository.

## Purpose

- Document the expected structure for each technology/service folder.
- Capture how configuration, environment handling, initialization, and runtime launch should work.
- Make it easy for an agent to answer questions about service behavior, conventions, and how to add new technologies.

## Core conventions

1. `run.sh` is the default service launcher.
   - It usually sources `../run-preprocess.tpl.sh`.
   - It may call `init.sh` for first-time setup.
   - It typically supports `--force` and `--persist`.

2. `public.env` is the public configuration file.
   - Contains non-sensitive defaults and service-level values.
   - Should be committed with the repository.
   - Loaded by `run-preprocess.tpl.sh` and can be referenced in templates.

3. `.env` is the local secret/override file.
   - Contains private values and environment overrides.
   - It may be generated from `.env.example` when missing.
   - Loaded by `run-preprocess.tpl.sh` but not necessarily committed.

4. `docker-compose.yml.tpl` is a template for generated Compose files.
   - `run.sh` often uses `envsubst` to produce `docker-compose.yml`.
   - Templates should keep sensitive values as placeholders when needed.

5. `docker-compose.yml` is either a generated artifact or a static compose file.
   - Some services use a generated file from a template.
   - Other services use a fixed compose file directly.

6. `Dockerfile` is present when the service requires a custom container build.
   - It may be built by `run-preprocess.tpl.sh` if present.

## `run-preprocess.tpl.sh` behavior

- Loads `public.env` and `.env` into the shell.
- Exports each line as environment variables.
- Ensures `public.env` exists and warns if missing.
- Builds a local Dockerfile image if `Dockerfile` exists.
- Creates the external Docker network if needed.

## Reference example: `mosquitto`

`mosquitto` is the recommended service structure for runtime configuration:

- `init.sh`
  - Creates required `./local/config` data directories.
  - Prompts for MQTT username and adds it with `mosquitto_passwd`.
  - Copies a default `mosquitto.conf` if missing.
  - Writes an initialization marker `./local/.initialized`.

- `run.sh`
  - Sources `../run-preprocess.tpl.sh`.
  - Runs `./init.sh` if initialization is not complete.
  - Starts the container with `docker run`.
  - Uses both `--env-file public.env` and `--env-file .env`.
  - Supports `--force` to remove an existing container.
  - Uses `--persist` to decide between detached and ephemeral execution.

This is the model structure for services that need both initialization and runtime launch.

## Reference example: `immich`

`immich` is the reference structure for modular Docker Compose-based services:

- `include/`
  - Contains modular service blocks for optional stack components (e.g., `include/database/compose-service` and `include/redis/compose-service`).

- `init.sh`
  - Creates local data and cache directories.
  - Evaluates feature flags (`IMMICH_CREATE_DATABASE`, `IMMICH_CREATE_REDIS`) from `public.env`/environment, or prompts interactively if unset.
  - Dynamically populates compose placeholders (`DATABASE_COMPOSE_SECTION`, `REDIS_COMPOSE_SECTION`, `DATABASE_DEPENDS_ON`, `REDIS_DEPENDS_ON`) from `include/` files.
  - Configures hostnames (`DB_HOSTNAME`, `REDIS_HOSTNAME`) depending on whether internal containers or existing external services are selected.
  - Generates `docker-compose.yml` from `docker-compose.yml.tpl` using `envsubst`.
  - Leaves secret placeholders such as `${DB_PASSWORD}` intact so they are resolved at runtime from `.env`.
  - Writes an initialization marker `./local/.initialized`.

- `docker-compose.yml.tpl`
  - Defines the modular Compose stack with placeholders for dynamically included services and dependencies.
  - Keeps sensitive secrets as placeholders.

- `run.sh`
  - Sources `../run-preprocess.tpl.sh`.
  - Checks for `./local/.initialized` and calls `init.sh` if first-time setup is needed.
  - Supports `--clean` to remove generated `docker-compose.yml`, initialization state, and local data directories (`postgres-data`, `cache`).
  - Runs `docker compose up` or `docker compose up -d` depending on `--persist`.

This is the model structure for compose-driven services with modular container selection and sensitive environment handling.

## Reference example: `postgresql`

`postgresql` is the reference structure for dynamic Dockerfile services with optional feature modules:

- `Dockerfile.tpl`
  - A Dockerfile template with placeholders such as `${PGVECTOR_DOCKERFILE_PRE}` and `${PGVECTOR_DOCKERFILE_POST}`.
  - `init.sh` uses `envsubst` to generate `Dockerfile` from this template.
  - Placeholders are populated or left empty depending on which features are enabled.

- `include/`
  - Contains feature module directories (e.g. `include/pgvector/`).
  - Each module directory can contain:
    - `dockerfile-pre` — raw Dockerfile lines inserted before the main `FROM` (e.g. multi-stage build sources).
    - `dockerfile-post` — raw Dockerfile lines appended after the main `FROM` (e.g. `RUN`, `COPY`, `CMD` overrides).
    - `post-init.sh` — a script that runs inside the container via `/docker-entrypoint-initdb.d/` on first start.
  - These are plain content files read with `cat`, not sourced as shell scripts (except `post-init.sh` which runs inside the container).

- `init.sh`
  - Sources `../run-preprocess.tpl.sh`.
  - Prompts for optional features (e.g. pgvector) if not set in `public.env`.
  - Reads feature module content from `include/` directories.
  - Generates `Dockerfile` from `Dockerfile.tpl` via `envsubst`.
  - Builds the Docker image.
  - Does NOT run `initdb` — the Docker entrypoint handles database initialization on first container start.

- `run.sh`
  - Sources `../run-preprocess.tpl.sh`.
  - Supports `--clean` to reset init state and data directory.
  - Runs `init.sh` if initialization is not complete.
  - Starts the container with `docker run`, mounting the local data directory.
  - The Docker entrypoint automatically initializes the database, sets passwords, and runs `/docker-entrypoint-initdb.d/` scripts on first start with an empty data directory.

This is the model structure for services with a dynamically generated Dockerfile and optional feature modules.

## Reference example: `traefik`

`traefik` is the reference structure for edge reverse proxy / load balancer services with dynamic file & Docker provider routing:

- `config/`
  - Contains default static configuration (`traefik.yml`) and default dynamic routing templates (e.g. `commons.yml`, `*.example.yml` for services like `openwebui`, `silverbullet`, `filebrowser`).

- `public.env`
  - Defines network name (`NETWORK_NAME`), container name (`CONTAINER_NAME`), host name (`HOST_NAME`), and ingress port mappings (`PORT_MAPPING=80`, `PORT_MAPPING_SECURE=443`, `PORT_MAPPING_DASHBOARD=8080`).

- `run.sh`
  - Sources `../run-preprocess.tpl.sh`.
  - Dynamically initializes `./local/dynamic` and populates default example route configs from `config/` on initial setup.
  - Copies default `traefik.yml` to `./local/traefik.yml` if missing.
  - Mounts `/var/run/docker.sock` for Docker container auto-discovery (`--providers.docker=true`, `--providers.docker.exposedbydefault=false`).
  - Mounts static config (`./local/traefik.yml`), dynamic configs (`./local/dynamic`), and SSL certificates (`./local/certs`).
  - Attaches to the shared Docker network (`${NETWORK_NAME}`).

- `edit.sh`
  - Helper script to open and edit dynamic route YAML files in the user's preferred editor (e.g. `gnome-text-editor`, `vim`, `vi`).

This is the model structure for edge routers, reverse proxies, and load balancers requiring dynamic route management, SSL certificate mounts, and Docker socket auto-discovery.

## Common folder archetypes

### 1. Compose-template service

Typical files:
- `run.sh`
- `docker-compose.yml.tpl`
- `public.env`
- Optional `.env`
- Optional `Dockerfile`

Examples:
- `aria2`
- `gitea`
- `grafana`
- `guacamole`
- `immich`
- `paperless`

Behavior:
- `run.sh` generates `docker-compose.yml` from the `.tpl` file.
- Public variables are substituted; secrets can remain as placeholders.
- `docker compose up` is used.

### 2. Docker-run service

Typical files:
- `run.sh`
- `public.env`
- Optional `.env`
- Optional `init.sh`
- Optional `Dockerfile`

Examples:
- `mosquitto`
- `filebrowser`
- `jupyter`
- `keycloak`
- `redis`
- `mysql`

Behavior:
- `run.sh` directly executes `docker run`.
- Environment is passed via `--env-file public.env` and `--env-file .env`.
- `init.sh` can be used for first-run configuration.

### 3. Dynamic Dockerfile service

Typical files:
- `run.sh`
- `init.sh`
- `Dockerfile.tpl`
- `public.env`
- Optional `.env`
- `include/` directory with feature module subdirectories

Examples:
- `postgresql`

Behavior:
- `init.sh` reads content files from `include/<feature>/` directories.
- `init.sh` generates `Dockerfile` from `Dockerfile.tpl` via `envsubst`.
- Feature modules provide raw Dockerfile snippets (`dockerfile-pre`, `dockerfile-post`) and entrypoint init scripts (`post-init.sh`).
- Init scripts are baked into the image via `COPY` into `/docker-entrypoint-initdb.d/`.
- Database initialization is handled by the Docker entrypoint on first start, not by `init.sh`.
- `run.sh` directly executes `docker run`.

### 4. Static compose service

Typical files:
- `docker-compose.yml`
- Optional `Dockerfile`
- Optional `public.env`
- Optional `.env`

Examples:
- `cloudcmd`
- `amazonlinux`
- `infrastructure`
- `mongodb` (also has Dockerfile)

Behavior:
- Use the compose file directly.
- May not use `run-preprocess.tpl.sh`.

## Special cases

- `cloudcmd`
  - Uses a plain `docker-compose.yml` and a `Dockerfile`.
  - Not all services need `run.sh` or Compose template generation.

- `jupyter`
  - Has `run.sh`, `docker-compose.yml`, and a `Dockerfile`.
  - The current `run.sh` runs `docker run` directly, not the compose file.
  - This means the service can behave as a special-case runtime launcher.

## Recommended rules for all technologies

- Prefer the `mosquitto` pattern when initialization is required.
- Prefer the `immich` pattern when using Docker Compose templates.
- Prefer the `postgresql` pattern when the Dockerfile needs to be dynamically generated with optional features.
- Prefer the `traefik` pattern when configuring an edge router, reverse proxy, or load balancer.
- Always keep non-sensitive defaults in `public.env`.
- Keep passwords and secrets in `.env` or as runtime environment variables.
- Avoid substituting sensitive secret placeholders in generated compose files.
- Use `--env-file public.env` and `--env-file .env` consistently when running containers.
- Keep `run.sh` as the single entry point for starting the service.
- When a service's Docker image supports `/docker-entrypoint-initdb.d/`, prefer baking init scripts into the image over running manual initialization.

## Adding a new technology

1. Create a new directory named after the service.
2. Add `run.sh` and `public.env`.
3. If the service uses Docker Compose templates, add `docker-compose.yml.tpl`.
4. If first-run setup is needed, add `init.sh` and an init marker file.
5. If custom image build is required, add `Dockerfile`.
6. Use `public.env` for defaults, `.env` for secrets.
7. Follow `run.sh` conventions: source `../run-preprocess.tpl.sh`, support `--force`, support `--persist`.

### Adding a new reverse proxy or load balancer

When adding a new edge router, reverse proxy, or load balancer (e.g. Traefik, Nginx, Caddy, HAProxy, Envoy):

1. **Shared Network**: Ensure the container attaches to `${NETWORK_NAME}` (e.g. `fznetwork`) so it can route traffic to backend containers in the `fzdocker` stack.
2. **Ingress Port Binding**: Bind external host ports (e.g. `80`, `443`, and management/dashboard ports) via variables defined in `public.env` (`PORT_MAPPING`, `PORT_MAPPING_SECURE`, etc.).
3. **Dynamic Route Configuration**:
   - Provide a template/default config folder (`config/` or `conf.d/`).
   - In `run.sh`, check if dynamic configuration directories exist, and copy default starter templates (e.g. `commons.yml`, service `.example.yml` files) on initial setup.
4. **SSL/TLS Certificates**: Create and mount a local certificates directory (e.g. `./local/certs`) into the container's certificate store path.
5. **Docker Provider & Container Discovery**:
   - If using auto-discovery via Docker container labels (like Traefik), mount `/var/run/docker.sock:/var/run/docker.sock`.
   - Set container auto-exposure to false by default (e.g. `--providers.docker.exposedbydefault=false`) so services are explicitly opt-in.
6. **Management Helper Scripts**: Optionally provide an `edit.sh` or helper script to streamline editing dynamic route and SSL configuration files.

## Query guidance for the agent

If asked about a service:
- Identify whether it is compose-template, docker-run, dynamic-dockerfile, or static-compose.
- Check `run.sh`, `init.sh`, `docker-compose.yml.tpl`, `Dockerfile.tpl`, and `public.env`.
- For compose-template services, inspect `docker-compose.yml.tpl` and `run.sh` envsubst logic.
- For dynamic-dockerfile services, inspect `Dockerfile.tpl`, `include/` directories, and `init.sh` envsubst logic.
- For init services, inspect `init.sh` and local data creation.
- For secrets handling, prefer `.env` or runtime environment over substitution.

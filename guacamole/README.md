# Apache Guacamole

Remote desktop gateway (RDP, VNC, SSH, etc.) using the official Guacamole Docker images.

## Usage

```bash
cd guacamole
./run.sh              # foreground
./run.sh --persist    # detached with restart policy
./run.sh --force      # recreate containers
```

First run generates the PostgreSQL schema at `local/init/initdb.sql` and marks `local/.initialized`. PostgreSQL applies that script only on a fresh data directory (`local/postgres-data`).

Open `http://localhost:8080/guacamole/` (or your `PORT_MAPPING`). Default login after a new database: **guacadmin** / **guacadmin** — change this immediately in Settings.

## Re-initialize

```bash
rm -rf local/postgres-data local/init local/.initialized
./run.sh
```

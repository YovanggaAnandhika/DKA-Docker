# Release Notes - `yovanggaanandhika/postgresql:17.0`

Release notes for the PostgreSQL 17.0 Docker image (`yovanggaanandhika/postgresql`) maintained by **DKA Research Center Organization**.

---

## 🚀 Key Highlights & Changes

### 1. Auto Maintenance & Optimizer System
* **Automatic Database Optimizer (`maintenance` script)**:
  * Automatically handles `VACUUM (VERBOSE, ANALYZE)` and `ANALYZE` tasks for database housekeeping.
  * **Smart Reindexing Mode**: Automatically calculates if index rebuilding (`REINDEX DATABASE`) is needed based on:
    * Dead tuple ratios (exceeding `DKA_MAINTENANCE_REINDEX_DEAD_RATIO_THRESHOLD` or `DKA_MAINTENANCE_REINDEX_MIN_DEAD_TUPLES`).
    * Unused/large index scans (`DKA_MAINTENANCE_REINDEX_INDEX_SCAN_THRESHOLD` and `DKA_MAINTENANCE_REINDEX_INDEX_SIZE_THRESHOLD`).
  * Support for `always` or `smart` reindexing modes.
* **Cron Scheduling**: Runs automatically at specified cron schedules (`DKA_MAINTENANCE_CRON` or hourly/daily via `DKA_MAINTENANCE_AT` timezone-aligned execution) with log routing to `/var/log/postgresql/maintenance.log`.

### 2. Built-in `pg_partman` Extension
* Automated build and installation of Keith Fiske's popular partition management extension **`pg_partman`** directly from source.
* Easily create and manage time-series or ID-based partitions at schema level out-of-the-box.

### 3. Integrated S3/Wasabi Cloud Backup
* Automated Cron-scheduled backup options (`DKA_CRON_ENABLE`, `DKA_CRON_PRIODIC`).
* In-container backup uploading straight to Amazon S3 or Wasabi-compliant storage with fully-configurable endpoints, paths, regions, and access keys.

### 4. Alpine Base & Native Privilege Isolation
* Lightweight base image footprint based on Alpine Linux.
* Employs `su-exec` for clean privilege dropping from `root` to the `postgres` user during boot, preserving process ID 1 for proper SIGTERM handling and graceful shutdown.
* Included system tools: `cgroup-tools`, `htop`, `nano`, `dcron`, `logrotate`, `rsync`, and `ifupdown-ng`.

---

## 🛠️ Usage

### Docker Compose Example (`compose.yml`)

```yaml
services:
  postgres:
    image: yovanggaanandhika/postgresql:17.0
    container_name: dka-dev-postgres
    hostname: dka-dev-postgres
    restart: always
    environment:
      DKA_ROOT_USERNAME: postgres
      DKA_ROOT_PASSWORD: your_secure_password
      DKA_DB_NAME: test
      DKA_DB_USERNAME: app_user
      DKA_DB_PASSWORD: app_password
      DKA_DB_MAX_CONNECTION: 200

      # Cron backup configuration
      DKA_CRON_ENABLE: true
      DKA_CRON_PRIODIC: "0 3 * * *"

      # S3 / Wasabi upload configuration
      DKA_S3_UPLOAD_ENABLE: true
      DKA_S3_BUCKET: dka-backups-bucket
      DKA_S3_PATH: backups/postgres
      DKA_S3_ENDPOINT: https://s3.wasabisys.com
      DKA_S3_REGION: us-east-1
      AWS_ACCESS_KEY_ID: your_access_key
      AWS_SECRET_ACCESS_KEY: your_secret_key

      # Auto maintenance / optimizer
      DKA_MAINTENANCE_ENABLE: true
      DKA_MAINTENANCE_CRON: "0 4 * * *"
      DKA_MAINTENANCE_REINDEX_ENABLE: true
      DKA_MAINTENANCE_REINDEX_MODE: smart
      DKA_MAINTENANCE_REINDEX_DEAD_RATIO_THRESHOLD: 0.20
      DKA_MAINTENANCE_REINDEX_MIN_DEAD_TUPLES: 100000
      DKA_MAINTENANCE_REINDEX_INDEX_SCAN_THRESHOLD: 50
      DKA_MAINTENANCE_REINDEX_INDEX_SIZE_THRESHOLD: 104857600
      DKA_MAINTENANCE_VACUUM_ENABLE: true
      DKA_MAINTENANCE_ANALYZE_ENABLE: true
      DKA_MAINTENANCE_LOG: /var/log/postgresql/maintenance.log
```

### Build Commands (`Makefile`)

* **Local Development Build**:
  ```bash
  make
  ```
* **Multi-Platform Build & Push**:
  ```bash
  make push
  ```

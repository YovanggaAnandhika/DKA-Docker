# Release Notes - `yovanggaanandhika/postgresql:17.0`

Release notes for the PostgreSQL 17.0 Docker image (`yovanggaanandhika/postgresql`) maintained by **DKA Research Center Organization**.

---

## 🚀 Key Highlights & Changes

### 1. Interactive S3 Backup Restore Selection (Technical)
* **Restore Utility Enhancements**:
  * The `restore` utility has been upgraded to support restoring from both **Local Directory** (`/backup`) and **S3 / Wasabi Storage**.
  * Dynamic listing of backups directly from S3 using the AWS CLI (`aws s3 ls`) with human-readable file sizes.
  * Automatic selection, download, restore, and cleanup of the temporary dump file from `/tmp/` to optimize resource management.
  * Added fallback configuration for endpoint and region: `DKA_S3_ENDPOINT` defaults to `https://s3.ap-southeast-1.wasabisys.com` and `DKA_S3_REGION` to `ap-southeast-1`. Default `DKA_S3_PATH` is set to `/`.

### 2. Auto Maintenance & Optimizer System (Technical)
* **Automatic Database Optimizer (`maintenance` script)**:
  * Automatically handles `VACUUM (VERBOSE, ANALYZE)` and `ANALYZE` tasks for database housekeeping.
  * **Smart Reindexing Mode**: Automatically calculates if index rebuilding (`REINDEX DATABASE`) is needed based on:
    * Dead tuple ratios (exceeding `DKA_MAINTENANCE_REINDEX_DEAD_RATIO_THRESHOLD` or `DKA_MAINTENANCE_REINDEX_MIN_DEAD_TUPLES`).
    * Unused/large index scans (`DKA_MAINTENANCE_REINDEX_INDEX_SCAN_THRESHOLD` and `DKA_MAINTENANCE_REINDEX_INDEX_SIZE_THRESHOLD`).
  * Support for `always` or `smart` reindexing modes.
* **Cron Scheduling**: Runs automatically at specified cron schedules (`DKA_MAINTENANCE_CRON` or hourly/daily via `DKA_MAINTENANCE_AT` timezone-aligned execution) with log routing to `/var/log/postgresql/maintenance.log`.

### 3. Built-in `pg_partman` Extension (Technical)
* Automated build and installation of Keith Fiske's popular partition management extension **`pg_partman`** directly from source.
* Easily create and manage time-series or ID-based partitions at schema level out-of-the-box.

### 4. Integrated S3/Wasabi Cloud Backup (Technical)
* Automated Cron-scheduled backup options (`DKA_CRON_ENABLE`, `DKA_CRON_PRIODIC`).
* In-container backup uploading straight to Amazon S3 or Wasabi-compliant storage with fully-configurable endpoints, paths, regions, and access keys.

### 5. Alpine Base & Native Privilege Isolation (Technical)
* Lightweight base image footprint based on Alpine Linux.
* Employs `su-exec` for clean privilege dropping from `root` to the `postgres` user during boot, preserving process ID 1 for proper SIGTERM handling and graceful shutdown.
* Included system tools: `cgroup-tools`, `htop`, `nano`, `dcron`, `logrotate`, `rsync`, and `ifupdown-ng`.

---

## 👥 Non-Technical Release Summary
This release makes database management more reliable and automated for operational teams. 
* **Simplified Recovery**: Operators can now restore databases directly by selecting backup files stored in the cloud (S3/Wasabi) from an interactive menu inside the container, eliminating the need to manually download, transfer, or unzip backups.
* **Cost-Efficient Storage Defaults**: Default cloud backups are now routed to Wasabi's Southeast Asia region (`ap-southeast-1`) by default, offering faster transfer speeds and lower latencies for regional deployments.
* **Automated Housekeeping**: Automatically cleans up unused indexes and optimizes database tables without manual intervention, keeping your application performing fast.

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
      DKA_S3_ENDPOINT: https://s3.ap-southeast-1.wasabisys.com
      DKA_S3_REGION: ap-southeast-1
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

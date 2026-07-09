# Release Notes - `yovanggaanandhika/mariadb:full`

Release notes for the MariaDB Docker image (`yovanggaanandhika/mariadb`) maintained by **DKA Research Center Organization**.

---

## 🚀 Key Highlights & Changes

### 1. Interactive S3 Backup Restore Selection (Technical)
* **Restore Utility Enhancements**:
  * Upgraded the `restore` utility to support restoring from both **Local Directory** (`/backup`) and **S3 / Wasabi Storage**.
  * Displays dynamic S3 database dump listing with sizes and keys, downloads the selected file automatically using the AWS CLI, and deletes it upon completion to free up space.
  * Added fallback configuration for endpoint and region: `DKA_S3_ENDPOINT` defaults to `https://s3.ap-southeast-1.wasabisys.com` and `DKA_S3_REGION` to `ap-southeast-1`. Default `DKA_S3_PATH` is set to `/`.

### 2. Auto Maintenance & Check System (Technical)
* **Database Maintenance Optimizer (`maintenance` script)**:
  * Performs database checks, table analysis, and optimization across all MariaDB databases using the `mariadbcheck` utility:
    * `mariadbcheck --check`
    * `mariadbcheck --optimize`
    * `mariadbcheck --analyze`
  * Defragments database file structures and updates optimization statistics.
* **Cron Scheduling**: Automatically schedules optimization routines at night via crontab based on environment settings (`DKA_MAINTENANCE_ENABLE`, `DKA_MAINTENANCE_CRON`, `DKA_MAINTENANCE_LOG`).

### 3. Integrated S3/Wasabi Cloud Backup (Technical)
* Automated Cron-scheduled backup options (`DKA_CRON_ENABLE`, `DKA_CRON_PRIODIC`).
* In-container backup uploading straight to Amazon S3 or Wasabi-compliant storage with fully-configurable endpoints, paths, regions, and access keys.

### 4. Alpine Base & Native Privilege Isolation (Technical)
* Lightweight base image footprint based on Alpine Linux.
* Employs `su-exec` for clean privilege dropping from `root` to the `mysql` user during boot, preserving process ID 1 for proper SIGTERM handling and graceful shutdown.
* Included system tools: `cgroup-tools`, `htop`, `nano`, `dcron`, `logrotate`, `rsync`, and `ifupdown-ng`.

---

## 👥 Non-Technical Release Summary
This release implements automated database tuning and secure cloud backup options to provide high availability and zero-touch operations for MariaDB servers.
* **Simple Database Restoration**: Operators can now recover databases using an interactive console menu directly inside the container that lists and pulls dumps from S3 / Wasabi.
* **Automatic Database Tuning**: Cleans up deleted records, defragments tables, and updates query planner statistics regularly without database downtime.
* **High-Speed Cloud Storage Default**: Configured to connect to Wasabi's Singapore/Asia Southeast region (`ap-southeast-1`) by default for minimized cloud transfer costs and maximum backup upload speed.

---

## 🛠️ Usage

### Docker Compose Example (`compose.yml`)

```yaml
services:
  mariadb:
    image: yovanggaanandhika/mariadb:full
    container_name: dka-database-mariadb
    hostname: dka-database-mariadb
    restart: always
    environment:
      DKA_ROOT_PASSWORD: your_secure_password
      DKA_DB_NAME: dka
      DKA_DB_USERNAME: dka
      DKA_DB_PASSWORD: your_db_password
      DKA_CRON_ENABLE: true
      DKA_CRON_PRIODIC: "0 3 * * *"
      
      # S3 / Wasabi upload configuration
      DKA_S3_UPLOAD_ENABLE: true
      DKA_S3_BUCKET: dka-backups-bucket
      DKA_S3_PATH: backups/mariadb
      DKA_S3_ENDPOINT: https://s3.ap-southeast-1.wasabisys.com
      DKA_S3_REGION: ap-southeast-1
      AWS_ACCESS_KEY_ID: your_access_key
      AWS_SECRET_ACCESS_KEY: your_secret_key
      
      # Auto maintenance
      DKA_MAINTENANCE_ENABLE: true
      DKA_MAINTENANCE_CRON: "0 4 * * *"
      DKA_MAINTENANCE_LOG: /var/log/mysql/maintenance.log
    ports:
      - "3306:3306"
    volumes:
      - data:/var/lib/mysql
      - backup:/backup
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

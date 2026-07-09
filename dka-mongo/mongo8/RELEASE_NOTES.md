# Release Notes - `yovanggaanandhika/mongo:13-slim-mongo-8.0.5`

Release notes for the MongoDB 8.0.5 Docker image (`yovanggaanandhika/mongo`) maintained by **DKA Research Center Organization**.

---

## 🚀 Key Highlights & Changes

### 1. Interactive S3 Backup Restore Selection (Technical)
* **Restore Utility Enhancements**:
  * Upgraded the `restore` utility to support restoring from both **Local Directory** (`/backup`) and **S3 / Wasabi Storage**.
  * Displays dynamic S3 database dump listing with sizes and keys, downloads the selected file automatically using the AWS CLI, and deletes it upon completion to free up space.
  * Added fallback configuration for endpoint and region: `DKA_S3_ENDPOINT` defaults to `https://s3.ap-southeast-1.wasabisys.com` and `DKA_S3_REGION` to `ap-southeast-1`. Default `DKA_S3_PATH` is set to `/`.

### 2. Auto Maintenance & Compaction System (Technical)
* **Database Compaction Optimizer (`maintenance` script)**:
  * Loops through all non-system user databases and executes collection compaction (`runCommand({ compact: collection })`).
  * Rebuilds indexes and frees up disk space from deleted/updated documents.
* **Cron Scheduling**: Automatically coordinates maintenance tasks based on environmental parameters (`DKA_MAINTENANCE_ENABLE`, `DKA_MAINTENANCE_CRON`, `DKA_MAINTENANCE_LOG`).

### 3. OS & Base Image Upgrade (Technical)
* **Base OS**: Upgraded from `debian:12-slim` to **`debian:13-slim`** (Trixie).
* Reduced image footprint while providing up-to-date core libraries and system utilities.

### 4. Multi-Platform Support (AMD64 & ARM64) (Technical)
* The build configuration (`Makefile`) now uses `docker buildx` to build and push multi-architecture manifests:
  * `linux/amd64`
  * `linux/arm64`
* **Tailored Package Repository Resolution**:
  * For **ARM64** platforms, the installer routes to MongoDB's Ubuntu Jammy (`8.0 multiverse`) repository.
  * For **AMD64** platforms, the installer routes to MongoDB's Debian Bookworm (`8.0 main`) repository.

### 5. Advanced Healthcheck Script (Technical)
* Integrated native Docker HEALTHCHECK utilizing `/usr/local/bin/healthcheck.sh`:
  * **Liveness Check**: Runs `db.adminCommand('ping')` to ensure the database engine is responding.
  * **Readiness Check**: Inspects master/secondary status to ensure the node is ready for connections and not stuck in initialization or recovery.
  * Employs authentication via `DKA_MONGO_USERNAME` and `DKA_MONGO_PASSWORD` to ensure secure health checking.

---

## 👥 Non-Technical Release Summary
This release implements automated maintenance and cloud backup integration to ensure minimal operational overhead for running MongoDB in production.
* **Streamlined Disaster Recovery**: Operators can view and restore MongoDB database snapshots directly from S3 or Wasabi object storage via a command-line menu inside the container.
* **Database Auto-Optimization**: Periodically compacts MongoDB collections to defragment storage, reduce storage usage, and restore indexing efficiency.
* **Optimized Local Endpoint**: Configured to target Wasabi Southeast Asia region (`ap-southeast-1`) by default for reduced network cost and latency in regional deployments.

---

## 🛠️ Usage

### Docker Compose Example (`compose.yml`)

```yaml
services:
  mongo:
    image: yovanggaanandhika/mongo:13-slim-mongo-8.0.5
    container_name: dka-dev-mongo
    hostname: dka-dev-mongo
    restart: always
    environment:
      DKA_MONGO_PASSWORD: "your_secure_password"
      DKA_REPL_ENABLED: "true"
      DKA_CRON_ENABLE: true
      DKA_CRON_PRIODIC: "0 3 * * *"

      # S3 / Wasabi upload configuration
      DKA_S3_UPLOAD_ENABLE: true
      DKA_S3_BUCKET: dka-backups-bucket
      DKA_S3_PATH: backups/mongodb
      DKA_S3_ENDPOINT: https://s3.ap-southeast-1.wasabisys.com
      DKA_S3_REGION: ap-southeast-1
      AWS_ACCESS_KEY_ID: your_access_key
      AWS_SECRET_ACCESS_KEY: your_secret_key

      # Auto maintenance
      DKA_MAINTENANCE_ENABLE: true
      DKA_MAINTENANCE_CRON: "0 4 * * *"
      DKA_MAINTENANCE_LOG: /var/log/mongodb/maintenance.log
    ports:
      - "27017:27017"
    volumes:
      - dka-dev-mongo-data:/data/db
      - dka-dev-mongo-backup:/backup
    deploy:
      resources:
        limits:
          memory: 500M
          cpus: '1.0'
        reservations:
          memory: 250M
          cpus: '0.8'

volumes:
  dka-dev-mongo-data:
    external: true
  dka-dev-mongo-backup:
    external: true
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

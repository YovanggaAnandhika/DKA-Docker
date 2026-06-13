# Release Notes - `yovanggaanandhika/mongo:13-slim-mongo-8.0.5`

Release notes for the MongoDB 8.0.5 Docker image (`yovanggaanandhika/mongo`) maintained by **DKA Research Center Organization**.

---

## 🚀 Key Highlights & Changes

### 1. OS & Base Image Upgrade
* **Base OS**: Upgraded from `debian:12-slim` to **`debian:13-slim`** (Trixie).
* Reduced image footprint while providing up-to-date core libraries and system utilities.

### 2. Multi-Platform Support (AMD64 & ARM64)
* The build configuration (`Makefile`) now uses `docker buildx` to build and push multi-architecture manifests:
  * `linux/amd64`
  * `linux/arm64`
* **Tailored Package Repository Resolution**:
  * For **ARM64** platforms, the installer routes to MongoDB's Ubuntu Jammy (`8.0 multiverse`) repository.
  * For **AMD64** platforms, the installer routes to MongoDB's Debian Bookworm (`8.0 main`) repository.

### 3. Integrated Security & Replica Set Configuration
* Automatically generates a secure MongoDB keyfile (`/etc/mongo-keyfile` with `600` permissions owned by `mongodb:mongodb`) on build for replica set authentication.

### 4. Advanced Healthcheck Script
* Integrated native Docker HEALTHCHECK utilizing `/usr/local/bin/healthcheck.sh`:
  * **Liveness Check**: Runs `db.adminCommand('ping')` to ensure the database engine is responding.
  * **Readiness Check**: Inspects master/secondary status to ensure the node is ready for connections and not stuck in initialization or recovery.
  * Employs authentication via `DKA_MONGO_USERNAME` and `DKA_MONGO_PASSWORD` to ensure secure health checking.

### 5. Pre-configured Services
* **Default Timezone**: Set to `Asia/Makassar` (`TZ=Asia/Makassar`).
* **System Utilities**: Included `cron`, `logrotate`, `procps`, `nano`, `bash`, and `curl` directly out-of-the-box.
* **Cron & Logrotate**: Integrated pre-configured Cron directories and Logrotate scripts for database maintenance.

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

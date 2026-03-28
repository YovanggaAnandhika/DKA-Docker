# === 1. BASE IMAGE ===
# Menggunakan image Alpine Linux resmi sebagai sistem dasar yang sangat ringan ("feather-weight").
FROM alpine:3.21

# === 2. METADATA & REPOSITORI ===
# Kumpulan tag label "OpenContainers" standar industri untuk memberi deskripsi terkait image, lisensi, author, dll.
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
LABEL org.opencontainers.image.title="Base Postgresql Alpine Image"
LABEL org.opencontainers.image.description="DKA Alpine Base Postgresql Image"
LABEL org.opencontainers.image.version="0.0.1"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/yovanggaanandhika/postgresql"
LABEL org.opencontainers.image.source="https://hub.docker.com/r/yovanggaanandhika/postgresql"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Yovangga Anandhika <dka.tech.dev@gmail.com>"
LABEL org.opencontainers.image.vendor="DKA Research Center Organization"

# === 3. INSTALASI PAKET INTI DAN ALAT SISTEM ===
# Mengunduh dan menginstal komponen inti untuk menunjang PostgreSQL:
# - cgroup-tools, htop, nano, bash, rsync: Standar Linux utilities untuk memonitoring, sinkronisasi file, & editing.
# - tzdata: Untuk integrasi zona waktu lokal/Server.
# - dcron, logrotate: Engine tugas berkala (cron) dan rotasi limit log (logrotate).
# - dhcpcd: DHCP client (Dukungan alokasi IP dinamis otomatis jika langsung dijalankan di jaringan Proxmox LXC).
# - su-exec: Utilitas WAJIB untuk "menurunkan hak akses" (privilege drop) dengan aman dari 'root' ke 'postgres' saat container booting, tanpa memecah PID 1 untuk Graceful Shutdown.
# - postgresql, postgis, postgresql-contrib, postgresql-client: Database utama, library GIS, plugin kontrib, dan client tool psql.
# Terakhir menghapus (/var/cache/apk/*) untuk memastikan ukuran image akhir seminimum mungkin.
RUN apk update && apk add --no-cache cgroup-tools tzdata htop nano dcron logrotate bash rsync dhcpcd su-exec \
    postgresql postgis postgresql-contrib postgresql-client && rm -rf /var/cache/apk/*

# === 4. KONFIGURASI LINGKUNGAN / ENVIRONMENT ===
# Mengatur Zona Waktu bawaan ke Waktu Indonesia Tengah
ENV TZ=Asia/Makassar

# === 5. PERSIAPAN INFRASTRUKTUR SISTEM ===
# Menyalin setup batas putaran log agar file log database tidak kepenuhan
COPY config/logrotate.d /etc/logrotate.d/

# Membentuk struktur fondasi direktori data, rekaman log, socket jaringan (.sock), hingga rute backup. 
# Secara langsung memberikan Hak Kepemilikan (Ownership) penuh kepada user "postgres" ("chown postgres:postgres").
RUN mkdir -p /var/log/postgresql && chown postgres:postgres /var/log/postgresql &&  \
    mkdir /backup && chown postgres:postgres /backup && chmod -R 755 /backup && \
    mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql && \
    mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql

# Menyalin naskah dan konfigurasi tugas berkala (Crontab job) dan memberinya akses pelaksana
COPY config/cron.d /usr/cron.d/
RUN chmod +x /usr/cron.d/*

# Menyalin alat bantu skrip buatan dari branch (Jika ada)
COPY config/bin /usr/local/bin/

# Menyalin Skrip Tembok Pintu Masuk Container (Entrypoint) beserta Skrip Pemantau Sehat (Healthcheck)
COPY config/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY config/healthcheck.sh /usr/local/bin/healthcheck.sh
# Memberi akses Eksekusi Skrip agar OS bisa menjalankan Bash-nya
RUN chmod +x /usr/local/bin/*
# Pastikan cron dimiliki oleh perizinan sistem Postgres
RUN chown -R postgres:postgres /etc/cron.d/

# === 6. INISIALISASI STRUKTUR SQL BARU (INITIAL RUN) ===
# Menyalin kumpulan file (.sql / .tmpl) bawaan yang tugasnya otomatis dieksekusi SECARA SEKALI SAJA jika database masih kosongan pertama kali (First Run).
COPY config/docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
RUN chown postgres:postgres /docker-entrypoint-initdb.d

# Menugaskan Engine Docker / Proxmox untuk mengirim sinyal cek nyawa setiap 10 detik memastikan database tidak stuck.
HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=15s \
  CMD /usr/local/bin/healthcheck.sh

# === 7. SQL OTOMASI (AUTO RELOAD) ===
# Direktori khusus file kueri ".sql" tugas berulang yang selalu ingin ditambahkan di fase re-run (Bila skenario pengguna mensyaratkannya).
COPY config/docker-entrypoint.d /docker-entrypoint.d
RUN chown postgres:postgres /docker-entrypoint.d

# === 8. DEFAULT USER ===
# (Baris 'USER postgres' disengaja DIHAPUS agar Image otomatis terbuka/boot sebagai 'user root'. 
# Tujuannya adalah memastikan fitur Pembersihan Folder & Socket yang Kusam teratasi secara paksa 
# tanpa pesan "Permission Denied" jika dipasang pada Cloud/Kubernetes Storage yang persisten. 
# "su-exec" akan dipakai di dalam entrypoint.sh untuk secara dramatis memberikan/menyerahkan kendali ke proses postgres)

# === 9. PENYELESAIAN JARINGAN (PORT) & ENTRYPOINT ===
# Menargetkan keterbukaan port default PostgreSQL di host (TCP 5432)
EXPOSE 5432

# Skrip peluncuran eksklusif ("Pid 1 Bootloader") yang akan menjadi komando utama saat container start.
ENTRYPOINT ["entrypoint.sh"]
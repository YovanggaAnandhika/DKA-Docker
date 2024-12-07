# Gunakan image FreeRADIUS resmi sebagai base image
FROM freeradius/freeradius-server

# Salin seluruh isi dari direktori lokal 'etc/' ke dalam direktori '/etc' di dalam container
# Pastikan Anda memiliki folder 'etc/' di direktori yang sama dengan Dockerfile
COPY etc/ /etc/

# Ekspos port RADIUS Authentication (1812) dan Accounting (1813)
EXPOSE 1812 1813
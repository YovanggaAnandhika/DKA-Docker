# Informasi Rilis - MongoDB 8.0 (`yovanggaanandhika/mongo:13-slim-mongo-8.0.5`)

Dokumen ini berisi penjelasan sederhana mengenai fitur-fitur baru pada pembaruan database MongoDB 8.0.

---

## 🌟 Apa yang Baru & Manfaatnya untuk Anda?

### 1. Mendukung Komputer & Server Tipe Baru (ARM64)
* **Manfaat**: Database kini dapat berjalan dengan lancar di server modern hemat energi (seperti AWS Graviton) maupun laptop Apple Macbook (M1/M2/M3).
* **Kenapa ini penting?**: Memudahkan tim developer bekerja di laptop mereka dan menghemat biaya sewa server cloud hingga 40%.

### 2. Sistem Pemantau Kesehatan Otomatis (Healthcheck)
* **Manfaat**: Database kini dilengkapi dengan "dokter internal" yang otomatis memeriksa apakah sistem berjalan normal dan siap menerima data.
* **Kenapa ini penting?**: Jika terjadi kendala pada database, sistem akan langsung mendeteksinya secara instan dan dapat melakukan perbaikan otomatis (restart) sebelum pengguna aplikasi menyadarinya.

### 3. Keamanan yang Lebih Ketat secara Otomatis
* **Manfaat**: Kunci pengaman untuk menghubungkan beberapa server database kini dibuat secara otomatis dengan standar keamanan tinggi.
* **Kenapa ini penting?**: Menghindari risiko kebocoran data akibat kelalaian konfigurasi keamanan manual.

### 4. Performa Lebih Cepat & Sistem Lebih Ringan
* **Manfaat**: Menggunakan sistem operasi dasar (Debian 13) yang lebih baru, bersih, dan dioptimalkan.
* **Kenapa ini penting?**: Menghemat kapasitas penyimpanan harddisk server dan membuat loading awal database menjadi lebih instan.

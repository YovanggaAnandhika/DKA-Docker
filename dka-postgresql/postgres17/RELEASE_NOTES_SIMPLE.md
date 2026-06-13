# Informasi Rilis - PostgreSQL 17 (`yovanggaanandhika/postgresql:17.0`)

Dokumen ini berisi penjelasan sederhana mengenai fitur-fitur baru pada pembaruan database PostgreSQL 17.0.

---

## 🌟 Apa yang Baru & Manfaatnya untuk Anda?

### 1. Pembersihan & Perawatan Otomatis (Auto-Maintenance)
* **Manfaat**: Database kini secara rutin membersihkan "sampah data" (bekas data yang telah dihapus atau diubah) secara otomatis pada jam-jam sepi.
* **Kenapa ini penting?**: Mencegah database menjadi lambat seiring berjalannya waktu dan memastikan pencarian data tetap cepat tanpa perlu perawatan manual dari admin.

### 2. Pengarsipan Data Besar yang Pintar (`pg_partman`)
* **Manfaat**: Database sekarang memiliki kemampuan bawaan untuk membagi data yang sangat besar (seperti transaksi harian) menjadi laci-laci kecil berdasarkan waktu/kategori.
* **Kenapa ini penting?**: Membaca laporan bulanan atau mencari data transaksi lama menjadi jauh lebih cepat karena sistem tidak perlu menggeledah seluruh database.

### 3. Backup Cadangan Otomatis ke Cloud (S3/Wasabi)
* **Manfaat**: Salinan cadangan (backup) database kini bisa otomatis diunggah langsung ke penyimpanan cloud yang aman di luar server utama.
* **Kenapa ini penting?**: Menjamin keamanan data bisnis Anda. Jika server utama rusak atau terbakar, data Anda masih utuh dan bisa dipulihkan dalam hitungan menit dari cloud.

### 4. Hemat Penggunaan RAM & Memori Server
* **Manfaat**: Menggunakan sistem operasi dasar (Alpine Linux) yang sangat minimalis dan efisien.
* **Kenapa ini penting?**: Meminimalkan biaya sewa server karena database tidak memerlukan spesifikasi RAM yang besar untuk dapat bekerja dengan optimal.

# Ragum Stok — Panduan Pemasangan & Pemakaian

Aplikasi manajemen stok gudang dengan scan barcode. Berjalan di HP dan laptop, data tersinkron lewat cloud.

**Isi paket:**

| File | Fungsi |
|---|---|
| `index.html` | Aplikasi utama |
| `schema.sql` | Struktur database (dijalankan sekali di Supabase) |
| `manifest.json` | Agar bisa di-install ke layar HP |
| `sw.js` | Service worker, agar tampilan tetap terbuka saat sinyal putus |
| `icon-192.png`, `icon-512.png`, `favicon.ico` | Ikon aplikasi (identitas Ragum) |

Total biaya: **Rp 0**. Supabase gratis sampai 500 MB database, Netlify/Vercel gratis untuk hosting.

Bagian dari ekosistem **Ragum** (Ramah · Guna · Mandiri), sejalur dengan Ragum Finance.

---

## Ringkasan Cepat

Kalau kamu sudah terbiasa, ini intinya saja:

| # | Langkah | Waktu |
|---|---|---|
| 1 | Buat proyek Supabase, region **Singapore** | 5 menit |
| 2 | Jalankan `schema.sql` di SQL Editor | 2 menit |
| 3 | Salin Project URL + anon key ke 2 baris di `index.html` | 3 menit |
| 4 | Seret folder ke **app.netlify.com/drop** | 5 menit |
| 5 | Buka di HP → Add to Home screen | 2 menit |

**Jangan lewati langkah 4.** Kamera browser hanya berfungsi lewat HTTPS. Kalau file dibuka langsung dari HP, tombol scan tidak akan jalan.

**Jangan unggah** `schema.sql` dan `PANDUAN.md` ke hosting — keduanya hanya untuk kamu.

Penjelasan lengkap tiap langkah ada di bawah.

---

## BAGIAN 1 — Menyiapkan Database (10 menit)

### 1.1 Buat akun Supabase

1. Buka **supabase.com**, tekan **Start your project**, daftar dengan akun GitHub atau email.
2. Tekan **New project**.
3. Isi:
   - **Name**: `ragum-stok`
   - **Database Password**: buat sandi yang kuat, **simpan baik-baik** (dipakai kalau nanti butuh akses langsung ke database)
   - **Region**: pilih **Southeast Asia (Singapore)** — paling dekat dengan Indonesia, jadi aplikasi terasa cepat
4. Tekan **Create new project**. Tunggu sekitar 2 menit sampai statusnya hijau.

### 1.2 Jalankan struktur database

1. Di menu kiri, tekan ikon **SQL Editor**.
2. Tekan **New query**.
3. Buka file `schema.sql`, **salin seluruh isinya**, tempel ke editor.
4. Tekan **Run** (atau Ctrl+Enter).
5. Kalau muncul tulisan **Success. No rows returned** — berhasil.

Untuk memastikan, buka menu **Table Editor**. Harus ada 4 tabel: `warehouses`, `products`, `transactions`, `transaction_items`.

### 1.3 Matikan verifikasi email (opsional, agar pendaftaran instan)

Kalau ini hanya untuk dipakai sendiri, verifikasi email cuma merepotkan:

1. Menu **Authentication** → **Sign In / Providers** → **Email**.
2. Matikan **Confirm email**.
3. Tekan **Save**.

Kalau nanti dijual ke orang lain, **nyalakan kembali** — verifikasi email mencegah pendaftaran akun palsu.

### 1.4 Ambil kunci koneksi

1. Menu **Settings** (ikon gerigi) → **API Keys**.
2. Catat dua nilai ini:
   - **Project URL** — bentuknya `https://abcdefgh.supabase.co`
   - **anon public** — teks panjang diawali `eyJ...`

> Kunci `anon` memang aman ditaruh di file HTML. Yang melindungi data Anda adalah Row Level Security yang sudah dipasang oleh `schema.sql`, bukan kerahasiaan kunci ini.
>
> Yang **tidak boleh** dibagikan adalah kunci `service_role`. Jangan pernah menaruhnya di file HTML.

### 1.5 Masukkan kunci ke aplikasi

Buka `index.html` dengan Notepad atau editor teks apa pun. Cari dua baris ini di dekat awal blok `<script>`:

```js
const SUPABASE_URL  = 'https://XXXXXXXX.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOi...GANTI_DENGAN_ANON_KEY_ANDA';
```

Ganti keduanya dengan nilai dari langkah 1.4, lalu simpan.

---

## BAGIAN 2 — Menaikkan ke Internet (5 menit)

Langkah ini **wajib**. Kamera hanya boleh diakses browser lewat HTTPS. Kalau file dibuka langsung dari HP (`file://`), scan barcode tidak akan jalan.

### Cara termudah: Netlify Drop

1. Masukkan semua file (`index.html`, `manifest.json`, `sw.js`, `icon-192.png`, `icon-512.png`) ke dalam satu folder.
2. Buka **app.netlify.com/drop**.
3. Seret folder itu ke halaman tersebut.
4. Selesai. Anda langsung dapat alamat seperti `https://nama-acak.netlify.app`.

Untuk mengganti nama alamat: **Site configuration** → **Change site name**.

### Cara alternatif: Vercel (lebih rapi untuk jangka panjang)

1. Buat repository baru di GitHub, unggah semua file ke sana.
2. Buka **vercel.com**, tekan **Add New** → **Project**.
3. Pilih repository tadi, tekan **Deploy**.

Keuntungannya: setiap kali Anda perbaiki file di GitHub, situs otomatis diperbarui.

> `schema.sql` dan `PANDUAN.md` tidak perlu diunggah — keduanya hanya untuk Anda.

---

## BAGIAN 3 — Memasang di HP

1. Buka alamat situs tadi lewat **Chrome** (Android) atau **Safari** (iPhone).
2. Android: menu titik tiga → **Add to Home screen** / **Install app**.
   iPhone: tombol Share → **Add to Home Screen**.
3. Ikon Ragum Stok muncul di layar HP. Buka dari situ — tampil layar penuh seperti aplikasi biasa.

Saat pertama kali menekan **Nyalakan Kamera**, browser akan minta izin. Tekan **Izinkan**. Kalau tidak sengaja ditolak: ikon gembok di address bar → Izin situs → Kamera → Izinkan.

---

## BAGIAN 4 — Cara Memakai

### Langkah pertama

1. Buka aplikasi, tekan **Daftar di sini**, isi email dan kata sandi (minimal 6 karakter).
2. Gudang bernama "Gudang Utama" otomatis dibuatkan untuk Anda.
3. Masuk ke tab **Atur** → **Muat Data Contoh** untuk mencoba dulu dengan 8 barang.
4. Kalau sudah paham alurnya, hapus barang contoh satu per satu, lalu isi barang asli Anda.

### Mendaftarkan barang

Tekan tab **Barang** (ikon +) di bawah.

| Isian | Penjelasan |
|---|---|
| **Kode / Barcode** | Ketik angka barcode di kemasan. Untuk barang tanpa barcode, tekan **Auto** — sistem membuatkan kode, lalu tulis/tempel kode itu di kardusnya. |
| **Nama Barang** | Tulis lengkap dengan ukuran, contoh "Minyak Goreng 2L" bukan cuma "Minyak". |
| **Satuan** | Satuan terkecil yang Anda catat: pcs, dus, kg, roll, sak. |
| **Stok Awal** | Jumlah fisik saat ini. Hitung dulu sebelum mengisi. |
| **Stok Minimum** | Ambang peringatan. Isi sesuai pemakaian selama menunggu kiriman supplier. Contoh: kalau sehari habis 2 dus dan supplier datang 5 hari, isi 10. |
| **Harga Satuan** | Untuk menghitung nilai persediaan. Boleh 0 kalau tidak perlu. |

Cara cepat mengisi banyak barang: buka situsnya di **laptop**, ngetik jauh lebih cepat pakai keyboard.

### Mencatat barang keluar (mode kasir)

1. Tekan tombol tengah berbentuk bingkai scan.
2. Pastikan mode **Barang Keluar** (oranye) yang aktif.
3. Tekan **Nyalakan Kamera**, arahkan ke barcode.
4. Setiap scan berhasil: terdengar *beep* dan HP bergetar, barang masuk keranjang.
   Scan barang yang sama tiga kali = jumlah 3.
5. Barang tanpa barcode? Tekan **Input Manual**, pilih dari daftar, isi jumlahnya.
6. Perlu ubah jumlah? Pakai tombol − / + atau ketik langsung di kotak angkanya.
7. Tekan **Simpan Barang Keluar**.

### Mencatat barang masuk

Sama persis, hanya pilih mode **Barang Masuk** (hijau) sebelum mulai scan.

### Pengaman yang sudah terpasang

- Jumlah keluar melebihi stok → tombol simpan terkunci, tulisannya berubah jadi "Jumlah melebihi stok". Pemeriksaan ini juga diulang di server, jadi tidak bisa ditembus.
- Scan barcode yang belum terdaftar → notifikasi merah, tidak masuk keranjang.
- Barcode sama yang terbaca dua kali dalam 1,6 detik dihitung sekali saja.
- Kalau internet putus di tengah penyimpanan, transaksi dibatalkan seluruhnya. Tidak akan ada transaksi setengah jadi.

### Membaca daftar stok

- **Garis oranye di kiri** = stok sudah menyentuh batas minimum, saatnya pesan lagi.
- **Baris pudar** = stok habis.
- Barang bermasalah otomatis naik ke urutan atas.
- Angka **Stok Menipis** di header adalah jumlah barang yang perlu perhatian Anda hari ini.

### Laporan dan ekspor

Tab **Atur** menampilkan:

- Nilai persediaan (total stok × harga)
- Jumlah jenis barang
- Berapa barang yang perlu restock
- Jumlah dan nilai transaksi keluar 30 hari terakhir

**Ekspor CSV** menghasilkan file yang bisa langsung dibuka di Excel, sudah rapi dengan huruf Indonesia.

---

## BAGIAN 5 — Hal Penting yang Perlu Dipahami

### Stok dihitung, bukan disimpan

Angka stok tidak pernah disimpan sebagai satu angka yang ditimpa berulang kali. Setiap perubahan dicatat sebagai baris transaksi, lalu stok dihitung ulang dari seluruh riwayat.

Kenapa ini penting: kalau suatu hari angkanya terasa aneh, Anda bisa menelusuri riwayatnya dan menemukan penyebabnya. Sistem yang menimpa angka langsung tidak bisa melakukan itu — begitu salah, tidak ada jejak.

Ini juga alasan kenapa **stok tidak bisa diedit langsung** di form Ubah Barang. Untuk mengoreksi selisih hasil hitung fisik, catat sebagai transaksi masuk atau keluar.

### Keamanan data

Row Level Security memastikan setiap akun hanya bisa membaca dan menulis gudangnya sendiri. Aturan ini berlaku di tingkat database, bukan di tampilan — jadi tetap aman meskipun ada yang mengutak-atik kode di browser.

### Batas paket gratis

Supabase gratis mencakup 500 MB database. Sebagai gambaran, itu cukup untuk ratusan ribu baris transaksi — bertahun-tahun untuk satu toko.

Satu catatan: proyek Supabase gratis akan **dijeda otomatis kalau tidak dipakai selama 7 hari**. Membangunkannya cukup dengan membuka dashboard dan menekan Restore. Data tidak hilang. Kalau aplikasi dipakai harian, ini tidak akan pernah terjadi.

---

## BAGIAN 6 — Kalau Ada Masalah

| Gejala | Penyebab & Solusi |
|---|---|
| Kamera tidak menyala | Situs harus dibuka lewat **https://**. Kalau alamatnya masih `file://`, selesaikan Bagian 2 dulu. |
| Izin kamera terlanjur ditolak | Ikon gembok di address bar → Izin situs → Kamera → Izinkan → muat ulang halaman. |
| Barcode tidak terbaca | Tambah cahaya, jaga jarak sekitar 15–20 cm, pastikan barcode datar tidak melengkung. Kalau tetap gagal, pakai **Input Manual**. |
| "Email atau kata sandi salah" | Cek huruf besar-kecil. Kalau lupa: Supabase → Authentication → Users → hapus akun, lalu daftar ulang. |
| "Gagal memuat gudang" | `schema.sql` belum dijalankan, atau kunci di langkah 1.5 salah tempel. |
| Halaman kosong / putih | Buka Console browser (F12) untuk melihat pesan error. Biasanya kunci Supabase salah. |
| Data tidak muncul di HP padahal sudah diisi di laptop | Pastikan login dengan **akun yang sama**. Tarik layar ke bawah untuk memuat ulang. |
| "Kode barang ini sudah dipakai" | SKU harus unik. Tekan **Auto** untuk membuat kode baru. |
| Aplikasi terasa lambat setelah lama tidak dipakai | Proyek Supabase sedang dijeda. Buka dashboard, tekan Restore. |

---

## BAGIAN 7 — Rencana Pengembangan Berbayar

Struktur database yang sudah ada sekarang sanggup menopang semua fitur di bawah tanpa perlu dirombak.

### Fitur yang paling layak dijual

Dari pengalaman produk sejenis, yang membuat orang mau membayar bukan fitur scan-nya — itu sudah dianggap standar. Yang dibayar adalah:

1. **Laporan** — kartu stok per barang, nilai persediaan bulanan, barang paling laku. View `v_top_moving` di `schema.sql` sudah menyiapkan dasarnya.
2. **Multi-pengguna** — pemilik toko ingin karyawan bisa mencatat tanpa bisa mengubah harga atau menghapus barang.
3. **Cetak label barcode** — untuk barang tanpa barcode pabrik. Pakai pustaka `bwip-js`, cetak ke printer thermal.

### Usulan tingkatan harga

| Paket | Harga | Batas |
|---|---|---|
| Gratis | Rp 0 | 50 jenis barang, 1 pengguna, riwayat 30 hari |
| Pro | Rp 49.000/bulan | Tanpa batas, 3 pengguna, laporan lengkap, cetak label |
| Bisnis | Rp 149.000/bulan | Multi-gudang, tanpa batas pengguna, ekspor terjadwal |

### Cara memasang batas paket

Tambahkan tabel langganan, lalu tegakkan batasnya di database — bukan di tampilan:

```sql
create table subscriptions (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  plan       text not null default 'free' check (plan in ('free','pro','business')),
  expires_at timestamptz
);

-- Tolak penambahan barang ke-51 untuk pengguna paket gratis
create or replace function check_product_limit()
returns trigger language plpgsql as $$
declare v_plan text; v_count int;
begin
  select coalesce(s.plan,'free') into v_plan
    from warehouses w
    left join subscriptions s on s.user_id = w.owner_id
   where w.id = new.warehouse_id;

  if v_plan = 'free' then
    select count(*) into v_count from products where warehouse_id = new.warehouse_id;
    if v_count >= 50 then
      raise exception 'Paket gratis dibatasi 50 jenis barang. Tingkatkan ke Pro untuk tanpa batas.';
    end if;
  end if;
  return new;
end $$;

create trigger trg_product_limit
  before insert on products
  for each row execute function check_product_limit();
```

Menegakkan batas di database membuatnya tidak bisa ditembus dari browser.

Untuk pembayaran, sambungkan webhook Xendit ke Supabase Edge Function yang memperbarui kolom `plan` dan `expires_at`.

### Urutan pengerjaan yang saya sarankan

1. Pakai sendiri dulu minimal sebulan. Masalah nyata baru muncul saat dipakai harian.
2. Tawarkan gratis ke 3–5 pemilik toko yang Anda kenal. Perhatikan di mana mereka tersendat.
3. Baru bangun fitur berbayar, berdasarkan apa yang benar-benar mereka minta — bukan tebakan.

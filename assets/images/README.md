# Assets — Standar Gambar & Diagram

Direktori ini menyimpan seluruh gambar yang dipakai dalam dokumentasi:
foto rak, diagram arsitektur, dan screenshot.

> **Terakhir Diperbarui:** 2026-08-28

---

## 1. Struktur Direktori

```
assets/images/
├── README.md          # dokumen ini
├── racks/             # foto fisik: rak, chassis, kabel, label aset
├── diagrams/          # diagram: topologi jaringan, storage, alur data
└── screenshots/       # tangkapan layar: IPMI, Proxmox, terminal, Grafana
```

| Subdirektori | Isi | Format Disarankan |
|---|---|---|
| `racks/` | Foto kamera dari perangkat fisik | `.jpg` (foto), `.png` (bila ada teks/label penting) |
| `diagrams/` | Diagram yang dibuat sendiri | `.svg` (utama), `.png` (fallback), `.drawio` (sumber) |
| `screenshots/` | Tangkapan layar antarmuka/terminal | `.png` |

---

## 2. Standar Penamaan File

### 2.1 Pola Umum

```
<subjek>-<konteks>[-<varian>].<ext>
```

Aturan:

| Aturan | Ya | Tidak |
|---|---|---|
| Huruf kecil semua | `hpc-node-01-rack.png` | `HPC-Node-01-Rack.PNG` |
| Pemisah tanda hubung | `storage-node-01-zfs.png` | `storage_node_01_zfs.png` |
| Tanpa spasi | `network-topology.png` | `network topology.png` |
| Tanpa karakter khusus | `idrac-dashboard.png` | `idrac(dashboard)#1.png` |
| Nama deskriptif | `hpc-node-01-rear-cabling.jpg` | `IMG_2847.jpg` |
| Diawali nama node bila spesifik | `hpc-node-01-dimm-layout.png` | `dimm-layout.png` |
| Tanpa tanggal, kecuali untuk seri waktu | `zpool-status.png` | `zpool-status-28agustus2026.png` |

### 2.2 Pola per Kategori

**Foto rak (`racks/`):**
```
<hostname>-rack.jpg                 → posisi node di rak
<hostname>-front.jpg                → tampak depan chassis
<hostname>-rear-cabling.jpg         → tampak belakang + kabel
<hostname>-asset-tag.jpg            → close-up label aset & serial
<nama-rak>-full.jpg                 → keseluruhan rak
<nama-rak>-front-labeled.jpg        → rak dengan label RU
```
Contoh:
```
hpc-node-01-rack.jpg
storage-node-01-front.jpg
proxmox-node-01-rear-cabling.jpg
rack-a01-full.jpg
rack-a02-front-labeled.jpg
```

**Diagram (`diagrams/`):**
```
<lingkup>-<jenis>.svg
<hostname>-<komponen>-layout.svg
```
Contoh:
```
network-topology-overview.svg
cluster-architecture.svg
dataflow-scratch-to-storage.svg
rack-elevation-a01.svg
hpc-node-01-dimm-layout.svg
storage-node-01-disk-bay-map.svg
storage-node-01-zfs-topology.svg
proxmox-node-01-network-bridge.svg
proxmox-node-01-vm-map.svg
```

**Screenshot (`screenshots/`):**
```
<hostname>-<aplikasi/perintah>.png
<hostname>-<perintah>-<kondisi>.png
mnt-<id-tiket>-<tahap>.png
```
Contoh:
```
hpc-node-01-idrac-dashboard.png
hpc-node-01-nvidia-smi.png
storage-node-01-zpool-status.png
storage-node-01-zpool-status-degraded.png
storage-node-01-capacity-trend.png
proxmox-node-01-dashboard.png
proxmox-node-01-storage.png
grafana-cluster-overview.png
slurm-sinfo-output.png
mnt-2026-005-before.png
mnt-2026-005-after.png
mnt-2026-006-resilver-done.png
```

**Untuk seri waktu (perbandingan sebelum/sesudah, tren):**
```
<subjek>-<YYYY-MM-DD>.png
<subjek>-before.png / <subjek>-after.png
```
Contoh:
```
storage-node-01-capacity-2026-01-01.png
storage-node-01-capacity-2026-08-01.png
mnt-2026-005-before.png
mnt-2026-005-after.png
```

### 2.3 Daftar Nama Baku yang Sudah Dipakai

Gunakan nama ini agar tautan di dokumen tetap konsisten:

| Nama File | Lokasi | Dipakai Di |
|---|---|---|
| `hpc-node-01-rack.png` | `racks/` | `inventory/hpc-nodes/hpc-node-01.md` |
| `hpc-node-01-rear-cabling.png` | `racks/` | `inventory/hpc-nodes/hpc-node-01.md` |
| `hpc-node-01-dimm-layout.png` | `diagrams/` | `inventory/hpc-nodes/hpc-node-01.md` |
| `hpc-node-01-idrac-dashboard.png` | `screenshots/` | `inventory/hpc-nodes/hpc-node-01.md` |
| `hpc-node-01-nvidia-smi.png` | `screenshots/` | `inventory/hpc-nodes/hpc-node-01.md` |
| `storage-node-01-rack.png` | `racks/` | `inventory/storage-nodes/storage-node-01.md` |
| `storage-node-01-disk-bay-map.png` | `diagrams/` | `inventory/storage-nodes/storage-node-01.md` |
| `storage-node-01-zfs-topology.png` | `diagrams/` | `inventory/storage-nodes/storage-node-01.md` |
| `storage-node-01-zpool-status.png` | `screenshots/` | `inventory/storage-nodes/storage-node-01.md` |
| `storage-node-01-capacity-trend.png` | `screenshots/` | `inventory/storage-nodes/storage-node-01.md` |
| `proxmox-node-01-rack.png` | `racks/` | `inventory/proxmox-nodes/proxmox-node-01.md` |
| `proxmox-node-01-network-bridge.png` | `diagrams/` | `inventory/proxmox-nodes/proxmox-node-01.md` |
| `proxmox-node-01-vm-map.png` | `diagrams/` | `inventory/proxmox-nodes/proxmox-node-01.md` |
| `proxmox-node-01-dashboard.png` | `screenshots/` | `inventory/proxmox-nodes/proxmox-node-01.md` |
| `proxmox-node-01-storage.png` | `screenshots/` | `inventory/proxmox-nodes/proxmox-node-01.md` |
| `network-topology-overview.png` | `diagrams/` | `README.md` |
| `dataflow-scratch-to-storage.png` | `diagrams/` | `docs/sop/sop-bioinformatics-execution.md` |

---

## 3. Cara Memanggil Gambar di Markdown

Gambar dipanggil dengan **path relatif** dari lokasi file `.md` yang memanggilnya.

### 3.1 Tabel Prefix Relatif

| File `.md` berada di | Prefix |
|---|---|
| Root repo (`README.md`, `CHANGELOG.md`) | `assets/images/` |
| `docs/sop/` | `../../assets/images/` |
| `inventory/hpc-nodes/` | `../../assets/images/` |
| `inventory/storage-nodes/` | `../../assets/images/` |
| `inventory/proxmox-nodes/` | `../../assets/images/` |
| `track-record/` | `../assets/images/` |
| `assets/images/` (dokumen ini) | `./` |

Cara menghitungnya: satu `../` untuk setiap tingkat direktori dari lokasi
file `.md` menuju root repo.

### 3.2 Sintaks Dasar

```markdown
![Teks alternatif](path/ke/gambar.png)
```

Dari `README.md` (root):
```markdown
![Diagram topologi jaringan cluster](assets/images/diagrams/network-topology-overview.png)
```

Dari `inventory/hpc-nodes/hpc-node-01.md`:
```markdown
![Posisi rak hpc-node-01](../../assets/images/racks/hpc-node-01-rack.png)
```

Dari `track-record/maintenance-log.md`:
```markdown
![Kondisi bay sebelum penggantian](../assets/images/screenshots/mnt-2026-006-before.png)
```

Dari `docs/sop/sop-bioinformatics-execution.md`:
```markdown
![Alur data scratch ke storage](../../assets/images/diagrams/dataflow-scratch-to-storage.png)
```

### 3.3 Mengatur Ukuran Gambar

Markdown murni tidak mendukung pengaturan ukuran. Gunakan HTML — GitHub merendernya:

```markdown
<img src="../../assets/images/racks/hpc-node-01-rack.png"
     alt="Posisi rak hpc-node-01"
     width="600">
```

Panduan lebar:

| Jenis Gambar | Lebar Disarankan |
|---|---|
| Diagram besar (topologi cluster) | `900` atau tanpa batas |
| Diagram node tunggal | `700` |
| Foto rak (potret) | `400` |
| Foto rak (lanskap) | `700` |
| Screenshot terminal | `800` |
| Close-up label aset | `450` |

### 3.4 Gambar Bisa Diklik untuk Ukuran Penuh

Berguna untuk diagram detail yang terlalu kecil saat ditampilkan inline:

```markdown
[![Peta bay disk](../../assets/images/diagrams/storage-node-01-disk-bay-map.png)](../../assets/images/diagrams/storage-node-01-disk-bay-map.png)
```

### 3.5 Gambar dengan Keterangan

```markdown
<p align="center">
  <img src="../../assets/images/diagrams/storage-node-01-zfs-topology.png"
       alt="Topologi ZFS storage-node-01" width="800"><br>
  <em>Gambar 1 — Topologi pool <code>tank</code>: 3 vdev raidz2 + special vdev mirror + 2 hot spare</em>
</p>
```

### 3.6 Dua Gambar Berdampingan (Sebelum/Sesudah)

```markdown
| Sebelum | Sesudah |
|---|---|
| ![Sebelum](../assets/images/screenshots/mnt-2026-005-before.png) | ![Sesudah](../assets/images/screenshots/mnt-2026-005-after.png) |
```

### 3.7 Diagram Mermaid — Alternatif Tanpa File Gambar

Untuk diagram sederhana, gunakan Mermaid langsung di Markdown.
GitHub merendernya otomatis, dan hasilnya bisa dicari serta di-diff oleh Git —
keunggulan besar dibanding file gambar biner.

````markdown
```mermaid
flowchart LR
    A[/mnt/storage/raw] -->|stage-in| B[/scratch/$USER/$JOBID]
    B --> C[Proses berat]
    C --> D[Kompres ke CRAM]
    D -->|stage-out| E[/mnt/storage/projects]
    C -.->|hapus| F[File temp .sam]
```
````

**Kapan pakai Mermaid, kapan pakai file gambar:**

| Gunakan | Untuk |
|---|---|
| **Mermaid** | Alur proses, hubungan antar node, diagram sederhana yang sering berubah, apa pun yang ingin bisa di-`git diff` |
| **File SVG/PNG** | Denah rak dengan posisi RU presisi, peta bay disk, layout DIMM, diagram yang butuh kontrol tata letak penuh |
| **Foto (JPG)** | Kondisi fisik nyata: kabel, label aset, kerusakan komponen |

---

## 4. Standar Teknis File

### 4.1 Format

| Format | Kapan Dipakai | Catatan |
|---|---|---|
| `.svg` | Diagram buatan sendiri | **Format utama untuk diagram** — tajam di semua zoom, ukuran kecil, bisa di-`diff` |
| `.png` | Screenshot, diagram dengan transparansi | Lossless, cocok untuk teks tajam |
| `.jpg` | Foto kamera | Lebih kecil untuk foto; jangan dipakai untuk screenshot (teks jadi buram) |
| `.webp` | Alternatif hemat ukuran | Didukung GitHub; pakai bila PNG terlalu besar |
| `.drawio` | **Sumber** diagram | Simpan berdampingan dengan hasil ekspornya |

Jangan gunakan: `.bmp`, `.tiff`, `.heic`, `.psd`, `.ai` — semuanya diblokir `.gitignore`.

### 4.2 Batas Ukuran

| Jenis | Maks Ukuran File | Maks Resolusi |
|---|---|---|
| Diagram SVG | 500 KB | — (vektor) |
| Diagram PNG | 1 MB | 2000 × 2000 px |
| Screenshot | 800 KB | 1920 × 1080 px |
| Foto rak | **2 MB** | 2400 px sisi terpanjang |

> **Repo dokumentasi harus tetap ringan.** Total seluruh `assets/images/`
> sebaiknya di bawah 100 MB. Jika mendekati batas, kompres ulang gambar lama
> atau pertimbangkan Git LFS.

### 4.3 Kompresi Sebelum Commit

```bash
# PNG — pngquant (lossy, hasil sangat baik untuk screenshot)
pngquant --quality=65-85 --strip --force --ext .png gambar.png

# PNG — optipng (lossless)
optipng -o5 -strip all gambar.png

# JPG — turunkan kualitas & ubah ukuran
convert foto.jpg -resize 2400x2400\> -quality 82 -strip foto-compressed.jpg

# SVG — bersihkan metadata editor
svgo --multipass diagram.svg

# Cek ukuran sebelum commit
ls -lh assets/images/**/*.png
du -sh assets/images/
find assets/images -type f -size +2M -exec ls -lh {} \;
```

### 4.4 Git LFS (jika suatu saat diperlukan)

Belum diaktifkan. Jika total gambar melewati 100 MB:

```bash
git lfs install
git lfs track "assets/images/racks/*.jpg"
git lfs track "assets/images/**/*.png"
git add .gitattributes
git commit -m "chore(assets): aktifkan Git LFS untuk gambar"
```

---

## 5. Aturan Konten Gambar

### 5.1 Yang Boleh Terlihat

- IP privat (`10.x.x.x`, `192.168.x.x`)
- Hostname internal
- Serial number & asset tag
- Nomor bay/slot, posisi RU
- Nama VLAN, subnet, port switch
- Output perintah sistem (`zpool status`, `nvidia-smi`, `sinfo`)

### 5.2 Yang WAJIB Disensor Sebelum Commit

| Konten | Cara Menangani |
|---|---|
| Password / passphrase | Blur atau tutup dengan kotak solid |
| API token, session cookie | Blur |
| Private key / sertifikat | Jangan di-screenshot sama sekali |
| Isi file `.env` | Jangan di-screenshot sama sekali |
| Field password di UI iDRAC/Proxmox | Tutup kotak solid |
| Alamat email pribadi peneliti | Blur |
| Nama pasien / ID sampel yang dapat mengidentifikasi individu | **Wajib blur** — data biologis manusia tunduk aturan etik |
| Wajah orang | Blur, kecuali sudah ada izin tertulis |
| IP publik institusi | Sebagian disensor (`103.xxx.xxx.45`) |
| QR code / barcode lisensi | Blur |

> **Gunakan kotak solid, bukan blur, untuk kredensial.** Blur ringan dapat
> dibalik dengan alat pemulihan gambar. Untuk teks rahasia, tutup penuh
> dengan persegi hitam yang di-*flatten* ke gambar.

```bash
# Tutup area dengan kotak hitam (koordinat x1,y1 x2,y2)
convert screenshot.png -fill black -draw "rectangle 420,180 780,215" screenshot-redacted.png

# Blur area tertentu
convert screenshot.png -region 420x35+420+180 -blur 0x12 +region screenshot-blurred.png

# Hapus metadata EXIF dari foto (bisa mengandung lokasi GPS!)
exiftool -all= foto.jpg
mogrify -strip foto.jpg
```

> ⚠️ **Selalu hapus EXIF dari foto kamera/ponsel.** Metadata dapat memuat
> koordinat GPS ruang server, model perangkat, dan waktu pengambilan.

### 5.3 Verifikasi Sebelum Commit

```bash
# Cek metadata yang tersisa
exiftool assets/images/racks/*.jpg | grep -i -E 'gps|location|serial|owner'

# Pastikan tidak ada file besar
find assets/images -type f -size +2M

# Tinjau gambar baru secara visual sebelum push — buka satu per satu
```

---

## 6. Kualitas Foto Rak

Foto yang buruk lebih merugikan daripada tidak ada foto, karena memberi rasa
aman palsu bahwa sesuatu "sudah terdokumentasi".

**Standar minimum:**

- [ ] Pencahayaan cukup — gunakan senter/lampu ruang server, jangan andalkan flash yang memantul
- [ ] Fokus tajam pada objek utama
- [ ] Label aset dan nomor RU terbaca jelas
- [ ] Sertakan konteks: minimal satu node di atas dan di bawah agar posisi jelas
- [ ] Ambil tegak lurus, bukan menyudut ekstrem
- [ ] Untuk foto kabel: pastikan label kabel terbaca
- [ ] Untuk close-up serial: cukup dekat sampai teks terbaca tanpa zoom digital

**Set foto standar per node baru:**

| Foto | Nama File | Tujuan |
|---|---|---|
| Posisi di rak (dengan node tetangga) | `<hostname>-rack.jpg` | Menemukan node secara fisik |
| Tampak depan chassis | `<hostname>-front.jpg` | Kondisi bay, LED, label |
| Tampak belakang + kabel | `<hostname>-rear-cabling.jpg` | Jejak kabel jaringan & daya |
| Close-up label aset | `<hostname>-asset-tag.jpg` | Verifikasi serial & asset tag |

---

## 7. Checklist Menambahkan Gambar Baru

- [ ] Nama file mengikuti pola di bagian 2
- [ ] Ditempatkan di subdirektori yang benar (`racks/`, `diagrams/`, `screenshots/`)
- [ ] Format sesuai jenis konten (SVG untuk diagram, PNG untuk screenshot, JPG untuk foto)
- [ ] Ukuran file di bawah batas (bagian 4.2)
- [ ] Sudah dikompres
- [ ] EXIF dihapus (untuk foto)
- [ ] Konten sensitif sudah ditutup kotak solid, bukan sekadar blur
- [ ] Ditinjau visual sekali lagi sebelum `git add`
- [ ] Sudah dirujuk dari minimal satu file `.md` dengan path relatif yang benar
- [ ] Path relatif diuji di tab *Preview* GitHub (gambar benar-benar muncul)
- [ ] Teks alternatif (`alt`) deskriptif, bukan sekadar "gambar"
- [ ] File sumber `.drawio` ikut di-commit (bila diagram dibuat di draw.io)
- [ ] Baris ditambahkan ke tabel "Daftar Nama Baku" di bagian 2.3

---

## 8. Membuat Diagram

**Alat yang disarankan:**

| Alat | Untuk | Ekspor |
|---|---|---|
| [draw.io / diagrams.net](https://app.diagrams.net) | Diagram rak, jaringan, topologi | `.svg` + simpan `.drawio` |
| Mermaid (langsung di Markdown) | Alur proses, hubungan sederhana | — (dirender GitHub) |
| Excalidraw | Sketsa cepat, gaya tulisan tangan | `.svg` |
| Graphviz / `dot` | Diagram yang dihasilkan dari data | `.svg` |

**Konvensi visual agar seluruh dokumen konsisten:**

| Elemen | Warna | Bentuk |
|---|---|---|
| Node compute (HPC) | Biru `#3B82F6` | Persegi panjang |
| Node storage | Hijau `#10B981` | Silinder |
| Node hypervisor | Ungu `#8B5CF6` | Persegi panjang bertumpuk |
| Switch / jaringan | Abu-abu `#6B7280` | Belah ketupat |
| VM / LXC | Ungu muda `#C4B5FD` | Persegi panjang bergaris putus |
| Jalur data cepat (25GbE) | Garis tebal | — |
| Jalur manajemen (1GbE) | Garis tipis | — |
| Jalur IPMI | Garis putus-putus | — |

**Ekspor dari draw.io:**
1. `File → Export as → SVG`
2. Centang **"Include a copy of my diagram"** — ini menyimpan sumber di dalam SVG,
   sehingga file `.svg` bisa dibuka lagi di draw.io untuk diedit
3. Simpan ke `assets/images/diagrams/`
4. Jalankan `svgo --multipass` untuk membersihkan

---

## 9. Contoh Lengkap: Menambahkan Foto Node Baru

```bash
# 1. Ambil foto, salin ke komputer kerja
# 2. Hapus metadata
exiftool -all= IMG_2847.jpg

# 3. Ubah ukuran & kompres
convert IMG_2847.jpg -resize 2400x2400\> -quality 82 -strip hpc-node-03-rack.jpg

# 4. Periksa ukuran
ls -lh hpc-node-03-rack.jpg      # harus < 2 MB

# 5. Pindahkan ke direktori yang benar
mv hpc-node-03-rack.jpg assets/images/racks/

# 6. Rujuk dari dokumen node
#    (di inventory/hpc-nodes/hpc-node-03.md, tepat di bawah header)
```

Isi rujukannya:
```markdown
![Posisi rak hpc-node-03 di RACK-B02 RU 20–21](../../assets/images/racks/hpc-node-03-rack.jpg)
```

```bash
# 7. Commit
git add assets/images/racks/hpc-node-03-rack.jpg
git add inventory/hpc-nodes/hpc-node-03.md
git commit -m "docs(hpc-node-03): tambah foto posisi rak"
```

# Changelog

Semua perubahan penting pada **dokumentasi infrastruktur** ini dicatat di file ini.

Format mengikuti [Keep a Changelog 1.1.0](https://keepachangelog.com/id/1.1.0/),
dan penomoran versi mengikuti [Semantic Versioning 2.0.0](https://semver.org/lang/id/).

> **Cakupan file ini:** perubahan pada *dokumen* (struktur repo, template, SOP, isi inventory).
> Perubahan **fisik server** (ganti RAM, tambah disk, upgrade OS) dicatat di
> [`track-record/server-changelog.md`](track-record/server-changelog.md).
> Kegiatan **maintenance terjadwal** dicatat di
> [`track-record/maintenance-log.md`](track-record/maintenance-log.md).

---

## Aturan Penomoran Versi Dokumentasi

| Segmen | Naik ketika... | Contoh |
|---|---|---|
| **MAJOR** (`X.0.0`) | Struktur direktori repo berubah total; template lama tidak kompatibel; konvensi penamaan diganti | `1.4.2` → `2.0.0` |
| **MINOR** (`x.Y.0`) | Menambah node baru, menambah dokumen/SOP baru, menambah section besar pada template | `1.4.2` → `1.5.0` |
| **PATCH** (`x.y.Z`) | Koreksi typo, update nilai spesifikasi, perbaikan tautan, penyesuaian tabel | `1.4.2` → `1.4.3` |

## Kategori Perubahan yang Dipakai

| Kategori | Arti |
|---|---|
| `Added` | Dokumen, node, section, atau fitur dokumentasi baru |
| `Changed` | Perubahan pada dokumen/prosedur yang sudah ada |
| `Deprecated` | Bagian yang akan dihapus di versi berikutnya |
| `Removed` | Dokumen/section yang sudah dihapus |
| `Fixed` | Perbaikan informasi yang salah |
| `Security` | Perubahan terkait keamanan (rotasi kredensial, pengetatan `.gitignore`, hardening SOP) |

---

## [Unreleased]

Bagian ini menampung perubahan yang sudah di-merge ke `main` tapi belum di-*tag* rilis.
Saat rilis, pindahkan isinya ke section versi baru di bawah dan kosongkan bagian ini.

### Added
- `inventory/hpc-nodes/hpc-gpu.md` — **pendataan node komputasi**.
  ASRockRack ROME2D32GM-2T, 2× AMD EPYC 7763 (128C/256T), RAM 1 TB DDR4 ECC
  (16 channel terisi penuh), 2× NVIDIA A100-SXM4-40GB + 1× RTX 5060 Ti,
  scratch RAID0 4× NVMe 3.5 TB, Ubuntu 24.04.4 LTS. Terdaftar di Slurm cluster
  `bioinfo` sebagai `compute001`. Mencakup 25 temuan Known Issues terprioritas.
  Data dikumpulkan otomatis via SSH pada 2026-08-28.
- `scripts/collect-hpc.sh` — kolektor inventaris node HPC (Ubuntu bare-metal),
  seluruhnya read-only: GPU (`nvidia-smi`), Slurm, mdadm/NVMe + wear indicator,
  mount NFS, stack software, agen monitoring, dan hardening dasar.
- `README.md` §4.1 — daftar node yang teridentifikasi dari konfigurasi node lain
  tapi belum didata: `pipeline` (`192.168.18.194`, Slurm controller),
  `192.168.30.2` dan `192.168.18.113` (storage NFS).
- `inventory/proxmox-nodes/proxmox.md` — **pendataan node asli pertama**.
  Host Supermicro H12SSL-I / AMD EPYC 7B13 (64C/128T), RAM 256 GB DDR4-3200 ECC,
  Proxmox VE 9.2.10 di Debian 13. Mencakup 13 disk fisik lengkap dengan serial &
  status SMART, 4 ZFS pool (`zfs-storage` raidz2 11×14 TB di atas LUKS,
  `backup-pool`, `nvme-scratch`, `rpool`), konfigurasi jaringan, IPMI,
  2 VM (`dev-pipeline`, `dev-bioinfo`), dan 18 temuan Known Issues terprioritas.
  Data dikumpulkan otomatis via SSH pada 2026-08-28.
- `docs/penginputan-node.md` — panduan penginputan node: alur 6 langkah dari
  pengumpulan data sampai Pull Request, peta output kolektor ke bagian dokumen,
  daftar field yang wajib disurvei fisik, dan cara menyusun Known Issues.
- `scripts/collect-proxmox.sh` — kolektor inventaris Proxmox, seluruhnya read-only,
  bisa dijalankan via SSH (`<host> [user] [key]`) atau langsung di host (`--local`).
- `inventory/_templates/README.md` — penjelasan bahwa isi folder template adalah
  contoh, bukan server nyata, beserta cara menyalinnya.

### Changed
- **Template contoh dipisahkan dari data asli.** Tiga dokumen contoh dipindah
  (isi tidak diubah sama sekali):
  - `inventory/hpc-nodes/hpc-node-01.md` → `inventory/_templates/hpc-node.template.md`
  - `inventory/storage-nodes/storage-node-01.md` → `inventory/_templates/storage-node.template.md`
  - `inventory/proxmox-nodes/proxmox-node-01.md` → `inventory/_templates/proxmox-node.template.md`
- `README.md` §4 — tabel Index Node kini hanya memuat node yang benar-benar ada
  (`proxmox`), dengan catatan bahwa arsitektur di §2–§3 masih berupa desain target.
- `README.md` §5 — struktur repository diperbarui: `inventory/_templates/`,
  `scripts/`, `docs/penginputan-node.md`.
- `README.md` §7.1 — tabel prefix gambar ditambah baris `docs/` dan `inventory/_templates/`.
- `README.md` §8 — prosedur menambah node mengarah ke kolektor dan folder template.
- Konvensi penamaan file node: memakai **hostname asli** (`proxmox.md`),
  bukan nomor urut (`proxmox-node-01.md`).

### Deprecated
- *(belum ada)*

### Removed
- *(belum ada)*

### Fixed
- *(belum ada)*

### Security
- Terdokumentasi dari pendataan `proxmox` (belum ditindaklanjuti, lihat §12 dokumen node):
  firewall Proxmox belum aktif, IPMI satu segmen dengan jaringan data via DHCP,
  SNMP BMC masih community `public`, `PermitRootLogin yes`, hanya ada `root@pam`
  tanpa 2FA, dan **VM belum punya backup sama sekali**.
- `scripts/collect-proxmox.sh` sengaja tidak pernah mencetak password, private key,
  passphrase LUKS, maupun isi berkas kredensial.

---

## [1.0.0] — 2026-08-28

Rilis awal dokumentasi infrastruktur bioinformatics bare-metal.

### Added
- `README.md` — overview infrastruktur, diagram arsitektur (ASCII + Mermaid),
  tabel mapping path storage (`/scratch`, `/mnt/storage`, `/home`, `/opt`),
  index node, tata cara update repo, dan panduan pemanggilan gambar.
- `.gitignore` — rule khusus sysadmin & bioinformatics: memblokir data sekuens
  (`*.fastq`, `*.bam`, `*.sam`, `*.vcf`, `*.cram`), container image (`*.sif`),
  kredensial (`*.key`, `*.pem`, `.env`), dan log (`*.log`, `slurm-*.out`).
- `CHANGELOG.md` — dokumen ini, format Keep a Changelog.
- `inventory/hpc-nodes/hpc-node-01.md` — template detail node compute bare-metal:
  identitas aset, posisi rak/RU, IPMI/iDRAC, CPU socket/core/thread, layout RAM,
  GPU + VRAM, NVMe scratch lokal, partisi Slurm, daftar Conda env & Singularity image.
- `inventory/storage-nodes/storage-node-01.md` — template node storage bare-metal:
  topologi ZFS/RAID, tabel disk per-slot, kapasitas raw vs usable, status SMART,
  mount point, export NFS/SMB, kebijakan snapshot & scrub.
- `inventory/proxmox-nodes/proxmox-node-01.md` — template host Proxmox VE bare-metal:
  network bridge & VLAN, ZFS datastore lokal, tabel VM/LXC aktif beserta IP
  dan alokasi resource, kebijakan backup.
- `track-record/maintenance-log.md` — form laporan maintenance dengan checklist
  pre/post, estimasi downtime, rollback plan, dan PIC.
- `track-record/server-changelog.md` — log perubahan infrastruktur permanen
  (hardware, OS, kernel, firewall/network).
- `docs/sop/sop-bioinformatics-execution.md` — SOP eksekusi bioinformatics:
  pre-flight check (ruang storage ≥ 3× input, pemisahan scratch, pencegahan OOM),
  standar eksekusi (larangan run di SSH root, wajib Slurm/tmux, isolasi
  Conda/Singularity), batas resource (CPU 80–90%, monitoring I/O), dan housekeeping.
- `assets/images/README.md` — standar penamaan file gambar dan cara memanggilnya
  di Markdown dari berbagai kedalaman direktori.
- Struktur direktori `assets/images/{racks,diagrams,screenshots}/` dengan `.gitkeep`.

### Security
- `.gitignore` memblokir seluruh pola kredensial umum (`id_rsa*`, `*.pem`, `*.p12`,
  `.env`, `ipmi-*.conf`) sejak commit pertama.
- Ditetapkan aturan: kredensial IPMI/iDRAC **tidak pernah** ditulis di repo,
  hanya direferensikan ke password manager.

---

<!--
=============================================================================
 TEMPLATE ENTRI BARU — copy blok di bawah ini saat membuat rilis versi baru.
 Letakkan versi terbaru di ATAS (urutan menurun).
=============================================================================

## [X.Y.Z] — YYYY-MM-DD

Ringkasan 1–2 kalimat tentang fokus rilis ini.

### Added
- ...

### Changed
- ...

### Deprecated
- ...

### Removed
- ...

### Fixed
- ...

### Security
- ...

=============================================================================
 CONTOH ENTRI TERISI (untuk referensi gaya penulisan):

## [1.1.0] — 2026-09-15

Penambahan node compute ketiga dan pengetatan SOP housekeeping.

### Added
- `inventory/hpc-nodes/hpc-node-03.md` — node compute baru, 2x AMD EPYC 9554,
  RAM 1 TB, tanpa GPU, NVMe scratch 15 TB, masuk partisi `bigmem`.
- `assets/images/racks/hpc-node-03-rack.png` — foto posisi RU 20-21 Rak B02.
- Section "Prosedur Purge Otomatis /scratch" pada SOP eksekusi.

### Changed
- `README.md` — tabel index node diperbarui dengan `hpc-node-03`.
- `docs/sop/sop-bioinformatics-execution.md` — batas CPU diturunkan dari 90%
  menjadi 85% pada node dengan NFS client aktif, karena `nfsd` kelaparan CPU
  saat semua core dipakai job.

### Fixed
- `inventory/proxmox-nodes/proxmox-node-01.md` — koreksi IP VM `db-postgres`
  dari `10.10.20.45` menjadi `10.10.20.46`.

### Security
- Rotasi seluruh password IPMI setelah pergantian PIC sysadmin;
  dokumen hanya menyimpan referensi ke entri Vaultwarden.
=============================================================================
-->

[Unreleased]: https://github.com/<org-anda>/server-infrastructure/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/<org-anda>/server-infrastructure/releases/tag/v1.0.0

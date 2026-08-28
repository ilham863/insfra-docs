# Panduan Penginputan Node

Cara menambah atau memperbarui data server di repo ini, dari nol sampai ter-push.

> **Terakhir Diperbarui:** 2026-08-28

---

## 0. Aturan dasar

| Aturan | Alasan |
|---|---|
| **File di `inventory/_templates/` tidak pernah diedit** | Itu contoh/kerangka. Selalu **salin**, jangan diisi langsung. |
| **Nama file = hostname asli**, bukan nama karangan | `hostname -f` di server adalah sumber kebenaran. `proxmox.md`, bukan `proxmox-node-01.md`. |
| **Field yang tidak diketahui ditulis `*(isi)*`**, bukan dikosongkan | Supaya kelihatan mana yang belum terdata, bukan hilang diam-diam. |
| **Tidak ada kredensial** — password, token, private key, passphrase LUKS | Lihat §6.6 di [README](../README.md). Cukup tulis referensi ke password manager. |
| **Angka & versi disalin apa adanya dari output perintah** | Dokumentasi yang mengarang lebih berbahaya daripada tidak ada dokumentasi. |

---

## 1. Alur singkat

```
  ┌──────────────────────────┐
  │ 1. Jalankan kolektor     │   scripts/collect-<tipe>.sh
  │    (read-only, via SSH)  │
  └────────────┬─────────────┘
               ▼
  ┌──────────────────────────┐
  │ 2. Salin template        │   inventory/_templates/*.template.md
  │    → inventory/<tipe>/   │   nama file = hostname
  └────────────┬─────────────┘
               ▼
  ┌──────────────────────────┐
  │ 3. Isi dari output       │   yang tidak terbaca SSH → survei fisik
  └────────────┬─────────────┘
               ▼
  ┌──────────────────────────┐
  │ 4. Daftarkan di index    │   README.md §4
  └────────────┬─────────────┘
               ▼
  ┌──────────────────────────┐
  │ 5. Catat perubahan       │   track-record/ + CHANGELOG.md
  └────────────┬─────────────┘
               ▼
  ┌──────────────────────────┐
  │ 6. Branch → commit → PR  │
  └──────────────────────────┘
```

---

## 2. Langkah 1 — Kumpulkan data

### 2.1 Proxmox

```bash
bash scripts/collect-proxmox.sh <ip> root ~/.ssh/<key> > /tmp/pve-$(date +%F).txt
```

Contoh nyata:

```bash
bash scripts/collect-proxmox.sh 192.168.18.190 root ~/.ssh/id_proxmox > /tmp/pve-2026-08-28.txt
```

### 2.2 HPC / Storage node

Kolektor khusus untuk kedua tipe ini **belum dibuat**. Sementara, jalankan manual
di server target dan salin outputnya:

```bash
# Identitas
hostname -f
dmidecode -s system-serial-number
dmidecode -s system-product-name

# CPU / RAM
lscpu
free -h
dmidecode -t memory | grep -E 'Size:|Locator:|Speed:|Part Number:'

# Disk & ZFS
lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL,ROTA,MOUNTPOINT
zpool list && zpool status
zfs list

# Jaringan
ip -br address
cat /etc/network/interfaces        # Debian/PVE
nmcli device show                  # RHEL/Rocky

# IPMI
ipmitool lan print 1

# GPU (khusus HPC)
nvidia-smi -q | head -60
```

### 2.3 Yang **tidak bisa** diambil lewat SSH

Wajib disurvei langsung ke ruang server:

- Nama rak & posisi RU
- Jalur PDU A / PDU B dan nomor outlet
- Jumlah & watt PSU
- Label kabel
- Asset tag fisik
- Tanggal pembelian, garansi, nomor kontrak support

---

## 3. Langkah 2 — Salin template

```bash
# Proxmox
cp inventory/_templates/proxmox-node.template.md inventory/proxmox-nodes/<hostname>.md

# HPC
cp inventory/_templates/hpc-node.template.md     inventory/hpc-nodes/<hostname>.md

# Storage
cp inventory/_templates/storage-node.template.md inventory/storage-nodes/<hostname>.md
```

Kedalaman folder template sama dengan folder node (`inventory/<sesuatu>/`),
jadi semua path relatif di dalam template (`../../assets/...`) tetap benar
setelah disalin. Tidak perlu diubah.

---

## 4. Langkah 3 — Isi dokumennya

Peta dari output kolektor ke bagian dokumen:

| Bagian dokumen | Sumber di output kolektor |
|---|---|
| §1 Identitas | `IDENTITAS` (dmidecode) |
| §1.1 Lokasi Fisik | **survei fisik** — tidak ada di output |
| §2 IPMI | `IPMI` (`ipmitool lan print 1`, `mc info`) |
| §3.1 CPU | `CPU` (`lscpu`) |
| §3.2 Memory | `MEMORY` (`free -h`, `dmidecode -t memory`) |
| §3.3 Jaringan | `NETWORK` |
| §4 Versi PVE/OS | `PVE-VERSION`, `CLUSTER` |
| §5 Disk | `DISK` (`lsblk`, `smartctl`) |
| §6 ZFS Pool | `ZFS` |
| §7 Dataset & storage | `ZFS`, `STORAGE-PVE` |
| §8 VM & LXC | `VM-LXC` |
| §9 Backup | `BACKUP` |
| §10 Keamanan | `KEAMANAN` |
| §12 Known Issues | **analisis** — lihat §4.1 di bawah |

### 4.1 Mengisi Known Issues

Bagian ini yang membuat dokumen berguna, bukan sekadar daftar spesifikasi.
Hal yang rutin dicek tiap kali mendata:

| Cek | Cara lihat di output |
|---|---|
| Ada pool tanpa redundansi? | `zpool status` — vdev tunggal, bukan mirror/raidz |
| Ada pool > 80% penuh? | `zpool list` kolom `CAP` |
| Backup benar-benar jalan? | `jobs.cfg` ada isinya **dan** dump dir tidak kosong |
| Firewall aktif? | ada `cluster.fw` / `*.fw` |
| IPMI terpisah dari jaringan data? | `ipmitool lan print` — VLAN ID, subnet |
| Slot RAM terisi penuh sesuai channel platform? | `dmidecode -t memory` vs jumlah channel motherboard |
| Kecepatan uplink sepadan dengan kapasitas storage? | speed per-NIC vs total TB |
| Scrub terakhir kapan? | `zpool status` baris `scan:` |
| Ada single point of failure tersembunyi? | mis. dua pool berbagi satu disk fisik |

Tulis setiap temuan dengan **dampak konkret**, bukan label umum.
Bandingkan: *"backup-pool 93% penuh"* versus
*"backup-pool 93% penuh, single disk tanpa redundansi, berisi 10.1 T — 1 disk mati = 10 T hilang"*.
Yang kedua bisa ditindaklanjuti.

Prioritas: 🔴 Kritis (kehilangan data / node mati) · 🟠 Tinggi (risiko keamanan atau
performa besar) · 🟡 Sedang (perlu diperbaiki, tidak mendesak) · 🟢 Rendah (catatan).

---

## 5. Langkah 4 — Daftarkan di index

Tambahkan baris di tabel **§4 Index Node** pada [`README.md`](../README.md):

```markdown
| `<hostname>` | <Tipe> | [inventory/<tipe>/<hostname>.md](inventory/<tipe>/<hostname>.md) | 🟢 Production |
```

---

## 6. Langkah 5 — Catat perubahannya

| File | Isi yang ditambahkan |
|---|---|
| [`track-record/server-changelog.md`](../track-record/server-changelog.md) | Perubahan **fisik/konfigurasi** server (`SCL-<tahun>-<nnn>`) |
| [`track-record/maintenance-log.md`](../track-record/maintenance-log.md) | Kalau pendataan disertai pekerjaan maintenance |
| [`CHANGELOG.md`](../CHANGELOG.md) | Perubahan **dokumen** — bagian `[Unreleased]` |

Pendataan murni (tanpa menyentuh server) cukup masuk `CHANGELOG.md` saja.

---

## 7. Langkah 6 — Commit & Pull Request

```bash
git checkout main && git pull --rebase origin main
git checkout -b inventory/add-<hostname>

# pastikan tidak ada yang terlarang ikut ter-stage
git status --short          # TIDAK boleh ada .fastq/.bam/.vcf/.key/.pem/.env

git add .
git commit -m "feat(inventory): tambah pendataan node <hostname>"
git push -u origin inventory/add-<hostname>
```

Checklist sebelum PR ada di [README §6.5](../README.md#65-checklist-sebelum-pull-request).

---

## 8. Kapan mendata ulang

| Pemicu | Tindakan |
|---|---|
| Ganti/tambah hardware | Perbarui bagian terkait + entri `SCL-` di server-changelog |
| Upgrade PVE / OS / kernel | Perbarui §4, catat `OS-MAJOR` / `OS-KERNEL` |
| Tambah/hapus VM atau LXC | Perbarui §8 |
| Perubahan topologi ZFS | Perbarui §6, catat `HW-DISK` |
| Perubahan IP / VLAN | Perbarui §2 dan §3.3 |
| **Rutin** | Jalankan kolektor tiap **kuartal**, bandingkan dengan dokumen |

Membandingkan hasil kolektor dengan pendataan sebelumnya:

```bash
bash scripts/collect-proxmox.sh 192.168.18.190 root ~/.ssh/id_proxmox > /tmp/pve-baru.txt
diff /tmp/pve-2026-08-28.txt /tmp/pve-baru.txt
```

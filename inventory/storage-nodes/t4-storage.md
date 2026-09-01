# T4-Storage — Storage Server (Bare-Metal, mdadm + ZFS)

> **Tipe Unit:** Bare-Metal Storage Server — 1 chassis fisik
> **Status:** 🟢 Production
> **Terakhir Diperbarui:** 2026-09-02
> **PIC Node:** *(isi nama sysadmin)*
> **Sumber Data:** ⚠️ **pendataan jarak jauh tanpa SSH** — `node_exporter` (`:9100`),
> `smartctl_exporter` (`:9633`), `showmount -e` dari `proxmox`, fingerprint TLS/HTTP,
> dan tabel ARP. Dikumpulkan 2026-09-02 02:40–03:10 WIB.
> **Dokumen Terkait:** [network-map](../network-map.md) · [hpc-gpu](../hpc-nodes/hpc-gpu.md) · [proxmox](../proxmox-nodes/proxmox.md) · [server-changelog](../../track-record/server-changelog.md) · [maintenance-log](../../track-record/maintenance-log.md)

> ⚠️ **NODE PALING KRITIS DI INFRASTRUKTUR SAAT INI.**
> Node ini adalah **satu-satunya penyedia storage bersama** untuk `HPC-GPU`
> (`/media/bio-pool`, 21,7 TB via NFS 10 GbE). Jika node ini turun, job di
> `HPC-GPU` yang membaca `bio-pool` akan berhenti. Node ini **juga** menjalankan
> seluruh stack monitoring (Prometheus + Grafana) — jadi kalau ia mati,
> **kemampuan memantau seluruh fleet ikut mati bersamaan**.

> 🔴 **Dua temuan yang butuh tindakan segera** — detail di
> [§12 Known Issues](#12-known-issues--risiko):
> 1. Disk `/dev/sdj` berstatus **SMART FAILED** (258.448 reallocated sector).
> 2. Kredensial IPMI node ini **bocor dalam bentuk plaintext** lewat Prometheus
>    yang terbuka tanpa autentikasi di LAN.

---

## 1. Identitas & Aset Fisik

| Field | Nilai |
|---|---|
| **Hostname (`uname -n`)** | `t4-Super-Server` |
| **FQDN** | ⚠️ *(belum terverifikasi — `domainname` = `(none)`, tidak ada PTR di DNS)* |
| **Alias / Label Fisik** | **T4-Storage** *(nama yang dipakai tim)* |
| **Vendor** | **Supermicro** |
| **Motherboard** | **H12SSL-i** (single socket SP3), board version `1.02` |
| **Model Sistem (DMI)** | `Super Server` |
| **Tipe Chassis** | Supermicro, `chassis_version = 0123456789` |
| **Serial Number (DMI)** | ⚠️ **belum diprogram** — `chassis_asset_tag` & `board_asset_tag` = `To be filled by O.E.M.` |
| **Asset Tag (internal)** | *(isi — wajib, karena serial DMI tidak unik)* |
| **BIOS** | AMI versi **2.5**, rilis **2022-09-08** (BIOS release 5.22) ⚠️ *± 4 tahun* |
| **Form Factor** | *(isi: rackmount xU / tower)* |
| **Tanggal Pembelian** | *(isi)* |
| **Tanggal Go-Live** | *(isi)* |
| **Garansi Berakhir** | *(isi)* |
| **Status Operasional** | 🟢 Production |
| **Boot Terakhir** | **2026-08-26 09:59 WIB** (uptime ± 7 hari saat pendataan) |
| **Timezone** | WIB (UTC+7) |

> **Catatan aset:** motherboard **H12SSL-i sama persis** dengan yang dipakai
> [`proxmox`](../proxmox-nodes/proxmox.md), dan **keduanya** punya serial DMI
> default `0123456789`. Identitas aset **tidak bisa** mengandalkan DMI —
> gunakan **asset tag fisik** atau **serial dari FRU BMC** (`ipmitool fru print`).

### 1.1 Lokasi Fisik

Belum disurvei — seluruh baris di bawah **wajib diisi lewat pemeriksaan fisik**.

| Field | Nilai |
|---|---|
| **Gedung / Ruang** | *(isi)* |
| **Nama Rak** | *(isi)* |
| **Posisi RU** | *(isi — chassis besar, 41 disk, perhatikan bobot)* |
| **PDU A / PDU B** | *(isi)* |
| **PSU** | *(isi — cek redundansi 1+1)* |
| **Berat (terisi penuh)** | *(isi)* |
| **UPS** | *(isi)* |
| **Label Kabel** | *(isi)* |

---

## 2. Manajemen Out-of-Band (IPMI)

| Field | Nilai |
|---|---|
| **Tipe BMC** | **Supermicro BMC** (ASPEED), IPMI 2.0 |
| **IP IPMI** | **`192.168.18.200/24`** |
| **VLAN** | ⚠️ **tidak dipisah** — satu segmen dengan LAN server |
| **Web UI** | `https://192.168.18.200` — judul halaman `Supermicro BMC Login` |
| **Sertifikat TLS** | self-signed Supermicro, berlaku **2023-03-23 → 2033-03-23** |
| **Port terbuka** | `22` (SSH `OpenSSH_9.8`), `80` (→ redirect 443), `443`, **`623` (IPMI RMCP)**, `5900` (KVM/VNC) |
| **Firmware BMC** | *(isi — butuh login BMC atau `ipmitool mc info` in-band)* |
| **MAC BMC** | *(isi)* |
| **NIC virtual BMC (sisi host)** | `enxbe3af2b6059f`, MAC `be:3a:f2:b6:05:9f` (USB RNDIS) |
| **Kredensial** | 🔴 **BOCOR — wajib dirotasi.** Lihat [`KI-T02`](#12-known-issues--risiko). Setelah rotasi simpan di password manager, entri `IPMI / t4-storage` — **jangan tulis di dokumen ini** |

> ⚠️ **MAC `be:3a:f2:b6:05:9f` identik dengan `nic2` di [`proxmox`](../proxmox-nodes/proxmox.md).**
> Keduanya NIC virtual USB bawaan BMC Supermicro yang memakai MAC default sama.
> Selama antarmuka ini tidak dijembatani ke LAN fisik, tidak ada konflik.
> **Jangan pernah** memasukkannya ke bridge (`vmbr`/`br0`).

```bash
# Setelah kredensial dirotasi:
ipmitool -I lanplus -H 192.168.18.200 -U <user> fru print          # serial & asset sahih
ipmitool -I lanplus -H 192.168.18.200 -U <user> mc info
ipmitool -I lanplus -H 192.168.18.200 -U <user> sel elist
ipmitool -I lanplus -H 192.168.18.200 -U <user> sdr type Temperature
ipmitool -I lanplus -H 192.168.18.200 -U <user> chassis identify 60
```

---

## 3. CPU, RAM, dan Sistem Operasi

| Field | Nilai |
|---|---|
| **Total Thread** | **128** *(dihitung dari `node_cpu_seconds_total`)* |
| **Model CPU** | ⚠️ *(belum terbaca — `node_exporter` tidak mengekspos model)*. H12SSL-i = **single socket SP3**, jadi 128 thread ⇒ **1× EPYC 64-core / 128-thread**. Konfirmasi dengan `lscpu` |
| **Socket** | 1 (batasan platform H12SSL-i) |
| **RAM Total** | **125,6 GiB** (`134.875.652.096` byte) ≈ **128 GB** |
| **Konfigurasi DIMM** | *(isi — butuh `dmidecode -t memory`)* |
| **OS** | **Ubuntu 22.04.5 LTS** (Jammy Jellyfish) |
| **Kernel** | `6.8.0-136-generic` (HWE) |
| **Arsitektur** | `x86_64` |
| **SSH** | `OpenSSH_8.9p1 Ubuntu-3ubuntu0.16` |

> ⚠️ **RAM 128 GB untuk melayani ± 198 TB kapasitas array.** Aturan praktis ZFS
> adalah ±1 GB RAM per 1 TB. Pool `bio-pool` (21,7 TB) sendiri masih aman, tapi
> ARC perlu dibatasi eksplisit agar `nfsd` dan array mdadm tidak kehabisan RAM.
> Verifikasi `zfs_arc_max` begitu akses SSH tersedia.

> ⚠️ **EPYC single-socket punya 8 channel memori.** 128 GB biasanya berarti
> 8× 16 GB (semua channel terisi, optimal) **atau** 4× 32 GB (setengah bandwidth).
> Wajib dicek — `proxmox` terbukti hanya mengisi 4 dari 8 channel.

---

## 4. Jaringan

| Interface | MAC | Status | Speed | IP | Peran |
|---|---|---|---|---|---|
| **`eno1`** | `3c:ec:ef:9f:7f:b0` | 🟢 UP | **1 Gb/s** | **`192.168.18.193/24`** | Manajemen / LAN server |
| `eno2` | `3c:ec:ef:9f:7f:b1` | 🟢 UP | ⚠️ **100 Mb/s** | *(isi)* | Port gigabit yang nego di 100 Mb — cek kabel/port switch |
| **`enp65s0f0`** | `94:57:a5:64:0d:48` | 🟢 UP | **10 Gb/s** | **`192.168.30.2/24`** | **SFP+ jalur data → `HPC-GPU` lewat switch Zyxel** |
| `enp65s0f1` | `94:57:a5:64:0d:4c` | ⚪ DOWN | — | — | Port SFP+ kedua, menganggur |
| `enxbe3af2b6059f` | `be:3a:f2:b6:05:9f` | 🟢 UP | 425 Mb/s | *(internal)* | NIC virtual USB dari BMC |

- OUI `3c:ec:ef` = **Super Micro Computer** (NIC onboard) — konsisten dengan BMC Supermicro di `.200`.
- OUI `94:57:a5` = **Hewlett Packard** — kartu SFP+ 10 GbE dual-port add-on.
- MTU per-interface **belum terverifikasi**. `HPC-GPU` memakai **MTU 9000** di sisi
  `192.168.30.3`, jadi sisi ini **harus** 9000 juga. Verifikasi wajib:
  `ping -M do -s 8972 -c4 192.168.30.3`.

### 4.1 Topologi SFP+ ke HPC-GPU

```
   T4-Storage                    Zyxel Switch                    HPC-GPU
  (t4-Super-Server)            192.168.18.250                  (compute001)
 ┌──────────────────┐         ┌───────────────┐          ┌──────────────────┐
 │ enp65s0f0        │  SFP+   │               │   SFP+   │ enp1s0f0         │
 │ 94:57:a5:64:0d:48├─────────┤  jalur data   ├──────────┤ c4:34:6b:fd:bc:58│
 │ 192.168.30.2     │ 10 GbE  │  192.168.30.x │  10 GbE  │ 192.168.30.3     │
 │ MTU ?  (cek!)    │         │               │          │ MTU 9000         │
 └────────┬─────────┘         └───────────────┘          └────────┬─────────┘
          │ eno1 1 GbE                                            │ enp34s0f0 1 GbE
          │ 192.168.18.193                                        │ 192.168.18.178
          └──────────────── LAN server 192.168.18.0/24 ───────────┘
                                      │
                            ┌─────────┴─────────┐
                            │  BMC .200 / .119  │  ⚠️ IPMI satu segmen
                            └───────────────────┘
```

> Segmen `192.168.30.0/24` **tidak terjangkau** dari LAN klien maupun dari
> `proxmox` (`ip route get 192.168.30.2` keluar lewat gateway `.18.1` dan tidak
> sampai). Hanya `T4-Storage` dan `HPC-GPU` yang punya kaki di sana.

---

## 5. Inventaris Disk

**41 disk fisik, total raw ± 424,6 TB.** Semua terhubung lewat **SAS expander**
di `pci-0000:42:00.0` (tiga expander: `0x500cc1000018b8bf`,
`0x500cc100000e7dbf`, `0x500cc100000df1bf`).

### 5.1 Rekapitulasi per model

| Model | Jumlah | Kapasitas/unit | Total | Kelas | Catatan |
|---|---|---|---|---|---|
| `WDC WUH721816ALE6L4` | 8 | 16 TB | 128,0 TB | 🟢 Ultrastar DC (enterprise) | Kandidat anggota `md127` |
| `ST8000DM004-2U9188` | 14 | 8 TB | 112,0 TB | 🔴 **BarraCuda desktop, SMR** | Lihat peringatan di bawah |
| `WDC WUH722020BLE6L4` | 3 | 20 TB | 60,0 TB | 🟢 Ultrastar DC | |
| `OOS12000G` | 3 | 12 TB | 36,0 TB | 🟡 OEM/generic | Model sama dipakai `proxmox` |
| `WDC WUH721818ALE6L4` / `ALN604` | 3 | 18 TB | 54,0 TB | 🟢 Ultrastar DC | Penamaan model tidak seragam |
| `MidasForce SSD 4TB` | 3 | 4 TB | 12,0 TB | 🟡 SSD merek tidak umum | |
| `MidasForce SSD 2TB` | 3 | 2 TB | 6,0 TB | 🟡 SSD merek tidak umum | |
| `WDC WD80EAAZ-00BXBB0` | 1 | 8 TB | 8,0 TB | 🟡 WD desktop | |
| `PNY CS900 4TB SSD` | 1 | 4 TB | 4,0 TB | 🟡 SSD konsumer | |
| `WDC WD5000AVCS-632DY1` | 1 | 500 GB | 0,5 TB | 🔴 **WD AV-GP** (drive CCTV era 2010) | 27.805 jam, 1 pending sector |
| `SPCC M.2 PCIe SSD` | 1 | 512 GB | 0,5 TB | 🔴 SSD konsumer | **Disk boot — tanpa redundansi** |
| **TOTAL** | **41** | — | **± 424,6 TB** | | |

> 🔴 **14 disk `ST8000DM004` adalah Seagate BarraCuda 3.5" — drive desktop
> ber-teknologi SMR (Shingled Magnetic Recording).** SMR sangat buruk untuk
> array paritas: rebuild bisa berjalan berhari-hari dan justru sering memicu
> kegagalan disk berikutnya di tengah rebuild. Ini populasi disk terbesar di
> node ini (112 TB) dan **salah satunya sudah SMART FAILED**.

> 🔴 **Populasi disk sangat heterogen** — 11 model berbeda, campuran enterprise
> (Ultrastar DC) dengan desktop/konsumer (BarraCuda, WD AV-GP, PNY, MidasForce).
> Konsekuensinya karakteristik timeout, TLER/ERC, dan perilaku error tidak
> seragam, sehingga perilaku array sulit diprediksi saat ada disk bermasalah.

### 5.2 Disk dengan atribut SMART bermasalah

| Device | Model | Serial | Power-On | Realloc (5) | Pending (197) | Offline Uncorr (198) | Reported Uncorr (187) | SMART |
|---|---|---|---|---|---|---|---|---|
| **`/dev/sdj`** | Seagate BarraCuda `ST8000DM004-2U9188` | **`ZR15WNCX`** | 9.039 jam (± 1,0 thn) | **258.448** *(ambang 10)* | **3.608** | **3.608** | 1 | 🔴 **FAILED** |
| `/dev/sdv` | `WDC WD5000AVCS-632DY1` (AV-GP 500 GB) | `WD-WCAV9DL77050` | **27.805 jam** (± 3,2 thn) | 0 | **1** | 0 | 0 | 🟡 PASSED |
| 39 disk lainnya | — | — | — | 0 | 0 | 0 | 0 | 🟢 PASSED |

Suhu seluruh disk sehat saat pendataan: **29–32 °C** (tertinggi `nvme0` 32 °C).

> 🔴 **`/dev/sdj` sudah melewati ambang pre-fail.** Nilai ternormalisasi atribut 5
> adalah **1** dengan ambang **10** — inilah yang membuat SMART overall
> `FAILED`. 3.608 sektor pending **dan** 3.608 offline-uncorrectable berarti
> data di sektor-sektor itu **sudah tidak terbaca**. Disk ini harus diganti
> **sebelum** ada disk lain bermasalah di array yang sama.
>
> `mdadm` sendiri **belum** menandainya gagal (`node_md_disks{state="failed"} = 0`)
> karena drive masih merespons perintah. Jangan menunggu sampai mdadm yang
> menyadarinya.

### 5.3 Langkah verifikasi (butuh SSH — belum bisa dilakukan)

```bash
# Disk sdj ada di array yang mana?
cat /proc/mdstat
mdadm --detail /dev/md126 /dev/md127
zpool status bio-pool

# Konfirmasi kondisi sdj
sudo smartctl -a /dev/sdj
sudo smartctl -l selftest /dev/sdj

# Peta slot fisik sebelum mencabut — JANGAN cabut tanpa ini
lsblk -o NAME,SIZE,SERIAL,MODEL
ls -l /dev/disk/by-path/ | grep sdj
sudo ledctl locate=/dev/sdj
```

---

## 6. Array & Pool

| Volume | Tipe | Disk | Kapasitas | Redundansi | Status | Mount |
|---|---|---|---|---|---|---|
| **`md127`** | mdadm | **7 aktif**, 0 gagal, 0 spare | **± 96,0 TB** | *(dugaan RAID5)* | 🟢 sinkron penuh | ⚠️ **tidak ter-mount** saat pendataan |
| **`md126`** | mdadm | **11 aktif**, 0 gagal, 0 spare | **± 80,0 TB** | *(dugaan RAID5)* | 🟢 sinkron penuh | ⚠️ **tidak ter-mount** saat pendataan |
| **`bio-pool`** | ZFS | *(isi)* | **21,73 TB** | *(isi — cek `zpool status`)* | 🟢 ONLINE | `/bio-pool` |
| `nvme0n1p3` | ext4 | 1 (`SPCC M.2`) | 471,5 GB | ❌ tidak ada | 🟢 | `/` |
| `/dev/loop0` | xfs | — | 226,6 GB | ❌ tidak ada | 🟢 | `/var/lib/docker` |

> **Dasar dugaan level RAID** (perlu dikonfirmasi dengan `cat /proc/mdstat`):
> - `md127` = 7 disk × 16 TB menghasilkan **96 TB** ⇒ 6 disk data + 1 paritas = **RAID5**.
>   Cocok dengan nama export `96-Storage` dan dengan populasi 8× disk 16 TB (7 terpakai, 1 sisa).
> - `md126` = 11 disk × 8 TB menghasilkan **80 TB** ⇒ 10 disk data + 1 paritas = **RAID5**.
>   Cocok dengan populasi 14× `ST8000DM004` (11 terpakai, 3 sisa).

> 🔴 **RAID5 hanya tahan 1 disk mati.** Kalau `md126` benar RAID5 di atas 11 disk
> SMR 8 TB, dan `/dev/sdj` adalah anggotanya, maka node ini sedang berjalan
> **tanpa margin sama sekali**: satu disk lagi bermasalah saat rebuild = **80 TB
> hilang**. Rebuild RAID5 SMR 11-disk realistis memakan **beberapa hari**.

> ⚠️ **`md126` dan `md127` tidak muncul di daftar filesystem ter-mount**, padahal
> `/media/t4/96-Storage` masih diekspor lewat NFS. Artinya ada kemungkinan
> **NFS mengekspor direktori kosong** — klien yang mount akan melihat direktori
> hampa alih-alih menerima error. Ini kemungkinan besar berkaitan dengan mount
> `HPC-GPU` yang `failed`, dan harus dicek segera.

---

## 7. Export NFS

Diverifikasi dengan `showmount -e 192.168.18.193` dari `proxmox` pada 2026-09-02:

| Path Export | Klien Diizinkan | Dipakai Untuk | Status |
|---|---|---|---|
| `/bio-pool` | `192.168.30.0/24` | `/media/bio-pool` di `HPC-GPU` (21,7 TB) | 🟢 **aktif & ter-mount** |
| `/media/t4/NVME-3.6TB` | `192.168.30.0/24` | `/media/t4-storage-nvme` di `HPC-GPU` | 🔴 mount `failed` di klien |
| `/media/t4/96-Storage` | `192.168.18.0/24` | `/mnt/t4-storage` di `HPC-GPU` | 🔴 mount `failed` di klien |

> 🔴 **Penyebab mount `/mnt/t4-storage` gagal sudah ditemukan.** `/etc/fstab` di
> `HPC-GPU` menunjuk ke **`192.168.18.113`**, sedangkan export
> `/media/t4/96-Storage` sekarang dilayani dari **`192.168.18.193`**. Alamat
> `.113` **tidak merespons ping maupun TCP** — IP node ini sudah berpindah
> `.113 → .193` dan referensi lama tidak ikut diperbarui. Perbaikan ada di
> [`hpc-gpu.md` §7.2](../hpc-nodes/hpc-gpu.md#72-yang-gagal-mount).

> ⚠️ **`/media/t4/96-Storage` diekspor ke seluruh `192.168.18.0/24`** — yaitu ke
> setiap host di LAN server, termasuk laptop dan workstation, bukan hanya ke
> node HPC. Persempit ke host yang benar-benar membutuhkan.

```bash
showmount -e 192.168.18.193
sudo exportfs -v
cat /etc/exports
```

---

## 8. Stack Monitoring (berjalan di node ini)

Node ini merangkap sebagai **server monitoring seluruh fleet**.

| Layanan | Port | Versi | Autentikasi | Status |
|---|---|---|---|---|
| **Prometheus** | `9090` | **2.52.0** (build 2024-05-08) | 🔴 **TIDAK ADA** | 🟢 jalan |
| **Grafana** | `3000` | **12.1.1** | 🟢 ada halaman login | 🟢 jalan (`database: ok`) |
| `node_exporter` | `9100` | — | 🔴 tidak ada | 🟢 jalan |
| `smartctl_exporter` | `9633` | — | 🔴 tidak ada | 🟢 jalan |
| `ipmi_exporter` | `9290` | — | 🔴 tidak ada | 🟢 jalan |
| NFS server | `2049` | NFSv4 | — | 🟢 jalan |
| Samba / SMB | `139`, `445` | *(isi)* | *(isi)* | 🟢 jalan |
| `rpcbind` | `111` | — | — | 🟢 jalan |
| SSH | `22` | `OpenSSH_8.9p1` | publickey + password | 🟢 jalan |

### 8.1 Seluruh target Prometheus sedang DOWN

| Job | Target | Peran | Health |
|---|---|---|---|
| `t4_storage_os` | `192.168.18.113:9100` | node_exporter | 🔴 **down** |
| `t4_storage_ipmi` | `192.168.18.113:9290` → BMC `192.168.18.200` | ipmi_exporter | 🔴 **down** |
| `smartctl` | `192.168.18.113:9633` | smartctl_exporter | 🔴 **down** |
| `t4_gpu_metrics` | `192.168.18.113:9400` | DCGM exporter | 🔴 **down** |

> 🔴 **Keempat job menunjuk ke `192.168.18.113` — IP lama node ini sendiri.**
> Exporter-nya sebenarnya hidup dan sehat, hanya saja di alamat **`.193`**.
> Akibatnya **monitoring seluruh fleet praktis mati sejak IP berpindah** —
> termasuk alarm SMART yang seharusnya meneriakkan `/dev/sdj`. Ini menjelaskan
> kenapa disk FAILED bisa lolos tanpa ketahuan.
>
> Perbaikan: ganti `192.168.18.113` → `192.168.18.193` di
> `/etc/prometheus/prometheus.yml`, lalu `systemctl reload prometheus`.

> **Job `t4_gpu_metrics` (DCGM, port 9400) menyiratkan node ini punya GPU NVIDIA** —
> konsisten dengan nama "T4" (NVIDIA Tesla T4). Belum terverifikasi; cek dengan
> `nvidia-smi` dan `lspci | grep -i nvidia` saat SSH tersedia.

---

## 9. Docker

`/var/lib/docker` berada di **`/dev/loop0`** (xfs, 226,6 GB) — bukan partisi asli,
melainkan **file image yang di-loop-mount**.

> ⚠️ Menaruh Docker di atas loop device menambah satu lapisan I/O dan membuat
> kapasitasnya sulit ditambah. Perlu dikonfirmasi apakah ini disengaja
> (mis. sisa instalasi `snap`) atau kecelakaan konfigurasi.

```bash
losetup -a
docker info | grep -E 'Storage Driver|Docker Root Dir'
docker ps -a
```

---

## 10. Yang Masih Kosong — Wajib Dilengkapi

Node ini **belum pernah didata lewat SSH**. Data berikut **tidak bisa** diambil
dari exporter dan harus dikumpulkan langsung dari dalam mesin:

| Kategori | Data yang belum ada | Perintah |
|---|---|---|
| CPU | Model, socket, NUMA, frekuensi | `lscpu` |
| RAM | Jumlah & posisi DIMM, channel terisi | `dmidecode -t memory` |
| Array | **Level RAID sebenarnya**, anggota tiap array, bitmap | `cat /proc/mdstat`, `mdadm --detail` |
| ZFS | Topologi `bio-pool`, `ashift`, ARC, riwayat scrub | `zpool status -v`, `arc_summary` |
| GPU | Ada/tidaknya GPU, model, driver | `nvidia-smi`, `lspci \| grep -i nvidia` |
| NFS | Isi `/etc/exports`, jumlah thread `nfsd` | `cat /etc/exports`, `cat /proc/fs/nfsd/threads` |
| SMB | Daftar share & hak akses | `testparm -s`, `smbstatus` |
| Snapshot | Kebijakan snapshot ZFS, ada/tidaknya sanoid | `zfs list -t snapshot`, `cat /etc/sanoid/sanoid.conf` |
| Backup | **Ada/tidaknya backup sama sekali** | — |
| MTU | MTU di `enp65s0f0` (harus 9000) | `ip -br link` |
| Akun | User dengan shell login, `sudo`, konfigurasi sshd | `getent passwd`, `sshd -T` |
| BMC | Firmware, MAC, akun, SEL | `ipmitool fru print`, `ipmitool sel elist` |

**Prasyarat:** kredensial SSH `T4-Storage` belum tersedia untuk admin repo ini.
Kunci publik admin (`~/.ssh/id_proxmox.pub`) sudah terpasang di `proxmox`, tapi
**belum** di node ini. Lihat [`docs/penginputan-node.md`](../../docs/penginputan-node.md).

---

## 11. Health Check Cepat

Sebelum SSH tersedia, kondisi node bisa dibaca **tanpa login** dari LAN server:

```bash
# Identitas, RAM, uptime
curl -s http://192.168.18.193:9100/metrics |
  grep -E '^node_(uname_info|dmi_info|boot_time_seconds|memory_MemTotal_bytes)'

# Semua disk yang SMART-nya tidak sehat  (nilai 0 = FAILED)
curl -s http://192.168.18.193:9633/metrics |
  awk '/^smartctl_device_smart_status/ && $NF==0'

# Sektor reallocated / pending / uncorrectable di seluruh disk
curl -s http://192.168.18.193:9633/metrics |
  grep -E 'attribute_id="(5|197|198)"' | grep 'value_type="raw"' | awk '$NF>0'

# Status array mdadm
curl -s http://192.168.18.193:9100/metrics |
  grep -E '^node_md_disks\{.*failed|^node_md_blocks'

# Export NFS (dari host mana pun di LAN server)
showmount -e 192.168.18.193
```

> Bahwa seluruh perintah di atas berjalan **tanpa autentikasi apa pun** adalah
> kemudahan bagi kita **dan** bagi siapa pun yang masuk ke LAN ini.
> Lihat `KI-T02` dan `KI-T07`.

---

## 12. Known Issues & Risiko

Diurutkan dari dampak paling besar. Semua temuan dari pendataan **2026-09-02**.

| ID | Temuan | Dampak | Prioritas |
|---|---|---|---|
| `KI-T01` | **`/dev/sdj` SMART FAILED** — 258.448 reallocated, 3.608 pending, 3.608 offline-uncorrectable | Jika ia anggota array RAID5, node berjalan tanpa margin. Satu disk lagi gagal = kehilangan seluruh array (80 TB) | 🔴 **Kritis** |
| `KI-T02` | **Kredensial IPMI bocor plaintext** di konfigurasi `ipmi_exporter`, terbaca lewat Prometheus `:9090` **tanpa autentikasi** dari seluruh LAN | Siapa pun di LAN dapat kendali penuh BMC: power off, mount media virtual, akses KVM — setara akses fisik ke server | 🔴 **Kritis** |
| `KI-T03` | **Monitoring mati total** — keempat job Prometheus menunjuk IP lama `.113` dan berstatus `down` | Tidak ada alarm apa pun. Inilah sebabnya `KI-T01` tidak ketahuan | 🔴 **Kritis** |
| `KI-T04` | **14 disk SMR desktop (`ST8000DM004`) dipakai di array paritas** | Rebuild berhari-hari dengan risiko tinggi memicu kegagalan berantai | 🔴 **Kritis** |
| `KI-T05` | **Belum diketahui adanya backup** untuk `bio-pool` maupun array mdadm | 21,7 TB data penelitian tanpa salinan yang terverifikasi | 🔴 **Kritis** *(perlu konfirmasi)* |
| `KI-T06` | **Disk boot `SPCC M.2` (SSD konsumer) tanpa redundansi** | Disk mati = node tidak bisa boot; storage & monitoring ikut turun | 🟠 Tinggi |
| `KI-T07` | **Prometheus + exporter terbuka tanpa autentikasi** di LAN | Seluruh inventaris hardware, serial disk, dan metrik terbaca siapa saja | 🟠 Tinggi |
| `KI-T08` | **IPMI (`.200`) satu segmen dengan LAN data**, tanpa VLAN terpisah | BMC terjangkau dari setiap host di LAN | 🟠 Tinggi |
| `KI-T09` | **SPOF ganda** — satu-satunya storage bersama **dan** satu-satunya server monitoring | Node turun = job HPC berhenti **dan** visibilitas hilang bersamaan | 🟠 Tinggi |
| `KI-T10` | **`md126` & `md127` tidak ter-mount** padahal `/media/t4/96-Storage` tetap diekspor | Klien NFS berpotensi mount direktori kosong tanpa pesan error | 🟠 Tinggi |
| `KI-T11` | **Perpindahan IP `.113 → .193` tidak terdokumentasi** — memutus `fstab` `HPC-GPU` dan seluruh job Prometheus | Kegagalan diam-diam di beberapa tempat sekaligus | 🟠 Tinggi |
| `KI-T12` | **Populasi disk sangat heterogen** (11 model, campur enterprise & konsumer) | Perilaku timeout/TLER tidak seragam; sulit menyiapkan spare | 🟡 Sedang |
| `KI-T13` | **BIOS 2.5 rilis 2022-09-08** (± 4 tahun) | Tertinggal perbaikan stabilitas & keamanan platform | 🟡 Sedang |
| `KI-T14` | **`eno2` nego di 100 Mb/s** padahal port gigabit | Indikasi kabel atau port switch bermasalah | 🟡 Sedang |
| `KI-T15` | **`/media/t4/96-Storage` diekspor ke seluruh `192.168.18.0/24`** | Cakupan akses jauh lebih luas dari kebutuhan | 🟡 Sedang |
| `KI-T16` | **Serial DMI `0123456789`**, asset tag `To be filled by O.E.M.` | Identitas aset tidak unik — sama persis dengan `proxmox` | 🟡 Sedang |
| `KI-T17` | **MTU jalur 10 GbE belum terverifikasi** (sisi `HPC-GPU` sudah 9000) | Ketidakcocokan MTU menyebabkan fragmentasi & throughput anjlok | 🟡 Sedang |
| `KI-T18` | **`/dev/sdv` (WD AV-GP 500 GB, 27.805 jam) punya 1 pending sector** | Drive CCTV berumur 3,2 tahun dipakai di server produksi | 🟡 Sedang |
| `KI-T19` | **Docker di atas loop device** (`/dev/loop0`) | Lapisan I/O ekstra, kapasitas sulit ditambah | 🟢 Rendah |
| `KI-T20` | **Tidak ada PTR/DNS**; hostname `t4-Super-Server` masih bawaan pabrik | Menyulitkan otomasi & pembacaan log | 🟢 Rendah |

---

## 13. Tindak Lanjut Berurutan

1. **Rotasi kredensial BMC `192.168.18.200` sekarang** (`KI-T02`), lalu keluarkan
   password dari `prometheus.yml` — gunakan file kredensial `ipmi_exporter`
   dengan permission `0600`, bukan parameter di URL.
2. **Perbaiki target Prometheus `.113 → .193`** (`KI-T03`) agar alarm hidup lagi.
3. **Tentukan lokasi `/dev/sdj`** (`cat /proc/mdstat`), siapkan disk pengganti
   **kelas enterprise CMR**, lalu jadwalkan penggantian (`KI-T01`).
4. **Verifikasi apakah `md126`/`md127` seharusnya ter-mount** (`KI-T10`) dan
   perbaiki `/etc/fstab` di `HPC-GPU` ke `.193` (`KI-T11`).
5. **Pasang kunci SSH admin** agar node ini bisa didata penuh (§10).
6. **Konfirmasi status backup `bio-pool`** (`KI-T05`) — ini menentukan seberapa
   gawat semua temuan di atas.

---

## 14. Riwayat Perubahan Node Ini

| Tanggal | Jenis | Ringkasan | Ref |
|---|---|---|---|
| *(sebelum 2026-08-28)* | Jaringan | IP manajemen berpindah `192.168.18.113` → `192.168.18.193`; referensi lama tidak diperbarui | `KI-T11` |
| 2026-08-26 09:59 | Operasional | Boot terakhir | — |
| 2026-09-02 | Dokumentasi | Node didata pertama kali (jarak jauh, tanpa SSH) | dokumen ini |

---

## 15. Lampiran — Gambar & Diagram

| Gambar | Path | Status |
|---|---|---|
| Foto rak | `../../assets/images/racks/t4-storage-rack.png` | *(belum ada)* |
| Peta bay disk | `../../assets/images/diagrams/t4-storage-disk-bay-map.png` | *(belum ada — penting untuk `KI-T01`)* |
| Topologi array | `../../assets/images/diagrams/t4-storage-array-topology.png` | *(belum ada)* |

Standar penamaan: [assets/images/README.md](../../assets/images/README.md).

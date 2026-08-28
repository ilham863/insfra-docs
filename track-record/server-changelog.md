# Server Changelog — Perubahan Infrastruktur Permanen

Log seluruh perubahan **permanen** pada hardware, sistem operasi, dan konfigurasi
jaringan/keamanan di infrastruktur bare-metal.

> **Terakhir Diperbarui:** 2026-08-28
>
> **Beda dengan dokumen lain:**
> - File ini = **apa yang berubah secara permanen** pada server (hardware, OS, network).
> - [`maintenance-log.md`](maintenance-log.md) = **bagaimana pekerjaannya dilaksanakan** (jendela, checklist, rollback).
> - [`../CHANGELOG.md`](../CHANGELOG.md) = perubahan **dokumen** di repo ini.
>
> Satu pekerjaan bisa muncul di dua tempat: `MNT-2026-005` (cara kerjanya)
> dan `SCL-2026-004` (hasil perubahan permanennya).

---

## Format ID

```
SCL-<TAHUN>-<NOMOR URUT 3 DIGIT>
Contoh: SCL-2026-007
```

## Kategori Perubahan

| Kode | Kategori | Contoh |
|---|---|---|
| `HW-CPU` | Prosesor | Tambah/ganti CPU, ubah setting SMT/NUMA di BIOS |
| `HW-RAM` | Memori | Tambah/ganti/lepas DIMM |
| `HW-DISK` | Penyimpanan | Tambah/ganti HDD/SSD/NVMe, ubah topologi RAID/ZFS |
| `HW-GPU` | Akselerator | Tambah/ganti/lepas GPU |
| `HW-NIC` | Jaringan fisik | Ganti kartu jaringan, transceiver, kabel DAC/fiber |
| `HW-PSU` | Daya | Ganti PSU, pindah jalur PDU |
| `HW-OTHER` | Lainnya | Fan, backplane, riser, HBA, baterai CMOS |
| `FW-BIOS` | Firmware sistem | BIOS/UEFI |
| `FW-BMC` | Firmware manajemen | iDRAC/IPMI/BMC |
| `FW-DEV` | Firmware perangkat | HBA, NIC, disk, GPU VBIOS |
| `OS-MAJOR` | Upgrade OS mayor | Rocky 9.3 → 9.4, Debian 11 → 12, PVE 8.1 → 8.2 |
| `OS-KERNEL` | Kernel | Upgrade/pin/patch kernel |
| `OS-DRIVER` | Driver | NVIDIA, mpt3sas, ZFS module |
| `NET-CONFIG` | Konfigurasi jaringan | Bonding, VLAN, bridge, MTU, IP |
| `NET-FIREWALL` | Aturan firewall | Buka/tutup port, ubah policy |
| `SEC-CHANGE` | Keamanan | SELinux, 2FA, rotasi kredensial, kebijakan SSH |
| `SVC-CONFIG` | Konfigurasi layanan | slurm.conf, exports, smb.conf, storage.cfg |
| `NODE-ADD` | Node baru masuk produksi | — |
| `NODE-REMOVE` | Node ditarik dari produksi | Decommission |

## Kolom Wajib per Entri

Setiap entri **harus** menjawab: kapan, node mana, apa yang berubah,
dari nilai apa ke nilai apa, kenapa, siapa, dan apa dampaknya.

---

## TEMPLATE ENTRI (copy blok ini)

````markdown
### SCL-YYYY-NNN — <Judul Singkat>

| Field | Isi |
|---|---|
| **ID** | `SCL-YYYY-NNN` |
| **Tanggal Efektif** | `YYYY-MM-DD` |
| **Node Terdampak** | `hostname` (Asset Tag `AST-XXX`) |
| **Kategori** | `HW-RAM` / `OS-MAJOR` / ... |
| **Tiket Maintenance Terkait** | `MNT-YYYY-NNN` |
| **PIC** | Nama |
| **Disetujui Oleh** | Nama |
| **Reversibel?** | Ya / Tidak / Sebagian |

**Perubahan:**

| Item | Sebelum | Sesudah |
|---|---|---|
| ... | ... | ... |

**Alasan:**
...

**Dampak pada operasional:**
- ...

**Dokumen yang ikut diperbarui:**
- [ ] `inventory/<path>/<node>.md`
- [ ] `README.md` (jika mengubah mapping storage / index node)
- [ ] `docs/sop/...` (jika mengubah cara kerja user)
- [ ] `CHANGELOG.md`

**Verifikasi:**
```
<perintah + output singkat yang membuktikan perubahan berhasil>
```

**Catatan:**
...
````

---

## Index Perubahan (terbaru di atas)

| ID | Tanggal | Node | Kategori | Ringkasan | MNT Terkait |
|---|---|---|---|---|---|
| `SCL-2026-007` | 2026-06-22 | `hpc-node-01` | `HW-NIC`, `NET-CONFIG` | 10GbE → dual 25GbE LACP, MTU 9000 | `MNT-2026-011` |
| `SCL-2026-006` | 2026-06-14 | `storage-node-01` | `OS-DRIVER` | OpenZFS 2.1.15 → 2.2.4, `autotrim=on` | `MNT-2026-010` |
| `SCL-2026-005` | 2026-05-06 | `proxmox-node-01` | `SEC-CHANGE` | Aktifkan TOTP 2FA, firewall `policy_in DROP` | `MNT-2026-009` |
| `SCL-2026-004` | 2026-03-14 | `hpc-node-01` | `HW-DISK` | Ganti NVMe scratch Bay 1 (wear 84%) | `MNT-2026-005` |
| `SCL-2026-003` | 2026-03-09 | `storage-node-01` | `HW-DISK` | Ganti HDD Bay 7 (pending sector) | `MNT-2026-004` |
| `SCL-2026-002` | 2026-02-11 | `proxmox-node-01` | `HW-DISK` | Tambah `vmdata` mirror-1, 3.45 → 6.9 TB usable | `MNT-2026-003` |
| `SCL-2025-016` | 2025-11-03 | `storage-node-01` | `HW-NIC`, `NET-CONFIG` | 10GbE → dual 25GbE, `nfsd` 64 → 128 thread | `MNT-2025-018` |
| `SCL-2025-014` | 2025-10-14 | `proxmox-node-01` | `OS-MAJOR` | Proxmox VE 8.1 → 8.2, kernel 6.5 → 6.8 | `MNT-2025-016` |
| `SCL-2025-011` | 2025-09-30 | `hpc-node-01` | `OS-MAJOR`, `OS-KERNEL` | Rocky 9.3 → 9.4, kernel 5.14.0-362 → -427 | `MNT-2025-014` |
| `SCL-2025-008` | 2025-06-30 | `proxmox-node-01` | `HW-NIC`, `NET-CONFIG` | Tambah dual 25GbE, `vmbr1` VLAN-aware | `MNT-2025-011` |
| `SCL-2025-004` | 2025-03-22 | `storage-node-01` | `HW-DISK` | Tambah special vdev mirror 2× NVMe 1.92 TB | `MNT-2025-006` |
| `SCL-2025-003` | 2025-02-08 | `hpc-node-01` | `HW-RAM` | RAM 512 GB → 1 TB | `MNT-2025-004` |
| `SCL-2025-002` | 2025-01-27 | `proxmox-node-01` | `HW-RAM` | RAM 256 GB → 512 GB | `MNT-2025-002` |
| `SCL-2024-018` | 2024-12-05 | `storage-node-01` | `HW-DISK` | Tambah vdev `raidz2-2`, 288 → 432 TB raw | `MNT-2024-016` |
| `SCL-2024-011` | 2024-08-19 | `proxmox-node-01` | `SVC-CONFIG` | Deploy VM `101 gitlab-server`, `103 monitoring` | — |
| `SCL-2024-003` | 2024-05-02 | `proxmox-node-01` | `NODE-ADD` | Go-live Proxmox VE 8.1 | — |
| `SCL-2024-002` | 2024-06-18 | `storage-node-01` | `NODE-ADD` | Go-live pool `tank` 2× raidz2 | — |
| `SCL-2024-001` | 2024-07-02 | `hpc-node-01` | `NODE-ADD` | Go-live Rocky Linux 9.3, Slurm 23.02 | — |

---

## Riwayat Lengkap

### SCL-2026-007 — Upgrade Jaringan hpc-node-01 ke Dual 25GbE LACP

| Field | Isi |
|---|---|
| **ID** | `SCL-2026-007` |
| **Tanggal Efektif** | `2026-06-22` |
| **Node Terdampak** | `hpc-node-01` (Asset Tag `AST-HPC-2024-0001`) |
| **Kategori** | `HW-NIC`, `NET-CONFIG` |
| **Tiket Maintenance Terkait** | `MNT-2026-011` |
| **PIC** | *(isi)* |
| **Disetujui Oleh** | *(isi)* |
| **Reversibel?** | Ya (kartu 10GbE lama disimpan sebagai spare) |

**Perubahan:**

| Item | Sebelum | Sesudah |
|---|---|---|
| Kartu jaringan data | 1× Intel X710 10GbE (`eno2`) | 1× Mellanox ConnectX-6 dual 25GbE (`ens1f0`, `ens1f1`) |
| Bonding | Tidak ada | `bond0`, LACP 802.3ad, `xmit_hash_policy=layer3+4` |
| Bandwidth data | 10 Gbps | **50 Gbps agregat** |
| MTU jalur data | 1500 | **9000** |
| IP data | `10.10.20.11/24` di `eno2` | `10.10.20.11/24` di `bond0` |
| Port switch | `SW-DATA-01 : Eth1/11` | `SW-DATA-01 : Eth1/11` + `SW-DATA-02 : Eth1/11`, LACP `po11` |
| Redundansi jalur | Tidak ada | Ada (dual switch) |
| Opsi mount NFS | `rsize/wsize=262144` | `rsize/wsize=1048576`, `nconnect=8` |

**Alasan:**

Throughput baca dari `/mnt/storage` terbatas di ± 1.1 GB/s (praktis batas 10GbE),
padahal `storage-node-01` mampu melayani 2.7 GB/s. Tahap *stage-in* data mentah
(memindahkan FASTQ dari `/mnt/storage/raw` ke `/scratch`) memakan 35–50 menit
untuk sampel WGS 120 GB — sekitar 18% dari total waktu pipeline hanya untuk
menyalin data.

**Dampak pada operasional:**
- Waktu stage-in sampel WGS 120 GB turun dari ± 42 menit → **± 11 menit**.
- Kegagalan satu switch tidak lagi memutus akses node ke storage.
- Jumbo frame wajib konsisten end-to-end; jika ada perangkat di jalur yang
  tidak mendukung MTU 9000, koneksi akan gagal secara senyap (paket besar di-drop).
  Ini dicatat sebagai risiko konfigurasi baru.

**Dokumen yang ikut diperbarui:**
- [x] `inventory/hpc-nodes/hpc-node-01.md` (tabel jaringan, mount NFS, riwayat)
- [x] `README.md` (diagram arsitektur — label 25GbE)
- [ ] `docs/sop/...` (tidak berubah)
- [x] `CHANGELOG.md`

**Verifikasi:**
```
$ cat /proc/net/bonding/bond0 | grep -E 'Bonding Mode|MII Status|Slave Interface'
Bonding Mode: IEEE 802.3ad Dynamic link aggregation
MII Status: up
Slave Interface: ens1f0
MII Status: up
Slave Interface: ens1f1
MII Status: up

$ ip -br addr show bond0
bond0  UP  10.10.20.11/24

$ ip link show bond0 | grep mtu
2: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 9000

$ ping -M do -s 8972 -c 3 10.10.20.50
3 packets transmitted, 3 received, 0% packet loss

$ iperf3 -c 10.10.20.50 -P 8 -t 30 | tail -3
[SUM]   0.00-30.00  sec   162 GBytes  46.4 Gbits/sec   sender
```

**Catatan:**
Kartu 10GbE lama disimpan di lemari spare, dilabeli `SPARE-NIC-10G-01`.
Konfigurasi switch (LACP port-channel) dilakukan oleh tim jaringan;
konfigurasi tersimpan di repo jaringan terpisah.

---

### SCL-2026-006 — Upgrade OpenZFS 2.1.15 → 2.2.4 di storage-node-01

| Field | Isi |
|---|---|
| **ID** | `SCL-2026-006` |
| **Tanggal Efektif** | `2026-06-14` |
| **Node Terdampak** | `storage-node-01` (Asset Tag `AST-STG-2024-0001`) |
| **Kategori** | `OS-DRIVER` |
| **Tiket Maintenance Terkait** | `MNT-2026-010` |
| **PIC** | *(isi)* |
| **Disetujui Oleh** | *(isi)* |
| **Reversibel?** | **Sebagian** — modul bisa di-downgrade, tetapi *feature flag* pool yang sudah diaktifkan tidak bisa dinonaktifkan |

**Perubahan:**

| Item | Sebelum | Sesudah |
|---|---|---|
| Versi OpenZFS | `2.1.15` | `2.2.4` |
| `autotrim` pada `tank` | `off` | `on` |
| Feature flag baru diaktifkan | — | `block_cloning` (tidak dipakai), `head_errlog`, `vdev_zaps_v2` |
| ARC max | 384 GiB | 384 GiB (tidak berubah) |

**Alasan:**

1. OpenZFS 2.1.x memasuki fase maintenance; 2.2.x adalah rilis stabil yang didukung.
2. Perbaikan performa untuk beban file besar sekuensial yang persis cocok dengan
   pola akses BAM/CRAM.
3. `head_errlog` memberi pelaporan error per-dataset, memudahkan menemukan
   proyek mana yang terdampak jika terjadi checksum error.
4. Special vdev NVMe perlu `autotrim` agar performanya tidak menurun seiring waktu.

**Dampak pada operasional:**
- Downtime NFS ± 25 menit (reboot untuk memuat modul kernel baru).
- Semua node HPC dengan mount `hard` akan hang sementara lalu pulih otomatis —
  tidak ada job yang perlu dibunuh, tetapi node tetap di-drain untuk aman.
- **Feature flag tidak bisa dibalik.** Setelah `zpool upgrade`, pool tidak dapat
  di-import oleh OpenZFS 2.1.x. Ini keputusan satu arah dan sudah disetujui.
- `block_cloning` sengaja **tidak** dimanfaatkan — pada 2.2.0–2.2.1 ada bug
  korupsi data terkait fitur ini; kami menunggu 2.2.4 yang sudah memuat perbaikannya
  dan tetap tidak mengandalkan fitur tersebut.

**Dokumen yang ikut diperbarui:**
- [x] `inventory/storage-nodes/storage-node-01.md` (versi ZFS, `autotrim`, riwayat)
- [ ] `README.md` (tidak berubah)
- [x] `CHANGELOG.md`

**Verifikasi:**
```
$ zfs version
zfs-2.2.4-1
zfs-kmod-2.2.4-1

$ zpool get autotrim tank
NAME  PROPERTY  VALUE     SOURCE
tank  autotrim  on        local

$ zpool status tank | head -5
  pool: tank
 state: ONLINE
  scan: scrub repaired 0B in 1 days 08:11:44 with 0 errors on Sun Jun  7 08:11:45 2026

$ zpool upgrade tank
This system supports ZFS pool feature flags.
Pool 'tank' already has all supported and requested features enabled.
```

**Catatan:**
Snapshot rekursif `tank@pre-SCL-2026-006` dibuat sebelum upgrade dan disimpan
selama 30 hari. Upgrade diuji lebih dulu di pool test pada VM `108 test-sandbox`
selama 2 minggu tanpa masalah.

---

### SCL-2026-005 — Pengetatan Keamanan proxmox-node-01

| Field | Isi |
|---|---|
| **ID** | `SCL-2026-005` |
| **Tanggal Efektif** | `2026-05-06` |
| **Node Terdampak** | `proxmox-node-01` (Asset Tag `AST-PVE-2024-0001`) |
| **Kategori** | `SEC-CHANGE`, `NET-FIREWALL` |
| **Tiket Maintenance Terkait** | `MNT-2026-009` |
| **PIC** | *(isi)* |
| **Disetujui Oleh** | *(isi)* |
| **Reversibel?** | Ya |

**Perubahan:**

| Item | Sebelum | Sesudah |
|---|---|---|
| Firewall datacenter | Nonaktif | **Aktif** |
| `policy_in` | `ACCEPT` | **`DROP`** |
| Akses Web UI :8006 | Semua sumber | Hanya `10.10.10.0/24` |
| Akses SSH :22 | Semua sumber | Hanya `10.10.10.0/24`, key-based only |
| `PermitRootLogin` | `yes` | `prohibit-password` |
| 2FA akun admin | Tidak ada | **TOTP wajib** untuk `root@pam` dan `sysadmin@pve` |
| Akun audit | Tidak ada | `readonly@pve` dengan role `PVEAuditor` |
| Sertifikat Web UI | Self-signed | CA internal (`hpc.local`) |

**Alasan:**

Audit keamanan internal menemukan Proxmox Web UI dapat diakses dari seluruh
jaringan kampus, dan login root berbasis password masih aktif. Node ini
menyimpan `vaultwarden` (password manager berisi kredensial IPMI seluruh cluster),
sehingga kompromi di sini setara dengan kompromi seluruh infrastruktur.

**Dampak pada operasional:**
- Admin harus mengakses Web UI dari jaringan manajemen (VLAN 10) atau melalui
  jump host — tidak bisa lagi langsung dari laptop di jaringan kantor.
- Perangkat TOTP wajib didaftarkan sebelum perubahan diterapkan; kode pemulihan
  dicetak dan disimpan di brankas fisik.
- **Risiko lockout:** jika perangkat TOTP hilang dan kode pemulihan tidak tersedia,
  akses hanya bisa dipulihkan lewat konsol fisik/iDRAC. Prosedur pemulihan
  didokumentasikan dan diuji pada hari yang sama.

**Dokumen yang ikut diperbarui:**
- [x] `inventory/proxmox-nodes/proxmox-node-01.md` (bagian Firewall & Keamanan)
- [x] `README.md` (aturan keamanan konten)
- [x] `CHANGELOG.md` (kategori `Security`)

**Verifikasi:**
```
$ pve-firewall status
Status: enabled/running

$ grep -E 'policy_in|policy_out' /etc/pve/firewall/cluster.fw
policy_in: DROP
policy_out: ACCEPT

$ grep PermitRootLogin /etc/ssh/sshd_config
PermitRootLogin prohibit-password

$ pveum user list
root@pam
sysadmin@pve
readonly@pve
```

**Catatan:**
Kode pemulihan TOTP dicetak dan disimpan di brankas ruang server, amplop tersegel,
dilabeli `PVE-01 TOTP RECOVERY 2026-05-06`. Diuji sekali pada 2026-05-06 pukul 15:00
lalu amplop disegel ulang.

---

### SCL-2026-004 — Penggantian NVMe Scratch hpc-node-01

| Field | Isi |
|---|---|
| **ID** | `SCL-2026-004` |
| **Tanggal Efektif** | `2026-03-14` |
| **Node Terdampak** | `hpc-node-01` (Asset Tag `AST-HPC-2024-0001`) |
| **Kategori** | `HW-DISK` |
| **Tiket Maintenance Terkait** | `MNT-2026-005` |
| **PIC** | *(isi)* |
| **Disetujui Oleh** | *(isi)* |
| **Reversibel?** | Tidak (disk lama dikirim RMA) |

**Perubahan:**

| Item | Sebelum | Sesudah |
|---|---|---|
| NVMe Front Bay 1 | Samsung PM9A3 3.84 TB, serial `SN-D0004-OLD`, wear **84%** | Samsung PM9A3 3.84 TB, serial `SN-D0004`, wear **0%** |
| Array `/dev/md1` | RAID0, dibuat 2024-07-02 | RAID0, dibuat ulang 2026-03-14 |
| Filesystem `/scratch` | XFS, isi 4.2 TB | XFS baru, kosong |
| Throughput tulis | 8.0 GB/s | 8.1 GB/s |

**Alasan:**

Endurance NVMe mencapai 84%, melewati ambang perencanaan internal 80%.
Karena `/scratch` berbasis RAID0, kegagalan satu disk menghapus seluruh 7 TB
dan membunuh setiap job yang sedang menulis ke sana. Penggantian dilakukan
terjadwal, bukan reaktif.

**Dampak pada operasional:**
- Seluruh isi `/scratch` di node ini dihapus — sesuai kebijakan, `/scratch`
  tidak pernah dibackup dan user diberi tahu H-4, H-2, H-1.
- Node offline 1 jam 40 menit; job diarahkan ke node lain oleh Slurm.
- Kebijakan notifikasi diperketat setelah kejadian ini (lihat `MNT-2026-005` bagian L).

**Dokumen yang ikut diperbarui:**
- [x] `inventory/hpc-nodes/hpc-node-01.md` (tabel disk, kesehatan NVMe, riwayat)
- [ ] `README.md` (tidak berubah — kapasitas `/scratch` tetap 7 TB)
- [x] `CHANGELOG.md`

**Verifikasi:**
```
$ nvme list | grep -i pm9a3
/dev/nvme2n1  SN-D0003  SAMSUNG MZQL23T8HCLS  3.84 TB
/dev/nvme3n1  SN-D0004  SAMSUNG MZQL23T8HCLS  3.84 TB

$ nvme smart-log /dev/nvme3n1 | grep -E 'percentage_used|media_errors'
percentage_used   : 0%
media_errors      : 0

$ cat /proc/mdstat
md1 : active raid0 nvme2n1[0] nvme3n1[1]
      7501476864 blocks super 1.2 512k chunks

$ df -hT /scratch
/dev/md1  xfs  7.0T  68M  7.0T  1% /scratch
```

**Catatan:**
Disk lama dikirim RMA, nomor resi `RMA-2026-0312`. Setelah insiden ini,
ditambahkan alarm Prometheus baru: `nvme_percentage_used > 70` sebagai peringatan
dini agar penggantian bisa dipesan jauh sebelum menyentuh 80%.

---

### SCL-2026-002 — Ekspansi Datastore vmdata proxmox-node-01

| Field | Isi |
|---|---|
| **ID** | `SCL-2026-002` |
| **Tanggal Efektif** | `2026-02-11` |
| **Node Terdampak** | `proxmox-node-01` (Asset Tag `AST-PVE-2024-0001`) |
| **Kategori** | `HW-DISK` |
| **Tiket Maintenance Terkait** | `MNT-2026-003` |
| **PIC** | *(isi)* |
| **Disetujui Oleh** | *(isi)* |
| **Reversibel?** | Tidak (vdev tidak dapat dilepas dari pool ZFS tanpa membangun ulang) |

**Perubahan:**

| Item | Sebelum | Sesudah |
|---|---|---|
| Perangkat pool `vmdata` | 2× Samsung PM9A3 3.84 TB (mirror-0) | 4× Samsung PM9A3 3.84 TB (mirror-0 + mirror-1) |
| Kapasitas raw | 7.68 TB | 15.36 TB |
| Kapasitas usable | 3.45 TB | **6.9 TB** |
| IOPS acak (baca 4K) | ± 620.000 | ± 1.180.000 |
| Serial disk baru | — | `V003`, `V004` |

**Alasan:**

Pool `vmdata` mencapai 78% terisi setelah penambahan VM `107 jupyterhub`.
ZFS mulai kehilangan performa di atas 80%, dan masih ada rencana menambah
dua VM layanan lagi tahun ini.

**Dampak pada operasional:**
- Menambahkan vdev mirror kedua **tidak** menyeimbangkan ulang data yang sudah ada.
  Data lama tetap berada di mirror-0; hanya penulisan baru yang tersebar ke keduanya.
  Distribusi akan merata seiring waktu, atau bisa dipercepat dengan
  `zfs send/recv` per dataset bila diperlukan.
- Tidak ada downtime — disk U.2 hot-swap, `zpool add` dilakukan online.

**Dokumen yang ikut diperbarui:**
- [x] `inventory/proxmox-nodes/proxmox-node-01.md` (topologi pool, kapasitas, riwayat)
- [ ] `README.md` (tidak berubah)
- [x] `CHANGELOG.md`

**Verifikasi:**
```
$ zpool status vmdata
  pool: vmdata
 state: ONLINE
config:
        NAME                                  STATE     READ WRITE CKSUM
        vmdata                                ONLINE       0     0     0
          mirror-0                            ONLINE       0     0     0
            nvme-SAMSUNG_MZQL23T8HCLS_V001    ONLINE       0     0     0
            nvme-SAMSUNG_MZQL23T8HCLS_V002    ONLINE       0     0     0
          mirror-1                            ONLINE       0     0     0
            nvme-SAMSUNG_MZQL23T8HCLS_V003    ONLINE       0     0     0
            nvme-SAMSUNG_MZQL23T8HCLS_V004    ONLINE       0     0     0

$ zpool list vmdata
NAME     SIZE  ALLOC   FREE  FRAG    CAP  HEALTH
vmdata  13.9T  2.40T  11.5T    8%    17%  ONLINE

$ pvesm status | grep vmdata
vmdata   zfspool   active   7340032000   2516582400   4823449600   34.28%
```

**Catatan:**
Perintah yang dijalankan: `zpool add vmdata mirror nvme-..._V003 nvme-..._V004`.
Perhatikan penggunaan kata kunci `mirror` — tanpa itu, ZFS akan menambahkan
kedua disk sebagai vdev *stripe* tunggal tanpa redundansi, dan kesalahan itu
tidak dapat dibatalkan. Perintah selalu diuji dengan `-n` (dry run) lebih dulu.

---

### SCL-2025-003 — Upgrade RAM hpc-node-01 dari 512 GB ke 1 TB

| Field | Isi |
|---|---|
| **ID** | `SCL-2025-003` |
| **Tanggal Efektif** | `2025-02-08` |
| **Node Terdampak** | `hpc-node-01` (Asset Tag `AST-HPC-2024-0001`) |
| **Kategori** | `HW-RAM`, `SVC-CONFIG` |
| **Tiket Maintenance Terkait** | `MNT-2025-004` |
| **PIC** | *(isi)* |
| **Disetujui Oleh** | *(isi)* |
| **Reversibel?** | Ya |

**Perubahan:**

| Item | Sebelum | Sesudah |
|---|---|---|
| Total RAM | 512 GB (8× 64 GB) | **1.024 GB (16× 64 GB)** |
| Slot terisi | A1–A4, B1–B4 | A1–A8, B1–B8 |
| Distribusi NUMA | 256 GB per node | 512 GB per node |
| Channel terisi per socket | 4 dari 12 | 8 dari 12 |
| Slurm `RealMemory` | `480000` MB | **`992000`** MB |
| Batas QoS `MaxMemPerJob` | 460 GB | **960 GB** |
| Bandwidth memori terukur | ± 310 GB/s | ± 560 GB/s |

**Alasan:**

Tiga job assembly (SPAdes pada dataset metagenomik) gagal dengan OOM dalam
satu bulan, masing-masing membutuhkan ± 600 GB RAM. Selain itu pembangunan
index STAR untuk genom besar membutuhkan > 500 GB. Menaikkan jumlah channel
terisi dari 4 menjadi 8 per socket juga menaikkan bandwidth memori hampir dua kali —
manfaat sekunder yang signifikan untuk beban alignment.

**Dampak pada operasional:**
- Job assembly besar kini bisa berjalan di node ini tanpa OOM.
- `RealMemory` di `slurm.conf` **harus** diperbarui bersamaan; jika tidak, Slurm
  tetap membatasi job pada nilai lama dan upgrade tidak terasa manfaatnya.
- 32 GB tetap dicadangkan untuk OS dan cache — tidak dialokasikan ke job.
- 8 slot DIMM masih kosong; ekspansi ke 1,5 TB masih mungkin.

**Dokumen yang ikut diperbarui:**
- [x] `inventory/hpc-nodes/hpc-node-01.md` (bagian Memory, layout DIMM, konfigurasi Slurm, riwayat)
- [x] `README.md` (tidak berubah struktural, hanya index node)
- [x] `docs/sop/sop-bioinformatics-execution.md` (contoh batas `--mem` diperbarui)
- [x] `CHANGELOG.md`

**Verifikasi:**
```
$ free -h
               total        used        free      shared  buff/cache   available
Mem:           1.0Ti        18Gi       912Gi       1.2Gi        94Gi       988Gi

$ dmidecode -t 17 | grep -c "Size: 64 GB"
16

$ numactl --hardware | grep size
node 0 size: 515842 MB
node 1 size: 516096 MB

$ scontrol show node hpc-node-01 | grep RealMemory
   RealMemory=992000 AllocMem=0 FreeMem=934112 Sockets=2 Boards=1
```

**Catatan:**
Delapan DIMM baru berasal dari batch dan part number yang sama dengan yang lama
(`MTC40F2046S1RC48BA1`) untuk menghindari masalah kompatibilitas kecepatan.
Setelah pemasangan, dijalankan `memtester` selama 6 jam pada 900 GB dan
`stream` benchmark — keduanya bersih. Monitoring ECC via `rasdaemon` dipantau
ketat selama 2 minggu pertama, 0 correctable error.

---

### SCL-2024-018 — Ekspansi Pool tank dengan vdev raidz2-2

| Field | Isi |
|---|---|
| **ID** | `SCL-2024-018` |
| **Tanggal Efektif** | `2024-12-05` |
| **Node Terdampak** | `storage-node-01` (Asset Tag `AST-STG-2024-0001`) |
| **Kategori** | `HW-DISK` |
| **Tiket Maintenance Terkait** | `MNT-2024-016` |
| **PIC** | *(isi)* |
| **Disetujui Oleh** | *(isi)* |
| **Reversibel?** | **Tidak** — vdev tidak dapat dilepas dari pool raidz |

**Perubahan:**

| Item | Sebelum | Sesudah |
|---|---|---|
| Jumlah vdev data | 2× raidz2 (16 disk) | **3× raidz2 (24 disk)** |
| Bay terisi | 0–15 | 0–23 |
| Kapasitas raw | 288 TB | **432 TB** |
| Kapasitas usable | ± 130 TB | **± 200 TB** |
| Hot spare | 1 disk | **2 disk** (bay 32, 33) |
| Pemakaian pool saat itu | 84% (kritis) | 56% |

**Alasan:**

Pool mencapai 84% terisi — melewati ambang 80% di mana ZFS beralih ke alokasi
first-fit dan performa tulis anjlok. Tiga proyek WGS baru dijadwalkan masuk
kuartal berikutnya dengan estimasi kebutuhan 45 TB.

**Dampak pada operasional:**
- Tidak ada downtime; `zpool add` dilakukan online.
- Data lama tidak tersebar otomatis ke vdev baru. Selama beberapa bulan,
  penulisan baru lebih banyak diarahkan ke vdev kosong sehingga distribusi
  perlahan merata.
- Penambahan vdev **permanen** — vdev raidz tidak bisa dilepas dari pool.
  Keputusan topologi (8-disk raidz2, sama seperti vdev sebelumnya) diambil
  agar konsisten; mencampur lebar vdev akan menyulitkan prediksi performa.
- Hot spare kedua ditambahkan karena jumlah disk naik 50% sehingga probabilitas
  kegagalan bersamaan ikut naik.

**Dokumen yang ikut diperbarui:**
- [x] `inventory/storage-nodes/storage-node-01.md` (topologi, inventaris disk, kapasitas)
- [x] `README.md` (mapping storage — kapasitas `/mnt/storage` 130 TB → 200 TB)
- [x] `CHANGELOG.md`

**Verifikasi:**
```
$ zpool list tank
NAME   SIZE  ALLOC   FREE  FRAG    CAP  HEALTH
tank   392T   163T   229T   11%    41%  ONLINE

$ zpool status tank | grep -c raidz2
3

$ zfs list tank
NAME   USED  AVAIL  REFER  MOUNTPOINT
tank   109T  91.2T   192K  /tank
```

**Catatan:**
Perintah dijalankan dengan dry-run lebih dulu:
`zpool add -n tank raidz2 <8 disk by-id>`, keluarannya diperiksa untuk memastikan
ZFS benar-benar akan membuat vdev raidz2 (bukan stripe), baru dijalankan tanpa `-n`.
Ini adalah langkah wajib untuk setiap `zpool add` — kesalahan di sini permanen.

---

## Catatan Kebijakan

1. **Setiap perubahan permanen wajib punya entri di sini**, sekecil apa pun.
   Jika tidak tercatat, dianggap tidak pernah terjadi — dan enam bulan kemudian
   tidak ada yang ingat kenapa serial disk di dokumen berbeda dengan yang terpasang.
2. **Selalu catat nilai "sebelum" dan "sesudah".** Entri seperti "upgrade RAM"
   tanpa angka tidak berguna saat troubleshooting.
3. **Perubahan yang tidak reversibel harus ditandai eksplisit** dan disetujui
   oleh minimal dua orang (PIC + Lead). Contoh: `zpool upgrade`, `zpool add`,
   `mdadm --zero-superblock`, `mkfs`.
4. **Verifikasi wajib disertai output perintah nyata**, bukan pernyataan "sudah dicek".
5. **Setiap entri harus menyebut dokumen mana yang ikut diperbarui.**
   Dokumentasi inventory yang tidak sinkron lebih berbahaya daripada tidak ada
   dokumentasi sama sekali.

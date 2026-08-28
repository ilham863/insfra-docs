# Maintenance Log — Infrastruktur Bare-Metal

Form dan riwayat seluruh kegiatan **pemeliharaan terjadwal maupun darurat**
pada node bare-metal.

> **Terakhir Diperbarui:** 2026-08-28
> **Aturan:** setiap tindakan yang menyebabkan **downtime**, **reboot**,
> **pembukaan chassis**, atau **perubahan konfigurasi kritis** wajib punya entri di sini.
> Entri dibuat **sebelum** pekerjaan dimulai (bagian rencana), lalu dilengkapi **setelah** selesai.

---

## Format ID Tiket

```
MNT-<TAHUN>-<NOMOR URUT 3 DIGIT>
Contoh: MNT-2026-012
```

## Klasifikasi Tipe Maintenance

| Kode | Tipe | Contoh | Butuh Downtime? |
|---|---|---|---|
| `HW-REPLACE` | Ganti komponen rusak | Ganti disk, DIMM, PSU, fan | Tergantung (hot-swap: tidak) |
| `HW-UPGRADE` | Tambah/upgrade komponen | Tambah RAM, GPU, disk baru | Ya |
| `FW-UPDATE` | Update firmware | BIOS, iDRAC/BMC, HBA, NIC, disk | Ya (reboot) |
| `OS-PATCH` | Patch keamanan rutin | `dnf update`, `apt upgrade` | Kadang (kernel: ya) |
| `OS-UPGRADE` | Upgrade versi mayor OS | Rocky 9.3 → 9.4 | Ya |
| `SW-CONFIG` | Perubahan konfigurasi | slurm.conf, exports, firewall | Biasanya tidak |
| `NET-CHANGE` | Perubahan jaringan | Ganti NIC, bonding, VLAN, kabel | Ya |
| `STOR-OPS` | Operasi storage | Scrub, resilver, ekspansi pool | Tidak (performa turun) |
| `PWR-WORK` | Pekerjaan kelistrikan | Ganti PSU, pindah PDU, uji UPS | Ya |
| `PHY-AUDIT` | Audit fisik | Cek label, kabel, filter debu, suhu rak | Tidak |
| `EMERGENCY` | Perbaikan darurat | Node crash, pool degraded, OOM masif | Ya (tidak terjadwal) |

## Klasifikasi Dampak

| Level | Arti | Persetujuan Diperlukan |
|---|---|---|
| `IMPACT-0` | Tanpa downtime, tanpa penurunan layanan | PIC sysadmin |
| `IMPACT-1` | Penurunan performa, layanan tetap jalan | PIC sysadmin |
| `IMPACT-2` | Downtime 1 node, job di-drain dulu | Sysadmin + Bioinformatician Lead |
| `IMPACT-3` | Downtime cluster-wide (storage/jaringan inti) | Sysadmin + Lead + pemberitahuan H-7 ke semua user |

---

## FORM LAPORAN MAINTENANCE (Template — copy blok ini untuk setiap kegiatan)

````markdown
### MNT-YYYY-NNN — <Judul Singkat Pekerjaan>

#### A. Informasi Umum

| Field | Isi |
|---|---|
| **ID Tiket** | `MNT-YYYY-NNN` |
| **Judul** | |
| **Tanggal Rencana** | `YYYY-MM-DD` |
| **Jam Mulai (rencana)** | `HH:MM WIB` |
| **Jam Selesai (rencana)** | `HH:MM WIB` |
| **Tanggal Pelaksanaan** | `YYYY-MM-DD` |
| **Jam Mulai (aktual)** | `HH:MM WIB` |
| **Jam Selesai (aktual)** | `HH:MM WIB` |
| **Target Node Bare-Metal** | `hostname` (Asset Tag: `AST-XXX`, Rak: `RACK-XX`, RU: `NN`) |
| **Tipe Maintenance** | `HW-REPLACE` / `FW-UPDATE` / ... |
| **Level Dampak** | `IMPACT-0` … `IMPACT-3` |
| **Estimasi Downtime** | `X jam Y menit` |
| **Downtime Aktual** | `X jam Y menit` |
| **PIC Pelaksana** | Nama |
| **PIC Pendamping** | Nama |
| **Disetujui Oleh** | Nama + tanggal persetujuan |
| **Status** | `RENCANA` / `BERJALAN` / `SELESAI` / `DIBATALKAN` / `GAGAL-ROLLBACK` |

#### B. Latar Belakang & Tujuan

Jelaskan **mengapa** maintenance ini perlu dilakukan (gejala, alarm, atau kebutuhan).
Sertakan bukti: kutipan log, output SMART, alert Grafana, atau nomor kasus vendor.

#### C. Ruang Lingkup

**Yang dikerjakan:**
- ...

**Yang TIDAK dikerjakan (out of scope):**
- ...

#### D. Layanan yang Terdampak

| Layanan | Dampak | Durasi |
|---|---|---|
| Slurm partition `gpu` | Node di-drain, job baru antre | 4 jam |
| `/mnt/storage` | Tidak terdampak | — |

#### E. Notifikasi ke User

| Item | Isi |
|---|---|
| Dikirim pada | `YYYY-MM-DD HH:MM` (H-7 untuk IMPACT-3, H-2 untuk IMPACT-2) |
| Kanal | Email milis + kanal chat + MOTD login node |
| Isi ringkas | ... |

#### F. Checklist PRE-Maintenance

- [ ] Tiket dibuat dan disetujui
- [ ] Notifikasi ke user sudah dikirim sesuai level dampak
- [ ] Jendela maintenance tercatat di kalender tim
- [ ] Spare part tersedia di lokasi (serial: `______`)
- [ ] Firmware/paket yang akan dipasang sudah diunduh & di-checksum
- [ ] Backup konfigurasi diambil:
      `/etc/slurm/`, `/etc/exports`, `/etc/network/interfaces`, `/etc/fstab`, `/etc/pve/`
- [ ] Snapshot ZFS pre-maintenance dibuat (jika menyentuh storage)
- [ ] Job yang berjalan diperiksa: `squeue -w <node>`
- [ ] Node di-drain dari Slurm:
      `scontrol update NodeName=<node> State=DRAIN Reason="MNT-YYYY-NNN"`
- [ ] Reservasi Slurm dibuat untuk jendela maintenance
- [ ] Health check baseline dijalankan & outputnya disimpan
- [ ] Akses IPMI/iDRAC diverifikasi bisa dipakai (uji `power status`)
- [ ] Akses fisik ke ruang server dikonfirmasi (kunci/kartu akses)
- [ ] Rollback plan sudah ditulis dan dipahami
- [ ] Kontak vendor & nomor kasus siap (jika RMA)
- [ ] Alat kerja siap: obeng, gelang anti-statis, senter, label, kabel tie

#### G. Langkah Pelaksanaan

| No | Langkah | Perintah / Tindakan | Waktu | Hasil |
|---|---|---|---|---|
| 1 | ... | ... | `HH:MM` | ✅ / ❌ |
| 2 | ... | ... | `HH:MM` | ✅ / ❌ |

#### H. Rollback Plan

| Field | Isi |
|---|---|
| **Titik Tidak Bisa Kembali (point of no return)** | Contoh: setelah `zpool replace` dimulai |
| **Batas Waktu Keputusan Rollback** | `HH:MM` — jika belum selesai pada jam ini, rollback |
| **Kondisi Pemicu Rollback** | Contoh: node tidak POST, pool tidak import, NFS tidak melayani |

**Langkah rollback:**
1. ...
2. ...
3. ...

**Verifikasi setelah rollback:**
- [ ] Node kembali `IDLE` di Slurm
- [ ] Semua mount point kembali normal
- [ ] Layanan terdampak sudah pulih

#### I. Checklist POST-Maintenance

- [ ] Node berhasil POST dan boot normal
- [ ] Versi firmware/OS terverifikasi sesuai target
- [ ] Semua disk/DIMM/GPU terdeteksi dengan jumlah benar
- [ ] `systemctl --failed` bersih
- [ ] Semua mount point ter-mount (`findmnt`, `df -hT`)
- [ ] Jaringan normal (`ip -br addr`, bonding aktif, jumbo frame lolos)
- [ ] Health check dijalankan & dibandingkan dengan baseline pre-maintenance
- [ ] Benchmark singkat dijalankan (jika menyentuh storage/jaringan)
- [ ] Node di-resume: `scontrol update NodeName=<node> State=RESUME`
- [ ] Job uji dikirim dan sukses (`sbatch smoke-test.sh`)
- [ ] Monitoring/alert kembali hijau di Grafana
- [ ] Reservasi Slurm dihapus
- [ ] Snapshot pre-maintenance ditandai untuk dihapus setelah 7 hari
- [ ] Dokumen `inventory/<node>.md` diperbarui (serial baru, versi baru, tanggal)
- [ ] Entri ditambahkan ke `track-record/server-changelog.md` (jika perubahan permanen)
- [ ] `CHANGELOG.md` root diperbarui
- [ ] Notifikasi selesai dikirim ke user
- [ ] Part lama dilabeli & disimpan / dikirim RMA (nomor resi: `______`)

#### J. Hasil & Verifikasi

Tempel output singkat sebelum vs sesudah (potong seperlunya).

**Sebelum:**
```
<output>
```

**Sesudah:**
```
<output>
```

#### K. Masalah yang Ditemui

| Masalah | Dampak | Penyelesaian |
|---|---|---|
| ... | ... | ... |

#### L. Catatan & Pelajaran

- ...

#### M. Lampiran

| Berkas | Path |
|---|---|
| Foto sebelum | `../assets/images/screenshots/mnt-YYYY-NNN-before.png` |
| Foto sesudah | `../assets/images/screenshots/mnt-YYYY-NNN-after.png` |
````

---

## Index Maintenance

| ID | Tanggal | Node | Tipe | Dampak | Downtime | PIC | Status |
|---|---|---|---|---|---|---|---|
| `MNT-2026-005` | 2026-03-14 | `hpc-node-01` | `HW-REPLACE` | IMPACT-2 | 1j 40m | sysadmin | ✅ SELESAI |
| `MNT-2026-004` | 2026-03-09 | `storage-node-01` | `HW-REPLACE` | IMPACT-1 | 0m | sysadmin | ✅ SELESAI |
| `MNT-2026-006` | 2026-09-05 | `storage-node-01` | `HW-REPLACE` | IMPACT-1 | 0m | sysadmin | 🟡 RENCANA |
| `MNT-2025-012` | 2025-08-11 | `storage-node-01` | `HW-REPLACE` | IMPACT-1 | 0m | sysadmin | ✅ SELESAI |
| `MNT-2025-009` | 2025-05-17 | `hpc-node-01` | `FW-UPDATE` | IMPACT-2 | 2j 15m | sysadmin | ✅ SELESAI |
| `MNT-2024-014` | 2024-11-20 | `hpc-node-01` | `FW-UPDATE` | IMPACT-2 | 3j 05m | sysadmin | ✅ SELESAI |

---

## Riwayat Lengkap

### MNT-2026-006 — Penggantian Disk Bay 6 (Pending Sector) pada storage-node-01

#### A. Informasi Umum

| Field | Isi |
|---|---|
| **ID Tiket** | `MNT-2026-006` |
| **Judul** | Penggantian HDD Bay 6 karena 5 Current_Pending_Sector |
| **Tanggal Rencana** | `2026-09-05` |
| **Jam Mulai (rencana)** | `22:00 WIB` |
| **Jam Selesai (rencana)** | `23:00 WIB` (resilver berlanjut ± 24 jam di latar belakang) |
| **Tanggal Pelaksanaan** | — |
| **Jam Mulai (aktual)** | — |
| **Jam Selesai (aktual)** | — |
| **Target Node Bare-Metal** | `storage-node-01` (Asset Tag `AST-STG-2024-0001`, Rak `RACK-A02`, RU 02–05, Bay 6) |
| **Tipe Maintenance** | `HW-REPLACE` |
| **Level Dampak** | `IMPACT-1` |
| **Estimasi Downtime** | **0 menit** (hot-swap), performa turun ± 25% selama resilver |
| **Downtime Aktual** | — |
| **PIC Pelaksana** | *(isi)* |
| **PIC Pendamping** | *(isi)* |
| **Disetujui Oleh** | *(isi)* |
| **Status** | 🟡 `RENCANA` |

#### B. Latar Belakang & Tujuan

Disk pada Bay 6 (`ata-TOSHIBA_MG09ACA18TE_X007`) melaporkan 5
`Current_Pending_Sector` sejak 2026-08-19 dan nilainya naik perlahan
(2 → 4 → 5 dalam 9 hari). Belum ada `Reallocated_Sector_Ct` dan pool masih
`ONLINE`, tetapi tren ini adalah pendahulu kegagalan disk.

Bukti:
```
smartctl -A /dev/sdg
197 Current_Pending_Sector   0x0032   100   100   000   Old_age   Always   -   5
198 Offline_Uncorrectable    0x0030   100   100   000   Old_age   Offline  -   0
  5 Reallocated_Sector_Ct    0x0033   100   100   010   Pre-fail  Always   -   0
```

Tujuan: mengganti disk secara proaktif selagi vdev masih punya dua paritas penuh,
bukan menunggu sampai disk gagal total.

#### C. Ruang Lingkup

**Yang dikerjakan:**
- Offline-kan `X007` dari pool `tank`
- Cabut fisik disk Bay 6, pasang disk pengganti `X100`
- `zpool replace` dan pantau resilver hingga selesai
- Kirim disk lama ke vendor untuk RMA garansi

**Yang TIDAK dikerjakan:**
- Tidak menyentuh vdev lain
- Tidak melakukan scrub tambahan (scrub bulanan tetap sesuai jadwal)
- Tidak mengubah konfigurasi NFS/Samba

#### D. Layanan yang Terdampak

| Layanan | Dampak | Durasi |
|---|---|---|
| NFS `/mnt/storage` | Tetap melayani, throughput turun ± 25% | ± 24 jam (durasi resilver) |
| SMB `projects` | Sama seperti di atas | ± 24 jam |
| Slurm | Tidak ada drain; job I/O berat akan lebih lambat | ± 24 jam |
| Backup Proxmox | Jadwal 01:00 ditunda satu hari agar tidak menambah beban | 1 siklus |

#### E. Notifikasi ke User

| Item | Isi |
|---|---|
| Dikirim pada | `2026-09-03 09:00` (H-2, sesuai IMPACT-1) |
| Kanal | Email milis `bioinfo-users@`, kanal chat `#hpc-announce`, MOTD `login-01` |
| Isi ringkas | "Penggantian disk terjadwal pada storage server 5 Sep 22:00. Tidak ada downtime. Job I/O berat akan lebih lambat sampai 6 Sep sore. Hindari menjadwalkan job baru yang sangat I/O-intensif pada periode ini." |

#### F. Checklist PRE-Maintenance

- [ ] Tiket dibuat dan disetujui
- [ ] Notifikasi H-2 dikirim
- [ ] Jendela tercatat di kalender tim
- [ ] Disk pengganti tersedia di lokasi — serial: `X100`, model Toshiba MG09ACA18TE 18 TB
- [ ] Disk pengganti diuji singkat di luar pool (`smartctl -t short`) dan lolos
- [ ] Backup konfigurasi diambil: `/etc/exports`, `/etc/samba/smb.conf`, `zpool get all tank > /root/backup/zpool-tank-$(date +%F).txt`
- [ ] Snapshot ZFS pre-maintenance: `zfs snapshot -r tank@pre-MNT-2026-006`
- [ ] Peta bay ↔ serial diverifikasi ulang (`sas3ircu 0 DISPLAY`)
- [ ] Status pool sebelum kerja disimpan: `zpool status -v tank > /root/backup/zpool-status-pre.txt`
- [ ] Akses IPMI diverifikasi
- [ ] Akses fisik ruang server dikonfirmasi
- [ ] Rollback plan dipahami
- [ ] Nomor kasus RMA vendor sudah dibuka: `______`
- [ ] Gelang anti-statis & senter siap

#### G. Langkah Pelaksanaan

| No | Langkah | Perintah / Tindakan | Waktu | Hasil |
|---|---|---|---|---|
| 1 | Catat status awal pool | `zpool status -v tank` | | |
| 2 | Buat snapshot rekursif | `zfs snapshot -r tank@pre-MNT-2026-006` | | |
| 3 | Offline-kan disk | `zpool offline tank ata-TOSHIBA_MG09ACA18TE_X007` | | |
| 4 | Verifikasi pool `DEGRADED` terkendali | `zpool status tank` | | |
| 5 | Nyalakan LED lokasi | `ledctl locate=/dev/sdg` | | |
| 6 | **Verifikasi ulang** LED menyala di Bay 6 secara fisik | Visual | | |
| 7 | Cabut disk lama, beri label serial + tanggal | Fisik | | |
| 8 | Pasang disk baru `X100` | Fisik | | |
| 9 | Konfirmasi disk terdeteksi | `lsblk`, `ls /dev/disk/by-id/ \| grep X100` | | |
| 10 | Jalankan replace | `zpool replace tank ata-..._X007 ata-..._X100` | | |
| 11 | Pantau resilver | `watch -n 60 zpool status tank` | | |
| 12 | Matikan LED | `ledctl locate_off=/dev/sdg` | | |
| 13 | Tunggu resilver selesai, pastikan 0 error | `zpool status -v tank` | | |
| 14 | Jalankan `smartctl -t long` pada disk baru | `smartctl -t long /dev/sdX` | | |

#### H. Rollback Plan

| Field | Isi |
|---|---|
| **Titik tidak bisa kembali** | Setelah langkah 10 (`zpool replace` dimulai) — proses harus diselesaikan, tidak bisa dibatalkan di tengah tanpa risiko |
| **Batas waktu keputusan rollback** | `23:00 WIB` — jika sampai jam ini disk baru belum terdeteksi, batalkan |
| **Kondisi pemicu rollback** | (a) Disk baru tidak terdeteksi OS; (b) salah bay tercabut; (c) pool jadi `UNAVAIL`; (d) muncul error kedua pada disk lain di vdev yang sama |

**Langkah rollback:**
1. Jika **belum** menjalankan `zpool replace`: pasang kembali disk lama `X007` ke Bay 6.
2. Online-kan kembali: `zpool online tank ata-TOSHIBA_MG09ACA18TE_X007`
3. Tunggu resilver singkat selesai, verifikasi `zpool status` kembali `ONLINE`.
4. Jika **salah bay tercabut**: segera pasang kembali disk tersebut, jalankan
   `zpool online tank <disk-itu>`, tunggu resilver, baru evaluasi ulang. raidz2
   menoleransi 2 disk hilang — jangan panik dan jangan mencabut disk kedua.
5. Jika pool tidak bisa di-import setelah reboot:
   `zpool import -F tank`, lalu `zpool import -fFX tank` sebagai upaya terakhir.
6. Jika semua gagal: pulihkan dari replika `storage-node-02` (RTO ± 4 jam).

**Verifikasi setelah rollback:**
- [ ] `zpool status tank` menunjukkan `ONLINE`, 0 error
- [ ] `exportfs -v` menampilkan seluruh export
- [ ] Mount NFS di `hpc-node-01` masih responsif (`ls /mnt/storage`)
- [ ] Tidak ada job Slurm yang gagal akibat I/O error

#### I. Checklist POST-Maintenance

- [ ] `zpool status -v tank` = `ONLINE`, resilver selesai, 0 error
- [ ] Disk baru `X100` terdeteksi dengan kapasitas penuh 18 TB
- [ ] `smartctl -H /dev/sdX` pada disk baru = `PASSED`
- [ ] Kapasitas pool tidak berubah (`zpool list`)
- [ ] `exportfs -v` normal, NFS melayani
- [ ] Mount `/mnt/storage` di semua HPC node responsif
- [ ] `systemctl --failed` bersih
- [ ] Benchmark singkat dijalankan, throughput kembali ke baseline ± 10%
- [ ] Alert Grafana kembali hijau
- [ ] Snapshot `tank@pre-MNT-2026-006` dijadwalkan dihapus 7 hari setelahnya
- [ ] Tabel disk di `inventory/storage-nodes/storage-node-01.md` diperbarui (Bay 6 → serial `X100`, jam 0, SMART PASSED)
- [ ] Entri ditambahkan ke `track-record/server-changelog.md`
- [ ] `CHANGELOG.md` root diperbarui
- [ ] Disk lama `X007` dilabeli dan dikirim RMA — nomor resi: `______`
- [ ] Notifikasi selesai dikirim ke user

#### J. Hasil & Verifikasi

**Sebelum:**
```
(tempel output: zpool status -v tank, smartctl -A /dev/sdg)
```

**Sesudah:**
```
(tempel output: zpool status -v tank setelah resilver, smartctl -H disk baru)
```

#### K. Masalah yang Ditemui

| Masalah | Dampak | Penyelesaian |
|---|---|---|
| *(diisi setelah pelaksanaan)* | | |

#### L. Catatan & Pelajaran

- *(diisi setelah pelaksanaan)*

#### M. Lampiran

| Berkas | Path |
|---|---|
| Foto bay sebelum | `../assets/images/screenshots/mnt-2026-006-before.png` |
| Foto disk pengganti + label | `../assets/images/screenshots/mnt-2026-006-replacement-disk.png` |
| Screenshot resilver selesai | `../assets/images/screenshots/mnt-2026-006-resilver-done.png` |

---

### MNT-2026-005 — Penggantian NVMe Scratch pada hpc-node-01

#### A. Informasi Umum

| Field | Isi |
|---|---|
| **ID Tiket** | `MNT-2026-005` |
| **Judul** | Penggantian NVMe scratch Bay 1 (wear 84%) dan rebuild RAID0 `/scratch` |
| **Tanggal Rencana** | `2026-03-14` |
| **Jam Mulai (rencana)** | `21:00 WIB` |
| **Jam Selesai (rencana)** | `23:00 WIB` |
| **Tanggal Pelaksanaan** | `2026-03-14` |
| **Jam Mulai (aktual)** | `21:05 WIB` |
| **Jam Selesai (aktual)** | `22:45 WIB` |
| **Target Node Bare-Metal** | `hpc-node-01` (Asset Tag `AST-HPC-2024-0001`, Rak `RACK-A01`, RU 12–13, Front Bay 1) |
| **Tipe Maintenance** | `HW-REPLACE` |
| **Level Dampak** | `IMPACT-2` |
| **Estimasi Downtime** | 2 jam |
| **Downtime Aktual** | **1 jam 40 menit** |
| **PIC Pelaksana** | *(isi)* |
| **PIC Pendamping** | *(isi)* |
| **Disetujui Oleh** | *(isi)*, disetujui `2026-03-10` |
| **Status** | ✅ `SELESAI` |

#### B. Latar Belakang & Tujuan

`nvme3n1` (Samsung PM9A3 3.84 TB, serial `SN-D0004-OLD`) mencapai
`percentage_used = 84%` — mendekati ambang penggantian internal 80%.
Karena `/scratch` adalah RAID0, kegagalan satu NVMe berarti kehilangan
seluruh 7 TB scratch dan membunuh semua job yang sedang berjalan di node.
Penggantian dilakukan proaktif.

```
nvme smart-log /dev/nvme3n1
percentage_used   : 84%
data_units_written: 2.981.442.190
media_errors      : 0
```

#### C. Ruang Lingkup

**Yang dikerjakan:**
- Kosongkan `/scratch` (koordinasi dengan user, semua data dipindah/dihapus)
- Bongkar array `/dev/md1`
- Ganti NVMe Bay 1
- Rebuild RAID0 + XFS + quota, kembalikan mount

**Yang TIDAK dikerjakan:**
- Tidak menyentuh disk OS (`nvme0n1`/`nvme1n1`)
- Tidak upgrade firmware/BIOS
- Tidak mengubah konfigurasi Slurm selain drain/resume

#### D. Layanan yang Terdampak

| Layanan | Dampak | Durasi |
|---|---|---|
| Slurm partition `gpu` | Kapasitas berkurang 1 node | 1j 40m |
| Slurm partition `bigmem` | Kapasitas berkurang 1 node | 1j 40m |
| `/scratch` di `hpc-node-01` | **Data dihapus total** | Permanen (by design) |
| `/mnt/storage` | Tidak terdampak | — |

#### E. Notifikasi ke User

| Item | Isi |
|---|---|
| Dikirim pada | `2026-03-10 10:00` (H-4) |
| Kanal | Email milis + `#hpc-announce` + MOTD |
| Isi ringkas | "hpc-node-01 akan offline 14 Mar 21:00–23:00. **Seluruh isi /scratch di node ini akan dihapus.** Pindahkan data penting ke /mnt/storage sebelum 14 Mar pukul 18:00. Pengingat: /scratch memang tidak pernah dibackup." |

#### F. Checklist PRE-Maintenance

- [x] Tiket dibuat dan disetujui
- [x] Notifikasi H-4 dikirim, pengingat H-1 dikirim
- [x] Jendela tercatat di kalender tim
- [x] NVMe pengganti tersedia — serial `SN-D0004`, Samsung PM9A3 3.84 TB
- [x] Backup konfigurasi: `/etc/fstab`, `/etc/mdadm.conf`, output `xfs_quota report`
- [x] `squeue -w hpc-node-01` diverifikasi kosong pada 20:55
- [x] Node di-drain: `scontrol update NodeName=hpc-node-01 State=DRAIN Reason="MNT-2026-005"`
- [x] Reservasi Slurm dibuat
- [x] Isi `/scratch` diverifikasi sudah kosong / user sudah diberi tahu
- [x] Health check baseline disimpan di `/root/backup/hc-pre-MNT-2026-005.txt`
- [x] Akses IPMI diuji (`chassis power status` → `on`)
- [x] Akses fisik dikonfirmasi
- [x] Rollback plan ditulis
- [x] Gelang anti-statis, obeng, label siap

#### G. Langkah Pelaksanaan

| No | Langkah | Perintah / Tindakan | Waktu | Hasil |
|---|---|---|---|---|
| 1 | Verifikasi tidak ada job | `squeue -w hpc-node-01` | 20:55 | ✅ kosong |
| 2 | Backup konfigurasi | `cp /etc/fstab /etc/mdadm.conf /root/backup/` | 21:05 | ✅ |
| 3 | Unmount scratch | `umount /scratch` | 21:08 | ✅ |
| 4 | Hentikan array | `mdadm --stop /dev/md1` | 21:10 | ✅ |
| 5 | Hapus superblock | `mdadm --zero-superblock /dev/nvme2n1 /dev/nvme3n1` | 21:11 | ✅ |
| 6 | Shutdown node | `shutdown -h now` | 21:13 | ✅ |
| 7 | Ganti NVMe Bay 1 (U.2 hot-swap, tapi node dimatikan untuk aman) | Fisik | 21:25 | ✅ |
| 8 | Power on via IPMI | `ipmitool ... chassis power on` | 21:32 | ✅ |
| 9 | Verifikasi deteksi | `nvme list` | 21:38 | ✅ serial `SN-D0004` |
| 10 | Buat RAID0 | `mdadm --create /dev/md1 --level=0 --raid-devices=2 /dev/nvme2n1 /dev/nvme3n1` | 21:42 | ✅ |
| 11 | Simpan konfigurasi mdadm | `mdadm --detail --scan >> /etc/mdadm.conf ; dracut -f` | 21:45 | ✅ |
| 12 | Format XFS | `mkfs.xfs -f -d su=512k,sw=2 /dev/md1` | 21:48 | ✅ |
| 13 | Mount + set permission | `mount /scratch ; chmod 1777 /scratch` | 21:52 | ✅ |
| 14 | Aktifkan quota | `mount -o remount,uquota /scratch ; xfs_quota -x -c 'limit bsoft=3t bhard=3300g -d' /scratch` | 21:58 | ✅ |
| 15 | Buat ulang direktori user | script `rebuild-scratch-dirs.sh` | 22:05 | ✅ |
| 16 | Benchmark cepat | `fio --name=t --rw=write --bs=1M --size=50G --directory=/scratch` | 22:15 | ✅ 8.1 GB/s |
| 17 | Resume node | `scontrol update NodeName=hpc-node-01 State=RESUME` | 22:30 | ✅ |
| 18 | Smoke test job | `sbatch smoke-test.sh` | 22:35 | ✅ sukses |

#### H. Rollback Plan

| Field | Isi |
|---|---|
| **Titik tidak bisa kembali** | Setelah langkah 5 (`mdadm --zero-superblock`) — isi `/scratch` lama hilang permanen |
| **Batas waktu keputusan rollback** | `23:30 WIB` |
| **Kondisi pemicu rollback** | (a) NVMe baru tidak terdeteksi; (b) node tidak POST; (c) throughput di bawah 4 GB/s (indikasi salah slot PCIe) |

**Langkah rollback yang direncanakan:**
1. Matikan node, pasang kembali NVMe lama `SN-D0004-OLD` di Bay 1.
2. Buat ulang RAID0 dan XFS dengan cara yang sama (data lama tetap hilang —
   ini diterima karena `/scratch` memang ephemeral).
3. Jika node tetap tidak POST: cabut kedua NVMe scratch, boot dengan OS saja,
   set `TmpDisk=0` di `slurm.conf`, dan keluarkan node dari partisi yang butuh scratch
   sampai perbaikan lanjutan.
4. Eskalasi ke vendor dengan nomor kasus garansi.

*Rollback tidak diperlukan — semua langkah berhasil.*

#### I. Checklist POST-Maintenance

- [x] Node POST dan boot normal
- [x] `nvme list` menampilkan 4 NVMe, serial baru `SN-D0004` terbaca
- [x] `cat /proc/mdstat` → `md1` aktif, RAID0, 2 anggota
- [x] `df -hT /scratch` → 7.0 TB tersedia
- [x] Quota aktif (`xfs_quota -x -c 'report -h' /scratch`)
- [x] `systemctl --failed` bersih
- [x] Semua mount NFS kembali (`findmnt | grep nfs`)
- [x] Jaringan normal, bonding aktif, jumbo frame lolos
- [x] Benchmark 8.1 GB/s tulis (baseline lama 8.0 GB/s) ✅
- [x] Node `IDLE` di Slurm
- [x] Smoke test job sukses
- [x] Grafana hijau
- [x] Reservasi Slurm dihapus
- [x] `inventory/hpc-nodes/hpc-node-01.md` diperbarui (serial NVMe, wear 0%)
- [x] Entri `SCL-2026-004` ditambahkan ke `server-changelog.md`
- [x] `CHANGELOG.md` diperbarui
- [x] NVMe lama dilabeli & dikirim RMA — resi `RMA-2026-0312`
- [x] Notifikasi selesai dikirim `2026-03-14 22:50`

#### J. Hasil & Verifikasi

**Sebelum:**
```
$ nvme smart-log /dev/nvme3n1 | grep -E 'percentage_used|media_errors'
percentage_used   : 84%
media_errors      : 0

$ df -hT /scratch
/dev/md1  xfs  7.0T  4.2T  2.8T  61% /scratch
```

**Sesudah:**
```
$ nvme smart-log /dev/nvme3n1 | grep -E 'percentage_used|media_errors'
percentage_used   : 0%
media_errors      : 0

$ cat /proc/mdstat
md1 : active raid0 nvme2n1[0] nvme3n1[1]
      7501476864 blocks super 1.2 512k chunks

$ df -hT /scratch
/dev/md1  xfs  7.0T   68M  7.0T   1% /scratch
```

#### K. Masalah yang Ditemui

| Masalah | Dampak | Penyelesaian |
|---|---|---|
| `/scratch` tidak otomatis ter-mount saat boot pertama karena `mdadm.conf` belum masuk initramfs | Mount manual diperlukan | Jalankan `dracut -f` setelah `mdadm --detail --scan >> /etc/mdadm.conf`, reboot uji, berhasil |
| Dua user masih menyimpan data 900 GB di `/scratch` pada H-1 meski sudah diberi tahu | Hampir kehilangan data | Dihubungi langsung H-1, data dipindah ke `/mnt/storage`. **Pelajaran:** kirim pengingat H-1, bukan hanya H-4 |

#### L. Catatan & Pelajaran

- Selalu jalankan `dracut -f` (atau `update-initramfs -u` di Debian) setelah mengubah
  `mdadm.conf`, kalau tidak array tidak akan tersusun saat boot.
- Notifikasi H-4 saja tidak cukup untuk pekerjaan yang menghapus data.
  Kebijakan baru: **H-7, H-2, dan H-1** untuk setiap pekerjaan yang menghapus `/scratch`.
- Downtime aktual 20 menit lebih cepat dari estimasi karena tidak ada resilver
  (RAID0 tidak perlu sinkronisasi).

#### M. Lampiran

| Berkas | Path |
|---|---|
| Foto bay sebelum | `../assets/images/screenshots/mnt-2026-005-before.png` |
| Foto NVMe baru | `../assets/images/screenshots/mnt-2026-005-new-nvme.png` |
| Output benchmark | `../assets/images/screenshots/mnt-2026-005-fio-result.png` |

---

## Jadwal Maintenance Rutin (Berulang)

| Kegiatan | Frekuensi | Jadwal | Node | Dampak | PIC |
|---|---|---|---|---|---|
| Scrub ZFS | Bulanan | Minggu ke-1, Minggu 00:00 | `storage-node-01` | IMPACT-1 | sysadmin |
| SMART self-test short | Harian | 02:00 | Semua node | IMPACT-0 | otomatis |
| SMART self-test long | Mingguan | Minggu 01:00 | Semua node | IMPACT-0 | otomatis |
| Purge `/scratch` | Harian | 03:00 | Semua HPC node | IMPACT-0 | otomatis |
| Backup VM (`vzdump`) | Harian | 01:00 | `proxmox-node-01` | IMPACT-0 | otomatis |
| Replikasi ZFS (`syncoid`) | Harian | 01:00 | `storage-node-01` | IMPACT-0 | otomatis |
| Uji restore backup | Kuartalan | Minggu ke-2 kuartal | `proxmox-node-01` | IMPACT-0 | sysadmin |
| Patch keamanan OS | Bulanan | Sabtu ke-3, 22:00 | Bergilir per node | IMPACT-2 | sysadmin |
| Update firmware (BIOS/BMC/HBA) | Semesteran | Jendela besar | Bergilir per node | IMPACT-2 | sysadmin |
| Audit fisik rak (label, kabel, filter debu) | Kuartalan | Minggu ke-1 kuartal | Semua rak | IMPACT-0 | sysadmin |
| Uji beban UPS | Semesteran | Sesuai jadwal fasilitas | Semua | IMPACT-3 | sysadmin + fasilitas |
| Verifikasi baseline benchmark | Semesteran | Setelah jendela firmware | Semua | IMPACT-1 | sysadmin |
| Review kapasitas storage | Bulanan | Tanggal 1 | `storage-node-01` | IMPACT-0 | sysadmin |
| Audit akun & kredensial | Semesteran | Januari & Juli | Semua | IMPACT-0 | sysadmin |

---

## Prosedur Darurat (Emergency)

Untuk insiden tak terjadwal, tetap buat entri `MNT-YYYY-NNN` dengan tipe `EMERGENCY`,
tetapi isi form **setelah** situasi terkendali. Prioritas: pulihkan layanan dulu,
dokumentasi menyusul dalam 24 jam.

| Gejala | Tindakan Pertama | Eskalasi |
|---|---|---|
| Node compute tidak merespons | Cek `ipmitool ... chassis power status` dan `sel elist`, coba SOL console | Sysadmin utama |
| Pool ZFS `DEGRADED` | `zpool status -v`, pastikan hot spare mulai resilver, **jangan** cabut disk apa pun sebelum diverifikasi | Sysadmin utama |
| Pool ZFS `SUSPENDED`/`UNAVAIL` | Jangan reboot. Kumpulkan `zpool status`, `dmesg`, `zpool events -v`. | Sysadmin utama + vendor |
| NFS hang di semua node | Cek `storage-node-01` hidup & `nfsd` jalan; jangan `umount -f` di klien (mount `hard`) | Sysadmin utama |
| OOM Killer membunuh proses sistem | Drain node, cek `dmesg -T \| grep -i oom`, identifikasi job pelanggar | Sysadmin + Bioinfo Lead |
| Suhu ruangan naik / AC mati | Matikan node non-kritis (`proxmox-node-01` terakhir), jaga storage tetap hidup | Fasilitas + sysadmin |
| Listrik padam, UPS aktif | Shutdown terurut: compute → proxmox → storage | Sysadmin utama |
| Uncorrectable ECC error | Drain node segera, jadwalkan ganti DIMM | Sysadmin utama |

**Urutan shutdown darurat cluster:**
```
1. Drain & hentikan semua job Slurm    : scontrol update NodeName=ALL State=DRAIN
2. Matikan semua HPC compute node
3. Shutdown semua VM/LXC, lalu proxmox-node-01
4. Terakhir: export pool & shutdown storage-node-01
   (zpool export tank tidak wajib jika shutdown bersih, tapi pastikan
    tidak ada I/O aktif: `zpool sync tank`)
```

**Urutan startup:**
```
1. storage-node-01  → tunggu pool ONLINE & NFS melayani (verifikasi: showmount -e)
2. proxmox-node-01  → tunggu VM DNS/LDAP/monitoring hidup
3. login node       → verifikasi slurmctld
4. HPC compute node → verifikasi mount NFS sebelum State=RESUME
```

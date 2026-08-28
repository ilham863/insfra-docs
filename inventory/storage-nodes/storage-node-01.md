# storage-node-01 — Storage Server (Bare-Metal, ZFS)

> **Tipe Unit:** Bare-Metal Storage Server — 1 chassis fisik
> **Status:** 🟢 Production
> **Terakhir Diperbarui:** 2026-08-28
> **PIC Node:** *(isi nama sysadmin)*
> **Dokumen Terkait:** [server-changelog](../../track-record/server-changelog.md) · [maintenance-log](../../track-record/maintenance-log.md)

![Posisi rak storage-node-01](../../assets/images/racks/storage-node-01-rack.png)

> ⚠️ **NODE PALING KRITIS DI CLUSTER.**
> Jika node ini turun, seluruh HPC node kehilangan `/mnt/storage` dan `/home`,
> dan semua job yang menulis ke NFS akan hang (`hard` mount). Setiap tindakan
> pada node ini **wajib** melalui jendela maintenance terjadwal.

---

## 1. Identitas & Aset Fisik

| Field | Nilai |
|---|---|
| **Hostname (short)** | `storage-node-01` |
| **FQDN** | `storage-node-01.hpc.local` |
| **Alias / Label Fisik** | `STORAGE-ZFS-01` |
| **Serial Number** | `SN-YYYYYYY` |
| **Asset Tag (internal)** | `AST-STG-2024-0001` |
| **Vendor** | Supermicro / Dell EMC *(pilih)* |
| **Model** | SSG-6049P-E1CR36L (36-bay) / PowerEdge R760xd2 |
| **Form Factor** | Rackmount **4U**, 36× 3.5" hot-swap bay |
| **Tanggal Pembelian** | `2024-05-20` |
| **Tanggal Go-Live** | `2024-06-18` |
| **Garansi Berakhir** | `2029-05-19` |
| **Nomor Kontrak Support** | `CTR-YYYYYY` |
| **Status Operasional** | 🟢 Production |

### 1.1 Lokasi Fisik

| Field | Nilai |
|---|---|
| **Gedung / Ruang** | Gedung Riset — Ruang Server Lt. 2 |
| **Nama Rak** | `RACK-A02` |
| **Posisi RU** | **RU 02 – RU 05** (4U, paling bawah — pertimbangan bobot) |
| **PDU A** | `PDU-A02-A` → outlet **C13 #2** |
| **PDU B** | `PDU-A02-B` → outlet **C13 #2** |
| **PSU** | 2× 1600W Titanium (1+1 redundant) |
| **Daya Idle** | ± 480 W |
| **Daya Peak (scrub/resilver)** | ± 900 W |
| **Berat (terisi penuh)** | ± 48 kg |
| **UPS** | `UPS-01`, runtime ± 22 menit pada beban penuh |
| **Label Kabel** | `A02-RU02-NET1/2`, `A02-RU02-IPMI`, `A02-RU02-PWR-A/B` |

```bash
sudo dmidecode -t 1
sudo dmidecode -s system-serial-number
```

---

## 2. Manajemen Out-of-Band (IPMI)

| Field | Nilai |
|---|---|
| **Tipe BMC** | IPMI 2.0 (ASPEED AST2500) / iDRAC9 |
| **IP IPMI** | `10.10.30.50/24` |
| **Gateway** | `10.10.30.1` |
| **VLAN** | **VLAN 30** |
| **MAC BMC** | `AA:BB:CC:DD:EE:50` |
| **Hostname BMC** | `ipmi-storage-node-01.hpc.local` |
| **Firmware BMC** | `1.73.12` |
| **BIOS** | `3.4a` |
| **Web UI** | `https://10.10.30.50` |
| **SOL** | Aktif, `115200` |
| **Akun Admin** | `sysadmin` — password di Vaultwarden `IPMI / storage-node-01` |
| **Akun Read-only** | `monitor-ro` |

```bash
ipmitool -I lanplus -H 10.10.30.50 -U sysadmin -P '<...>' chassis power status
ipmitool -I lanplus -H 10.10.30.50 -U sysadmin -P '<...>' sdr type Temperature
ipmitool -I lanplus -H 10.10.30.50 -U sysadmin -P '<...>' sdr type Fan
ipmitool -I lanplus -H 10.10.30.50 -U sysadmin -P '<...>' sel elist
ipmitool -I lanplus -H 10.10.30.50 -U sysadmin -P '<...>' chassis identify 60
```

---

## 3. CPU, RAM, dan Jaringan

### 3.1 Compute

| Field | Nilai |
|---|---|
| **CPU** | 2× Intel Xeon Silver 4416+ (20C/40T @ 2.00 GHz) |
| **Total Core / Thread** | 40 / 80 |
| **RAM** | **512 GB** DDR5 ECC RDIMM 4800 MT/s (16× 32 GB) |
| **Peruntukan RAM** | ZFS ARC max **384 GB**, sisanya OS + NFS server |
| **NUMA** | 2 node |

> **Kenapa RAM sebesar ini:** ZFS ARC adalah cache baca utama.
> Aturan praktis untuk pool 200 TB dengan dedup **nonaktif**: minimal 1 GB RAM
> per 1 TB storage, plus headroom besar untuk metadata pipeline bioinformatics
> yang punya jutaan file kecil.

```bash
# Batasi ARC agar OS + nfsd tidak kehabisan RAM
cat /etc/modprobe.d/zfs.conf
# options zfs zfs_arc_max=412316860416     # 384 GiB
# options zfs zfs_arc_min=137438953472     # 128 GiB

arc_summary | head -40
arcstat 5
```

### 3.2 Jaringan

| Interface | Tipe | MAC | Speed | Bonding | IP | VLAN | Switch : Port | MTU | Fungsi |
|---|---|---|---|---|---|---|---|---|---|
| `eno1` | RJ45 | `AA:BB:CC:DD:EE:51` | 1 GbE | — | `10.10.10.50/24` | 10 | `SW-MGMT-01 : Gi1/0/20` | 1500 | Manajemen |
| `ens2f0` | SFP28 | `AA:BB:CC:DD:EE:52` | 25 GbE | `bond0` | — | 20 | `SW-DATA-01 : Eth1/20` | 9000 | Data |
| `ens2f1` | SFP28 | `AA:BB:CC:DD:EE:53` | 25 GbE | `bond0` | — | 20 | `SW-DATA-02 : Eth1/20` | 9000 | Data |
| `bond0` | LACP 802.3ad | — | **50 GbE** | master | `10.10.20.50/24` | 20 | `po20` | **9000** | NFS/SMB export |
| `ipmi` | RJ45 | `AA:BB:CC:DD:EE:50` | 1 GbE | — | `10.10.30.50/24` | 30 | `SW-MGMT-01 : Gi1/0/50` | 1500 | Out-of-band |

```bash
ip -br addr
cat /proc/net/bonding/bond0
ethtool bond0 | grep Speed
ping -M do -s 8972 -c 4 10.10.20.11     # verifikasi jumbo ke hpc-node-01
```

---

## 4. Controller Penyimpanan (HBA)

| Field | Nilai |
|---|---|
| **Model HBA** | Broadcom/LSI SAS 9500-16i (Tri-Mode) |
| **Mode** | **IT Mode / JBOD** — WAJIB, bukan RAID mode |
| **Firmware** | `24.00.00.00` |
| **Driver** | `mpt3sas 48.100.00.00` |
| **Jumlah HBA** | 2 unit (masing-masing 16 port) |
| **Expander Backplane** | SAS3 expander, 36 bay |
| **Cache BBU** | Tidak ada (tidak diperlukan di IT mode) |

> **Aturan mutlak:** ZFS **harus** melihat disk mentah.
> Jangan pernah membuat virtual disk RAID di HBA — itu menyembunyikan
> informasi SMART dan mematikan kemampuan self-healing ZFS.

```bash
lspci | grep -i -E 'sas|raid'
sudo storcli64 /c0 show                       # kalau pakai MegaRAID
sudo sas3ircu 0 DISPLAY                       # kalau pakai LSI IT-mode
ls -l /dev/disk/by-id/ | grep -v part
lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL,ROTA
```

---

## 5. Inventaris Disk per-Slot

> **Selalu gunakan `/dev/disk/by-id/` untuk konfigurasi ZFS**, jangan `/dev/sdX`
> — penamaan `sdX` bisa berubah setelah reboot.

| Bay | Device (by-id, disingkat) | Model | Kapasitas | Tipe | RPM | Firmware | Serial | Peran ZFS | Power-On Hours | SMART |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | `ata-TOSHIBA_MG09ACA18TE_X001` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X001` | `raidz2-0` | 18.900 | 🟢 PASSED |
| 1 | `ata-TOSHIBA_MG09ACA18TE_X002` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X002` | `raidz2-0` | 18.900 | 🟢 PASSED |
| 2 | `ata-TOSHIBA_MG09ACA18TE_X003` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X003` | `raidz2-0` | 18.898 | 🟢 PASSED |
| 3 | `ata-TOSHIBA_MG09ACA18TE_X004` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X004` | `raidz2-0` | 18.898 | 🟢 PASSED |
| 4 | `ata-TOSHIBA_MG09ACA18TE_X005` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X005` | `raidz2-0` | 18.897 | 🟢 PASSED |
| 5 | `ata-TOSHIBA_MG09ACA18TE_X006` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X006` | `raidz2-0` | 18.897 | 🟢 PASSED |
| 6 | `ata-TOSHIBA_MG09ACA18TE_X007` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X007` | `raidz2-0` | 18.895 | 🟡 *5 pending sector* |
| 7 | `ata-TOSHIBA_MG09ACA18TE_X008` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X008` | `raidz2-0` | 4.210 | 🟢 PASSED *(diganti 2026-03)* |
| 8 | `ata-TOSHIBA_MG09ACA18TE_X009` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X009` | `raidz2-1` | 18.890 | 🟢 PASSED |
| 9 | `ata-TOSHIBA_MG09ACA18TE_X010` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X010` | `raidz2-1` | 18.890 | 🟢 PASSED |
| 10 | `ata-TOSHIBA_MG09ACA18TE_X011` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X011` | `raidz2-1` | 18.888 | 🟢 PASSED |
| 11 | `ata-TOSHIBA_MG09ACA18TE_X012` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X012` | `raidz2-1` | 18.888 | 🟢 PASSED |
| 12 | `ata-TOSHIBA_MG09ACA18TE_X013` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X013` | `raidz2-1` | 18.885 | 🟢 PASSED |
| 13 | `ata-TOSHIBA_MG09ACA18TE_X014` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X014` | `raidz2-1` | 18.885 | 🟢 PASSED |
| 14 | `ata-TOSHIBA_MG09ACA18TE_X015` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X015` | `raidz2-1` | 18.883 | 🟢 PASSED |
| 15 | `ata-TOSHIBA_MG09ACA18TE_X016` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X016` | `raidz2-1` | 18.883 | 🟢 PASSED |
| 16–23 | `...X017` – `...X024` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X017`–`X024` | `raidz2-2` | ± 18.880 | 🟢 PASSED |
| 32 | `ata-TOSHIBA_MG09ACA18TE_X033` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X033` | **hot spare** | 18.880 | 🟢 PASSED |
| 33 | `ata-TOSHIBA_MG09ACA18TE_X034` | Toshiba MG09ACA18TE | 18 TB | SATA HDD | 7200 | `0104` | `X034` | **hot spare** | 18.880 | 🟢 PASSED |
| 34 | `nvme-SAMSUNG_MZQL21T9HCJR_S001` | Samsung PM9A3 | 1.92 TB | NVMe | — | `GDC7302Q` | `S001` | `special` (mirror) | 18.870 | 🟢 3% used |
| 35 | `nvme-SAMSUNG_MZQL21T9HCJR_S002` | Samsung PM9A3 | 1.92 TB | NVMe | — | `GDC7302Q` | `S002` | `special` (mirror) | 18.870 | 🟢 3% used |
| M.2 #1 | `nvme-MICRON_7450_PRO_S003` | Micron 7450 PRO | 480 GB | NVMe M.2 | — | `E1MU23BC` | `S003` | Boot mirror | 18.870 | 🟢 1% used |
| M.2 #2 | `nvme-MICRON_7450_PRO_S004` | Micron 7450 PRO | 480 GB | NVMe M.2 | — | `E1MU23BC` | `S004` | Boot mirror | 18.870 | 🟢 1% used |
| 24–31 | *(kosong)* | — | — | — | — | — | — | Slot ekspansi | — | — |

> 🟡 **Bay 6 (`X007`) punya 5 Current_Pending_Sector.** Sudah dipesan penggantinya.
> Rencana ganti: jendela maintenance berikutnya. Lihat `maintenance-log.md`.

```bash
# Peta bay ↔ device (penting saat mau cabut disk yang benar!)
sudo sas3ircu 0 DISPLAY | grep -E 'Enclosure|Slot|Serial'
lsblk -o NAME,SIZE,SERIAL,MODEL

# Nyalakan LED lokasi pada disk tertentu sebelum dicabut
sudo ledctl locate=/dev/sdg
sudo ledctl locate_off=/dev/sdg
```

---

## 6. Topologi ZFS Pool

### 6.1 Ringkasan pool

| Field | Nilai |
|---|---|
| **Nama Pool** | `tank` |
| **Versi ZFS** | OpenZFS `2.2.4` |
| **Topologi Data** | **3× vdev raidz2**, masing-masing 8× 18 TB |
| **Hot Spare** | 2 disk global |
| **Special vdev (metadata)** | mirror 2× NVMe 1.92 TB — mempercepat listing jutaan file kecil |
| **SLOG (ZIL)** | Tidak ada (workload didominasi async write; NFS sync ditangani special vdev) |
| **L2ARC** | Tidak ada (ARC 384 GB sudah cukup) |
| **ashift** | `12` (4K sector) |
| **Kompresi** | `lz4` (pool-wide default) |
| **Dedup** | **NONAKTIF** — jangan pernah diaktifkan, kebutuhan RAM-nya tidak masuk akal untuk data sekuens |
| **atime** | `off` |
| **xattr** | `sa` |
| **autotrim** | `on` (untuk special vdev NVMe) |
| **autoreplace** | `on` |
| **autoexpand** | `on` |

### 6.2 Diagram topologi

```
tank
├── raidz2-0   [8 × 18 TB]  → raw 144 TB, usable ± 108 TB (2 disk paritas)
│     bay 0,1,2,3,4,5,6,7
├── raidz2-1   [8 × 18 TB]  → raw 144 TB, usable ± 108 TB
│     bay 8,9,10,11,12,13,14,15
├── raidz2-2   [8 × 18 TB]  → raw 144 TB, usable ± 108 TB
│     bay 16,17,18,19,20,21,22,23
├── special
│    └── mirror-3  [2 × 1.92 TB NVMe]   → metadata + small blocks
└── spares
     ├── bay 32 (18 TB)
     └── bay 33 (18 TB)
```

### 6.3 `zpool status` (contoh keluaran normal)

```
  pool: tank
 state: ONLINE
  scan: scrub repaired 0B in 1 days 09:42:11 with 0 errors on Sun Aug  3 09:42:12 2026
config:

        NAME                                  STATE     READ WRITE CKSUM
        tank                                  ONLINE       0     0     0
          raidz2-0                            ONLINE       0     0     0
            ata-TOSHIBA_MG09ACA18TE_X001      ONLINE       0     0     0
            ata-TOSHIBA_MG09ACA18TE_X002      ONLINE       0     0     0
            ata-TOSHIBA_MG09ACA18TE_X003      ONLINE       0     0     0
            ata-TOSHIBA_MG09ACA18TE_X004      ONLINE       0     0     0
            ata-TOSHIBA_MG09ACA18TE_X005      ONLINE       0     0     0
            ata-TOSHIBA_MG09ACA18TE_X006      ONLINE       0     0     0
            ata-TOSHIBA_MG09ACA18TE_X007      ONLINE       0     0     0
            ata-TOSHIBA_MG09ACA18TE_X008      ONLINE       0     0     0
          raidz2-1                            ONLINE       0     0     0
            ata-TOSHIBA_MG09ACA18TE_X009      ONLINE       0     0     0
            ...
          raidz2-2                            ONLINE       0     0     0
            ata-TOSHIBA_MG09ACA18TE_X017      ONLINE       0     0     0
            ...
        special
          mirror-3                            ONLINE       0     0     0
            nvme-SAMSUNG_MZQL21T9HCJR_S001    ONLINE       0     0     0
            nvme-SAMSUNG_MZQL21T9HCJR_S002    ONLINE       0     0     0
        spares
          ata-TOSHIBA_MG09ACA18TE_X033        AVAIL
          ata-TOSHIBA_MG09ACA18TE_X034        AVAIL

errors: No known data errors
```

---

## 7. Kapasitas: Raw vs Usable

| Metrik | Nilai | Catatan |
|---|---|---|
| **Raw total (24 disk data)** | 432 TB | 24 × 18 TB |
| **Kapasitas setelah paritas raidz2** | ± 324 TB | 6 disk (2 per vdev) dipakai paritas |
| **Setelah overhead ZFS + padding** | ± 300 TiB | Overhead raidz ± 3–8% |
| **Batas operasional (80% rule)** | **± 240 TiB** | Di atas 80%, performa ZFS turun drastis |
| **Kapasitas terpublikasi ke user** | **200 TB usable** | Angka konservatif yang dipakai di README |
| **Reservasi sistem** | 5 TiB | `refreservation` di dataset `tank/system-reserve` |
| **Special vdev** | 1.92 TB mirror | Untuk metadata, bukan data user |
| **Hot spare** | 36 TB | 2 × 18 TB, tidak dihitung kapasitas |
| **Terpakai saat ini** | 148 TiB (**62%**) | Per 2026-08-28 |
| **Sisa** | 92 TiB | |

> **Aturan 80%:** jika `capacity` pool melewati **80%**, ZFS beralih dari alokasi
> *best-fit* ke *first-fit* dan performa tulis anjlok. Alarm critical di-set 80%,
> bukan 90%.

```bash
zpool list -v
zpool list -o name,size,alloc,free,frag,cap,dedup,health
zfs list -o name,used,avail,refer,compressratio,quota,mountpoint
zfs get compressratio tank
zpool get all tank | grep -E 'ashift|autotrim|autoreplace|autoexpand'
```

---

## 8. Dataset ZFS

| Dataset | Mountpoint | Quota | recordsize | Kompresi | Snapshot | Terpakai | Fungsi |
|---|---|---|---|---|---|---|---|
| `tank/storage` | `/tank/storage` | — | 1M | lz4 | harian | 92 TiB | Induk export utama |
| `tank/storage/raw` | `/tank/storage/raw` | 80 TiB | **1M** | lz4 | harian + hold | 61 TiB | FASTQ mentah, read-only setelah ingest |
| `tank/storage/projects` | `/tank/storage/projects` | 100 TiB | **1M** | lz4 | harian | 31 TiB | Hasil final per proyek |
| `tank/reference` | `/tank/reference` | 10 TiB | 1M | lz4 | mingguan | 6.4 TiB | Genom referensi + index |
| `tank/home` | `/tank/home` | 2 TiB | **128K** | lz4 | 4×/hari | 1.1 TiB | Home direktori user |
| `tank/containers` | `/tank/containers` | 4 TiB | 1M | **off** | mingguan | 1.8 TiB | Image `.sif` (sudah terkompres) |
| `tank/backup` | `/tank/backup` | 40 TiB | 1M | zstd-3 | harian | 12 TiB | Target `vzdump` Proxmox |
| `tank/system-reserve` | *(none)* | `refreservation=5T` | — | — | — | 5 TiB | Bantalan agar pool tidak pernah 100% |

> **Kenapa `recordsize=1M` untuk data sekuens:** BAM/CRAM/FASTQ dibaca dan ditulis
> secara sekuensial dalam blok besar. `recordsize` besar mengurangi overhead metadata
> dan menaikkan throughput signifikan. Sebaliknya `/home` diisi banyak file kecil,
> jadi tetap `128K`.

> **Kenapa kompresi `off` di `tank/containers`:** file `.sif` sudah SquashFS terkompres.
> Mengompres ulang hanya membakar CPU tanpa penghematan.

```bash
zfs list -r tank
zfs get -r recordsize,compression,quota,atime tank
zfs get used,logicalused,compressratio tank/storage/raw
```

---

## 9. Kesehatan SMART & Monitoring Disk

| Field | Nilai |
|---|---|
| **Daemon** | `smartd` (`smartmontools 7.4`) |
| **Config** | `/etc/smartmontools/smartd.conf` |
| **Self-test Short** | Setiap hari 02:00 |
| **Self-test Long** | Setiap Minggu 01:00 (bergilir per grup disk) |
| **Notifikasi** | Email ke sysadmin + trap SNMP ke `10.10.10.20` |
| **Atribut Dipantau** | `5` Reallocated_Sector_Ct, `187` Reported_Uncorrect, `188` Command_Timeout, `197` Current_Pending_Sector, `198` Offline_Uncorrectable, `194` Temperature |

### 9.1 Ambang tindakan

| Kondisi | Tingkat | Tindakan |
|---|---|---|
| `Current_Pending_Sector` 1–9 | 🟡 Warning | Pantau harian, siapkan disk pengganti |
| `Current_Pending_Sector` ≥ 10 | 🔴 Critical | Jadwalkan penggantian dalam 7 hari |
| `Reallocated_Sector_Ct` > 0 dan naik | 🔴 Critical | Ganti disk |
| `Offline_Uncorrectable` > 0 | 🔴 Critical | Ganti disk segera |
| SMART overall `FAILED` | 🔴 Critical | Ganti segera, jangan tunggu jendela |
| Suhu disk > 50 °C | 🟡 Warning | Cek fan & filter debu |
| Suhu disk > 58 °C | 🔴 Critical | Cek pendingin ruangan |
| ZFS `CKSUM` error > 0 | 🔴 Critical | Scrub, cek kabel/HBA, kandidat ganti disk |
| Pool `DEGRADED` | 🔴 Critical | Verifikasi resilver spare berjalan |

### 9.2 Perintah

```bash
# Ringkasan seluruh disk
for d in /dev/sd[a-z] /dev/sd[a-z][a-z]; do
  [ -b "$d" ] || continue
  printf "%-10s %-22s %s\n" "$d" \
    "$(sudo smartctl -i $d | awk -F': *' '/Serial Number/{print $2}')" \
    "$(sudo smartctl -H $d | awk -F': *' '/overall-health/{print $2}')"
done

sudo smartctl -a /dev/sdg
sudo smartctl -A /dev/sdg | grep -E 'Reallocated|Pending|Uncorrect|Temperature'
sudo smartctl -t short /dev/sdg
sudo smartctl -t long  /dev/sdg
sudo smartctl -l selftest /dev/sdg

# NVMe
sudo nvme smart-log /dev/nvme0n1
```

### 9.3 Prosedur ganti disk yang gagal

```bash
# 1. Identifikasi disk bermasalah
zpool status -v tank

# 2. Offline-kan
sudo zpool offline tank ata-TOSHIBA_MG09ACA18TE_X007

# 3. Nyalakan LED lokasi — PASTIKAN mencabut bay yang benar
sudo ledctl locate=/dev/sdg

# 4. Cabut fisik, pasang disk baru (hot-swap, tanpa matikan server)

# 5. Ganti di pool
sudo zpool replace tank ata-TOSHIBA_MG09ACA18TE_X007 \
                        ata-TOSHIBA_MG09ACA18TE_X099

# 6. Pantau resilver — untuk 18 TB bisa 12–30 jam
watch -n 60 zpool status tank

# 7. Matikan LED & catat di track-record/
sudo ledctl locate_off=/dev/sdg
```

---

## 10. Mount Point Lokal

| Mount Point | Sumber | FS | Kapasitas | Opsi | Keterangan |
|---|---|---|---|---|---|
| `/` | `rpool/ROOT/default` | ZFS | 400 GB | `noatime` | OS (mirror NVMe M.2) |
| `/boot/efi` | `nvme-...S003-part1` | vfat | 512 MB | `umask=0077` | EFI |
| `/tank` | `tank` | ZFS | 300 TiB | `noatime,xattr=sa` | Root pool data |
| `/tank/storage` | `tank/storage` | ZFS | — | inherit | Diekspor sebagai `/mnt/storage` |
| `/tank/reference` | `tank/reference` | ZFS | 10 TiB | inherit | Read-only export |
| `/tank/home` | `tank/home` | ZFS | 2 TiB | inherit | Home user |
| `/tank/containers` | `tank/containers` | ZFS | 4 TiB | inherit | Image `.sif` |
| `/tank/backup` | `tank/backup` | ZFS | 40 TiB | inherit | Backup Proxmox |

```bash
findmnt -t zfs
zfs mount
df -hT | grep -E 'zfs|tank'
```

---

## 11. Export NFS

| Path Export | Klien Diizinkan | Opsi | Dipakai Untuk |
|---|---|---|---|
| `/tank/storage` | `10.10.20.0/24` | `rw,sync,no_subtree_check,root_squash,sec=sys` | `/mnt/storage` di HPC node |
| `/tank/storage/raw` | `10.10.20.0/24` | `ro,sync,no_subtree_check,root_squash` | Data mentah — kunci read-only |
| `/tank/reference` | `10.10.20.0/24` | `ro,sync,no_subtree_check,root_squash` | Genom referensi |
| `/tank/home` | `10.10.20.0/24` | `rw,sync,no_subtree_check,no_root_squash` | Home direktori |
| `/tank/containers` | `10.10.20.0/24` | `ro,sync,no_subtree_check,root_squash` | Image Singularity |
| `/tank/backup` | `10.10.20.60/32` | `rw,sync,no_subtree_check,no_root_squash` | Hanya `proxmox-node-01` |

Isi `/etc/exports`:
```
/tank/storage         10.10.20.0/24(rw,sync,no_subtree_check,root_squash,sec=sys)
/tank/storage/raw     10.10.20.0/24(ro,sync,no_subtree_check,root_squash)
/tank/reference       10.10.20.0/24(ro,sync,no_subtree_check,root_squash)
/tank/home            10.10.20.0/24(rw,sync,no_subtree_check,no_root_squash)
/tank/containers      10.10.20.0/24(ro,sync,no_subtree_check,root_squash)
/tank/backup          10.10.20.60/32(rw,sync,no_subtree_check,no_root_squash)
```

| Parameter Server NFS | Nilai |
|---|---|
| **Versi** | NFSv4.2 (v3 dinonaktifkan) |
| **Jumlah thread `nfsd`** | **128** (`RPCNFSDCOUNT=128` di `/etc/nfs.conf`) |
| **Domain NFSv4** | `hpc.local` (`/etc/idmapd.conf`) |
| **Port** | 2049 saja (v4 tidak butuh portmapper terpisah) |
| **Firewall** | Hanya izinkan `10.10.20.0/24` ke port 2049 |

```bash
sudo exportfs -ra
sudo exportfs -v
showmount -e localhost
nfsstat -s
cat /proc/fs/nfsd/threads
systemctl status nfs-server
```

---

## 12. Share SMB / CIFS

| Nama Share | Path | Akses | Grup | Keterangan |
|---|---|---|---|---|
| `projects` | `/tank/storage/projects` | rw | `bioinfo-users` | Akses dari laptop peneliti (Windows/macOS) |
| `reference` | `/tank/reference` | ro | `bioinfo-users` | Genom referensi |
| `dropbox` | `/tank/storage/incoming` | rw | `bioinfo-users` | Zona transit upload data baru |

`/etc/samba/smb.conf` (potongan):
```ini
[global]
   workgroup = HPC
   server string = Bioinformatics Storage
   security = user
   passdb backend = tdbsam
   min protocol = SMB3
   smb encrypt = required
   server signing = mandatory
   vfs objects = zfsacl
   hosts allow = 10.10.10.0/24 10.10.20.0/24
   hosts deny = 0.0.0.0/0

[projects]
   path = /tank/storage/projects
   valid users = @bioinfo-users
   read only = no
   create mask = 0660
   directory mask = 2770
   force group = bioinfo-users

[reference]
   path = /tank/reference
   valid users = @bioinfo-users
   read only = yes

[dropbox]
   path = /tank/storage/incoming
   valid users = @bioinfo-users
   read only = no
   create mask = 0660
   directory mask = 2770
```

```bash
sudo testparm -s
sudo smbstatus
sudo pdbedit -L
systemctl status smbd nmbd
```

---

## 13. Snapshot, Replikasi, & Scrub

### 13.1 Kebijakan snapshot (`sanoid`)

| Dataset | frequently | hourly | daily | weekly | monthly | yearly |
|---|---|---|---|---|---|---|
| `tank/home` | 4 | 24 | 30 | 8 | 12 | 2 |
| `tank/storage/projects` | 0 | 12 | 30 | 8 | 12 | 3 |
| `tank/storage/raw` | 0 | 0 | 14 | 4 | 12 | 5 |
| `tank/reference` | 0 | 0 | 7 | 4 | 6 | 1 |
| `tank/containers` | 0 | 0 | 7 | 4 | 3 | 0 |
| `tank/backup` | 0 | 0 | 14 | 4 | 3 | 0 |

`/etc/sanoid/sanoid.conf` (potongan):
```ini
[tank/home]
        use_template = production
        frequently = 4
        hourly = 24
        daily = 30
        monthly = 12
        yearly = 2

[tank/storage/projects]
        use_template = production
        hourly = 12
        daily = 30
        monthly = 12
        yearly = 3

[template_production]
        autosnap = yes
        autoprune = yes
```

### 13.2 Replikasi off-site

| Field | Nilai |
|---|---|
| **Tool** | `syncoid` (bagian dari sanoid) |
| **Target** | `storage-node-02` di gedung berbeda (`10.10.20.51`) |
| **Dataset direplikasi** | `tank/home`, `tank/storage/projects`, `tank/reference` |
| **Jadwal** | Harian 01:00 |
| **Metode** | Incremental `zfs send -I` melalui SSH |
| **RPO** | 24 jam |
| **RTO** | ± 4 jam |
| **Status Verifikasi Restore Terakhir** | `2026-07-19` — sukses |

```bash
syncoid --recursive --no-sync-snap \
        tank/storage/projects \
        root@10.10.20.51:tank2/storage/projects
```

> ⚠️ **`tank/storage/raw` (61 TiB) tidak direplikasi** karena keterbatasan kapasitas
> target. Salinan asli data mentah ada di LTO tape / drive sequencer.
> **Ini adalah risiko yang diketahui dan diterima** — dicatat di Known Issues.

### 13.3 Scrub

| Field | Nilai |
|---|---|
| **Jadwal** | Minggu pertama tiap bulan, pukul 00:00 |
| **Timer** | `zfs-scrub-monthly@tank.timer` |
| **Durasi tipikal** | 30–36 jam pada 148 TiB terpakai |
| **Dampak performa** | Throughput turun ± 20% selama scrub |
| **Scrub terakhir** | `2026-08-03`, 0 error, 0 diperbaiki |

```bash
sudo zpool scrub tank
sudo zpool scrub -s tank           # hentikan
zpool status tank | grep scan
systemctl list-timers | grep zfs
```

### 13.4 Perintah snapshot manual

```bash
zfs list -t snapshot -o name,used,creation -s creation | tail -20
zfs snapshot tank/storage/projects@pre-maintenance-2026-09-05
zfs rollback tank/storage/projects@pre-maintenance-2026-09-05    # HATI-HATI
zfs destroy tank/storage/projects@snapshot-lama

# Restore file tunggal tanpa rollback (paling aman)
ls /tank/storage/projects/.zfs/snapshot/
cp /tank/storage/projects/.zfs/snapshot/autosnap_2026-08-27_00:00:01_daily/proyek-A/hasil.vcf.gz \
   /tank/storage/projects/proyek-A/hasil-restored.vcf.gz
```

---

## 14. Baseline Performa

| Metrik | Nilai Terukur | Cara Ukur | Tanggal |
|---|---|---|---|
| Baca sekuensial lokal | 3.8 GB/s | `fio bs=1M iodepth=32 rw=read` | 2026-06-20 |
| Tulis sekuensial lokal | 2.6 GB/s | `fio bs=1M iodepth=32 rw=write` | 2026-06-20 |
| Baca via NFS (1 klien) | 2.7 GB/s | `fio` di `hpc-node-01` | 2026-06-20 |
| Tulis via NFS (1 klien) | 2.1 GB/s | `fio` di `hpc-node-01` | 2026-06-20 |
| IOPS metadata (`stat`) | ± 180.000/s | `mdtest` | 2026-06-20 |
| Latency NFS rata-rata | 4.2 ms | `nfsiostat` | 2026-08-15 |
| ARC hit ratio | 94.3% | `arc_summary` | 2026-08-15 |

> Jalankan ulang benchmark setelah setiap perubahan hardware/pool
> dan perbarui tabel ini. Baseline yang tidak diperbarui tidak berguna.

---

## 15. Health Check Cepat

```bash
#!/usr/bin/env bash
# quick-health-check storage-node-01
echo "=== IDENTITAS ==="   ; hostnamectl; sudo dmidecode -s system-serial-number
echo "=== UPTIME ==="      ; uptime
echo "=== ZPOOL ==="       ; zpool status -v; zpool list -v
echo "=== KAPASITAS ==="   ; zfs list -o name,used,avail,refer,compressratio,quota
echo "=== ARC ==="         ; arc_summary | head -30
echo "=== SMART ==="       ; for d in /dev/sd?; do printf "%s " "$d"; sudo smartctl -H "$d" | grep -i overall; done
echo "=== SUHU DISK ==="   ; for d in /dev/sd?; do printf "%s " "$d"; sudo smartctl -A "$d" | awk '/Temperature_Celsius/{print $10}'; done
echo "=== NFS ==="         ; sudo exportfs -v; nfsstat -s | head -20; cat /proc/fs/nfsd/threads
echo "=== SAMBA ==="       ; sudo smbstatus --shares 2>/dev/null | head -20
echo "=== SNAPSHOT ==="    ; zfs list -t snapshot | tail -10
echo "=== NETWORK ==="     ; ip -br addr; cat /proc/net/bonding/bond0 | grep -E 'Status|MII'
echo "=== SERVICE GAGAL ==="; systemctl --failed
echo "=== ZFS EVENT ==="   ; sudo zpool events -v | tail -30
```

---

## 16. Riwayat Perubahan Node Ini

| Tanggal | Jenis | Ringkasan | Ref |
|---|---|---|---|
| 2024-06-18 | Instalasi | Go-live, pool `tank` 2× raidz2, 200 TB raw | `SCL-2024-002` |
| 2024-12-05 | Ekspansi | Tambah vdev `raidz2-2` (8× 18 TB), kapasitas naik ke 432 TB raw | `SCL-2024-018` |
| 2025-03-22 | Upgrade | Tambah special vdev mirror 2× NVMe 1.92 TB — listing direktori jadi ±6× lebih cepat | `SCL-2025-004` |
| 2025-08-11 | Hardware | Ganti disk Bay 12, SMART FAILED, resilver 19 jam | `MNT-2025-012` |
| 2025-11-03 | Network | 10GbE → dual 25GbE LACP, MTU 9000, `nfsd` thread 64 → 128 | `SCL-2025-016` |
| 2026-03-09 | Hardware | Ganti disk Bay 7 (wear + pending sector), serial `X008` baru | `MNT-2026-004` |
| 2026-06-14 | Software | OpenZFS 2.1.15 → 2.2.4, aktifkan `autotrim` | `SCL-2026-006` |

---

## 17. Known Issues & Risiko

| ID | Deskripsi | Dampak | Mitigasi | Status |
|---|---|---|---|---|
| `KI-S01` | `tank/storage/raw` (61 TiB) tidak direplikasi off-site | Kehilangan data mentah jika node hancur total | Salinan asli di LTO tape & drive sequencer; usulan tambah kapasitas `storage-node-02` | Risiko diterima |
| `KI-S02` | Bay 6 (`X007`) 5 pending sector | Belum berdampak (raidz2 masih toleran 2 disk) | Disk pengganti sudah tersedia, ganti di jendela berikutnya | Terjadwal |
| `KI-S03` | Tidak ada SLOG; NFS `sync` write bergantung special vdev | Latency tulis sync bisa naik saat pool sibuk | Pantau `nfsiostat`; evaluasi Optane SLOG di anggaran berikutnya | Dipantau |
| `KI-S04` | Single point of failure — tidak ada HA storage | Cluster berhenti total jika node ini mati | PSU redundan + UPS + spare part on-site + RTO 4 jam | Risiko diterima |
| `KI-S05` | Scrub bulanan turunkan throughput ± 20% | Job jadi lebih lambat di awal bulan | Scrub dijadwalkan Minggu dini hari | Diterima |

---

## 18. Lampiran — Gambar & Diagram

| Gambar | Path | Keterangan |
|---|---|---|
| Foto rak | `../../assets/images/racks/storage-node-01-rack.png` | Posisi RU 02–05 |
| Peta bay disk | `../../assets/images/diagrams/storage-node-01-disk-bay-map.png` | Nomor bay ↔ serial ↔ vdev |
| Topologi ZFS | `../../assets/images/diagrams/storage-node-01-zfs-topology.png` | Struktur vdev & spare |
| Screenshot `zpool status` | `../../assets/images/screenshots/storage-node-01-zpool-status.png` | Kondisi pool sehat |
| Grafik kapasitas | `../../assets/images/screenshots/storage-node-01-capacity-trend.png` | Tren pemakaian 12 bulan |

```markdown
![Peta bay disk storage-node-01](../../assets/images/diagrams/storage-node-01-disk-bay-map.png)
```

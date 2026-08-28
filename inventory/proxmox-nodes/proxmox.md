# proxmox — Proxmox VE Host (Bare-Metal)

> **Tipe Unit:** Bare-Metal Hypervisor Host — 1 chassis fisik
> **Status:** 🟢 Production
> **Terakhir Diperbarui:** 2026-08-28
> **PIC Node:** *(isi nama sysadmin)*
> **Sumber Data:** auto-collect via SSH — `scripts/collect-proxmox.sh`, 2026-08-28 14:28 WIB
> **Dokumen Terkait:** [server-changelog](../../track-record/server-changelog.md) · [maintenance-log](../../track-record/maintenance-log.md) · [Panduan Penginputan](../../docs/penginputan-node.md)

> **Peran node ini:** hypervisor tunggal (standalone, non-cluster) yang menjalankan
> VM pengembangan pipeline bioinformatika, sekaligus merangkap **host penyimpanan
> arsip 140 TB** (pool `zfs-storage`) dan target backup lokal (`backup-pool`).

---

## 1. Identitas & Aset Fisik

| Field | Nilai |
|---|---|
| **Hostname (short)** | `proxmox` |
| **FQDN** | `proxmox.server` |
| **Alias / Label Fisik** | *(isi label di chassis)* |
| **Vendor** | Supermicro |
| **Model Sistem** | Super Server *(nama generik dari DMI)* |
| **Motherboard** | Supermicro **H12SSL-I** (socket SP3, 8-channel DDR4) |
| **Tipe Chassis** | Main Server Chassis |
| **Serial Number (DMI)** | `0123456789` ⚠️ *default pabrik, belum diprogram — jangan dipakai sebagai identitas aset* |
| **Asset Tag (internal)** | *(isi — WAJIB, karena serial DMI tidak unik)* |
| **BIOS** | versi **3.3**, rilis **2025-03-28** |
| **Form Factor** | *(isi: rackmount xU / tower)* |
| **Tanggal Pembelian** | *(isi)* |
| **Tanggal Go-Live** | *(isi)* |
| **Garansi Berakhir** | *(isi)* |
| **Status Operasional** | 🟢 Production |

### 1.1 Lokasi Fisik

Belum terdata — field di bawah **tidak bisa** diambil lewat SSH, harus disurvei fisik.

| Field | Nilai |
|---|---|
| **Gedung / Ruang** | *(isi)* |
| **Nama Rak** | *(isi)* |
| **Posisi RU** | *(isi)* |
| **PDU A / PDU B** | *(isi)* |
| **PSU** | *(isi jumlah & watt)* |
| **Label Kabel** | *(isi)* |

---

## 2. Manajemen Out-of-Band (IPMI)

| Field | Nilai |
|---|---|
| **Tipe BMC** | Supermicro BMC (ASPEED), IPMI **2.0** |
| **Firmware BMC** | **1.05** |
| **IP IPMI** | `192.168.18.13/24` |
| **Sumber IP** | ⚠️ **DHCP** — sebaiknya dijadikan statis / reservasi DHCP |
| **Gateway** | `192.168.18.1` |
| **MAC BMC** | `7c:c2:55:c0:b5:da` |
| **VLAN 802.1q** | ⚠️ **Disabled** — IPMI satu segmen dengan jaringan data |
| **SNMP Community** | ⚠️ masih default `public` |
| **Bad Password Threshold** | 3 (auto-disable aktif) |
| **Cipher Suites** | 1,2,3,6,7,8,11,12,15,16,17 |
| **Kredensial** | simpan di password manager, entri `IPMI / proxmox` — **jangan tulis di sini** |

Perintah operasional:

```bash
ipmitool -I lanplus -H 192.168.18.13 -U <user> chassis power status
ipmitool -I lanplus -H 192.168.18.13 -U <user> sel list | tail -20
ipmitool -I lanplus -H 192.168.18.13 -U <user> sdr type Temperature
ipmitool -I lanplus -H 192.168.18.13 -U <user> chassis identify 60
```

---

## 3. Spesifikasi Hardware Host

### 3.1 CPU

| Field | Nilai |
|---|---|
| **Model** | AMD **EPYC 7B13** 64-Core Processor |
| **Socket terpasang** | 1 |
| **Core / Thread** | **64 core / 128 thread** (SMT aktif, 2 thread per core) |
| **Frekuensi** | min 1500 MHz — max **3541 MHz** (boost enabled) |
| **Cache** | L1d 2 MiB · L1i 2 MiB · L2 32 MiB · **L3 256 MiB** (8× 32 MiB) |
| **NUMA** | 1 node (NPS1) — semua 128 thread di `node0` |
| **Virtualisasi** | AMD-V (SVM), NPT aktif |
| **Mitigasi** | semua tertutup; `Spec rstack overflow: Safe RET`, `Tsa: Clear CPU buffers` |

### 3.2 Memory (RAM)

| Field | Nilai |
|---|---|
| **Total terpasang** | **256 GB** (terbaca OS: 251 GiB) |
| **Tipe** | DDR4 ECC RDIMM, **3200 MT/s** |
| **Konfigurasi** | 4× 64 GB Micron |
| **Slot terisi** | **4 dari 8** — `DIMMC1`, `DIMMD1`, `DIMMG1`, `DIMMH1` |
| **Slot kosong** | `DIMMA1`, `DIMMB1`, `DIMME1`, `DIMMF1` |
| **Swap** | **0 B** (tidak ada swap) |
| **ECC** | Multi-bit ECC aktif |

Detail modul:

| Slot | Bank | Ukuran | Part Number | Vendor | Rank | Speed |
|---|---|---|---|---|---|---|
| `DIMMC1` | P0_Node0_Channel2 | 64 GB | `36ASF8G72PZ-3G2B2` | Micron | 2 | 3200 MT/s |
| `DIMMD1` | P0_Node0_Channel3 | 64 GB | `36ASF8G72PZ-3G2B2` | Micron | 2 | 3200 MT/s |
| `DIMMG1` | P0_Node0_Channel6 | 64 GB | `36ASF8G72PZ-3G2E1` | Micron | 2 | 3200 MT/s |
| `DIMMH1` | P0_Node0_Channel7 | 64 GB | `36ASF8G72PZ-3G2E1` | Micron | 2 | 3200 MT/s |

> ⚠️ **Catatan bandwidth:** H12SSL-I / EPYC SP3 adalah platform **8-channel**.
> Dengan hanya 4 channel terisi, bandwidth memori berjalan **±50% dari maksimum**.
> Untuk workload bioinformatika yang memory-bandwidth-bound (assembly, index STAR),
> ini penalti nyata. Lihat [§12 Known Issues](#12-known-issues--risiko).

### 3.3 Jaringan

| Interface | MAC | Status | Speed | MTU | Keterangan |
|---|---|---|---|---|---|
| `nic0` | `7c:c2:55:c0:b7:ea` | 🟢 UP | **1000 Mb/s** | 1500 | uplink aktif, slave `vmbr0` |
| `nic1` | `7c:c2:55:c0:b7:eb` | ⚪ DOWN | — | 1500 | belum dipakai |
| `nic2` | `be:3a:f2:b6:05:9f` | ⚪ DOWN | — | 1500 | belum dipakai |
| `vmbr0` | `7c:c2:55:c0:b7:ea` | 🟢 UP | — | 1500 | bridge utama |

| Field | Nilai |
|---|---|
| **IP Host** | `192.168.18.190/24` (di `vmbr0`) |
| **Gateway** | `192.168.18.1` |
| **DNS** | `192.168.18.1` |
| **Search domain** | `server` |
| **VLAN** | **tidak ada** — jaringan flat |
| **Bonding** | **tidak ada** |
| **Jumbo frame** | tidak aktif (MTU 1500) |

`/etc/network/interfaces`:

```
auto lo
iface lo inet loopback

iface nic0 inet manual

auto vmbr0
iface vmbr0 inet static
	address 192.168.18.190/24
	gateway 192.168.18.1
	bridge-ports nic0
	bridge-stp off
	bridge-fd 0

iface nic1 inet manual
iface nic2 inet manual

source /etc/network/interfaces.d/*
```

Bridge tambahan `fwbr100i0` dibuat otomatis oleh PVE karena VM 100 mengaktifkan `firewall=1`.

---

## 4. Proxmox VE & Sistem Operasi

| Field | Nilai |
|---|---|
| **Proxmox VE** | **9.2.0** (`pve-manager 9.2.10 / 43df2e01f27a1a19`) |
| **OS Dasar** | Debian GNU/Linux **13 (trixie)** |
| **Kernel** | `7.0.14-11-pve` (build 2026-08-06) |
| **Kernel cadangan** | `7.0.2-6-pve-signed` |
| **ZFS** | `zfsutils-linux 2.4.3-pve1` |
| **QEMU** | `pve-qemu-kvm 11.0.3-2` |
| **LXC** | `pve-container 6.1.13` / `lxc-pve 7.0.0-2` |
| **Backup client** | `proxmox-backup-client 4.2.5-1` |
| **Microcode AMD** | `3.20251202.1~bpo13+1` |
| **Web UI** | `https://192.168.18.190:8006` |

### 4.1 Cluster

| Field | Nilai |
|---|---|
| **Mode** | **Standalone** — bukan bagian dari cluster |
| **corosync** | `inactive` (wajar untuk standalone) |
| **`/etc/pve/corosync.conf`** | tidak ada |
| **High Availability** | ❌ tidak tersedia |

### 4.2 Status layanan

| Service | Status |
|---|---|
| `pve-cluster` | 🟢 active |
| `pvedaemon` | 🟢 active |
| `pveproxy` | 🟢 active |
| `pvestatd` | 🟢 active |
| `corosync` | ⚪ inactive (by design) |
| systemd failed units | **0** |

---

## 5. Inventaris Disk Fisik

Total **13 perangkat**: 11× HDD 14 TB (terenkripsi, anggota `zfs-storage`),
1× HDD 12 TB (`backup-pool`), 1× NVMe 4 TB (OS + scratch).

| Dev | Model | Kapasitas | Serial | Firmware | RPM | Peran | SMART |
|---|---|---|---|---|---|---|---|
| `sdk` | WDC WUH721414ALE604 (Ultrastar DC HC530) | 14 TB | `9RG6B5GC` | LDGNW240 | 7200 | LUKS → `crypt0` → `zfs-storage` | ✅ PASSED |
| `sde` | WDC WUH721414ALE604 | 14 TB | `9RG7XTEC` | LDGNW240 | 7200 | LUKS → `crypt1` → `zfs-storage` | ✅ PASSED |
| `sdg` | WDC WUH721414ALE604 | 14 TB | `9RG846NC` | LDGNW240 | 7200 | LUKS → `crypt2` → `zfs-storage` | ✅ PASSED |
| `sdf` | WDC WUH721414ALE604 | 14 TB | `9RG8MLPC` | LDGNW240 | 7200 | LUKS → `crypt3` → `zfs-storage` | ✅ PASSED |
| `sdj` | WDC WUH721414ALE604 | 14 TB | `QGK914ZT` | LDAZW110 | 7200 | LUKS → `crypt4` → `zfs-storage` | ✅ PASSED |
| `sdb` | WDC WUH721414ALE604 | 14 TB | `QGKL21LT` | LDAZW110 | 7200 | LUKS → `crypt5` → `zfs-storage` | ✅ PASSED |
| `sdl` | WDC WUH721414ALE604 | 14 TB | `QGKNJKYT` | LDAZW110 | 7200 | LUKS → `crypt6` → `zfs-storage` | ✅ PASSED |
| `sdc` | WDC WUH721414ALE604 | 14 TB | `QGKNXDKT` | LDAZW110 | 7200 | LUKS → `crypt7` → `zfs-storage` | ✅ PASSED |
| `sdi` | WDC WUH721414ALE604 | 14 TB | `QGKNZA2T` | LDAZW110 | 7200 | LUKS → `crypt8` → `zfs-storage` | ✅ PASSED |
| `sdh` | WDC WUH721414ALE604 | 14 TB | `QGKR02WT` | LDAZW110 | 7200 | LUKS → `crypt9` → `zfs-storage` | ✅ PASSED |
| `sda` | WDC WUH721414ALE604 | 14 TB | `QGKR4G5T` | LDAZW110 | 7200 | LUKS → `crypt10` → `zfs-storage` | ✅ PASSED |
| `sdd` | OOS12000G | 12 TB | `0000SW4L` | OOS1 | 7200 | `backup-pool` (single, tanpa redundansi) | ✅ PASSED |
| `nvme0n1` | Lexar SSD NM790 4TB | 4.09 TB | `NJP380R000758P2202` | 12237 | SSD | `p3` → `rpool` · `p4` → `nvme-scratch` | ✅ PASSED |

> **Campuran firmware:** 4 disk di `LDGNW240`, 7 disk di `LDAZW110`.
> Bukan masalah untuk ZFS, tapi perlu dicatat saat ada kampanye update firmware.

### 5.1 Enkripsi disk

11 HDD anggota `zfs-storage` berada di atas **LUKS** (`crypt0`–`crypt10`),
bukan native ZFS encryption. Konsekuensi operasional:

- Pool **tidak akan otomatis online** setelah reboot sampai LUKS di-unlock.
- Kunci / passphrase LUKS **wajib** ada di password manager — kalau hilang, 140 TB tidak bisa dibuka.
- Prosedur unlock & urutan boot **belum terdokumentasi** — lihat [§12](#12-known-issues--risiko).

Layout partisi NVMe:

```
nvme0n1  3.7T  Lexar SSD NM790 4TB
├─p1   1007K   BIOS boot
├─p2      1G   EFI System Partition
├─p3    199G   rpool        (OS Proxmox + disk VM)
└─p4    3.5T   nvme-scratch (scratch cepat / disk VM)
```

---

## 6. ZFS Pool

### 6.1 Ringkasan

| Pool | Topologi | Raw | Alloc | Free | Pakai | Redundansi | Health |
|---|---|---|---|---|---|---|---|
| `zfs-storage` | **raidz2** 11× `crypt` (14 TB) | 140 T | 15.7 T | 124 T | 11% | ✅ tahan 2 disk mati | 🟢 ONLINE |
| `backup-pool` | **single disk** `ata-OOS12000G_0000SW4L` | 10.9 T | 10.1 T | 779 G | **93%** | ❌ **tidak ada** | 🟢 ONLINE |
| `nvme-scratch` | **single vdev** `nvme0n1p4` | 3.52 T | 2.60 T | 942 G | **73%** | ❌ tidak ada | 🟢 ONLINE |
| `rpool` | **single vdev** `nvme0n1p3` | 198 G | 55.4 G | 143 G | 28% | ❌ tidak ada | 🟢 ONLINE |

> ⚠️ Tiga dari empat pool **tanpa redundansi**, dan `rpool` + `nvme-scratch`
> berbagi **satu NVMe fisik yang sama**. Satu NVMe mati = OS dan scratch hilang bersamaan.

### 6.2 Topologi `zfs-storage`

```
zfs-storage                    ONLINE
└─ raidz2-0                    ONLINE   (11 disk, parity 2)
   ├─ crypt0   ← sdk  9RG6B5GC
   ├─ crypt1   ← sde  9RG7XTEC
   ├─ crypt2   ← sdg  9RG846NC
   ├─ crypt3   ← sdf  9RG8MLPC
   ├─ crypt4   ← sdj  QGK914ZT
   ├─ crypt5   ← sdb  QGKL21LT
   ├─ crypt6   ← sdl  QGKNJKYT
   ├─ crypt7   ← sdc  QGKNXDKT
   ├─ crypt8   ← sdi  QGKNZA2T
   ├─ crypt9   ← sdh  QGKR02WT
   └─ crypt10  ← sda  QGKR4G5T
```

Kapasitas efektif yang dilaporkan ZFS: **±106 TB** (11.9 T terpakai + 94.6 T tersedia).

### 6.3 Properti & tuning

| Pool | compression | recordsize | Catatan |
|---|---|---|---|
| `zfs-storage` | `lz4` | **1M** | cocok untuk file arsip besar |
| `nvme-scratch` | `lz4` | **1M** | zvol VM pakai `volblocksize 16K` |
| `backup-pool` | `on` (lz4) | 128K | |
| `rpool` | `on` (lz4) | 128K | zvol VM `volblocksize 16K` |

| Parameter | Nilai |
|---|---|
| `zfs_arc_max` | `214748364800` = **200 GiB** |

> ⚠️ ARC max 200 GiB pada host 251 GiB, sementara VM mengalokasikan 72 GiB.
> 200 + 72 = 272 GiB > 251 GiB. ARC memang menyusut di bawah tekanan,
> tapi marginnya tipis saat VM 200 menyala — lihat [§12](#12-known-issues--risiko).

### 6.4 Riwayat scrub

| Pool | Scrub terakhir | Durasi | Hasil |
|---|---|---|---|
| `zfs-storage` | 2026-08-17 18:56 | 03:06:40 | ✅ 0 error |
| `backup-pool` | 2026-08-16 05:00 | 13:53:31 | ✅ 0 error |
| `nvme-scratch` | 2026-08-15 03:54 | 00:08:09 | ✅ 0 error |
| `rpool` | ⚠️ **belum pernah tercatat** | — | — |

Semua pool melaporkan `errors: No known data errors`.

---

## 7. Dataset & Mount Point

### 7.1 Dataset `zfs-storage`

| Dataset | Mount | Terpakai | Isi |
|---|---|---|---|
| `zfs-storage/archive/DATA-PENELITI` | `/zfs-storage/archive/DATA-PENELITI` | **3.43 T** | data peneliti |
| `zfs-storage/archive/DATA_WGS_DEL_UGJ` | `/zfs-storage/archive/DATA_WGS_DEL_UGJ` | **3.04 T** | dataset WGS |
| `zfs-storage/archive/backup_nvme` | `/zfs-storage/archive/backup_nvme` | **2.99 T** | salinan isi NVMe |
| `zfs-storage/archive/vm-images` | `/zfs-storage/archive/vm-images` | **1.30 T** | image VM |
| `zfs-storage/archive/Folder-IT` | `/zfs-storage/archive/Folder-IT` | **1.13 T** | arsip IT |
| `zfs-storage/archive/TO_ANALISIS` | `/zfs-storage/archive/TO_ANALISIS` | 46.0 G | antrean analisis |
| `zfs-storage/archive/backup-config` | `/zfs-storage/archive/backup-config` | 281 M | backup konfigurasi |
| `zfs-storage/reference/software` | `/zfs-storage/reference/software` | 9.14 G | installer / software |

### 7.2 Dataset `rpool` & lainnya

| Dataset | Mount | Terpakai |
|---|---|---|
| `rpool/ROOT/pve-1` | `/` | 6.67 G |
| `rpool/var-lib-vz` | `/var/lib/vz` | 27.5 G |
| `rpool/data/vm-100-disk-0` | zvol VM 100 | 15.7 G |
| `rpool/data/vm-200-disk-1` | zvol VM 200 | 5.58 G |
| `nvme-scratch/vm-200-disk-0` | zvol VM 200 (scsi1) | 56 K |
| `backup-pool` | `/backup-pool` | **10.1 T** |

### 7.3 Storage terdaftar di Proxmox

| Name | Type | Content | Status | Total | Pakai |
|---|---|---|---|---|---|
| `local` | dir (`/var/lib/vz`) | backup, vztmpl, import, iso | 🟢 active | 164 G | 16.8% |
| `local-zfs` | zfspool (`rpool/data`) | rootdir, images (sparse) | 🟢 active | 158 G | 13.5% |
| `nvme-scratch` | zfspool (`/nvme-scratch`) | images, rootdir (sparse) | 🟢 active | 3.5 T | **76.2%** |

`/etc/pve/storage.cfg`:

```
dir: local
	path /var/lib/vz
	content backup,vztmpl,import,iso

zfspool: local-zfs
	pool rpool/data
	content rootdir,images
	sparse 1

zfspool: nvme-scratch
	pool nvme-scratch
	content images,rootdir
	mountpoint /nvme-scratch
	sparse 1
```

> ⚠️ **`zfs-storage` (140 TB) dan `backup-pool` (11 TB) tidak terdaftar sebagai
> storage Proxmox.** Keduanya hanya diakses dari sisi host / lewat virtiofs.
> Artinya kapasitas terbesar di mesin ini tidak terlihat di UI Proxmox dan
> tidak bisa jadi target `vzdump` tanpa didaftarkan lebih dulu.

---

## 8. Daftar VM & LXC

### 8.1 VM (KVM)

| VMID | Nama | Status | vCPU | RAM | Boot disk | Tags |
|---|---|---|---|---|---|---|
| **100** | `dev-pipeline` | 🟢 running | 24 | 8 GiB | 32 G (`local-zfs`) | `automation`, `dev` |
| **200** | `dev-bioinfo` | ⚪ stopped | 24 | 64 GiB (balloon 16 GiB) | 100 G (`local-zfs`) | `bioinformatika`, `dev` |

**VM 100 — `dev-pipeline`**

| Field | Nilai |
|---|---|
| CPU | 24 core, 1 socket, tipe `x86-64-v2-AES` |
| Memory | 8192 MB |
| Firmware / Machine | OVMF (UEFI) / `q35` |
| Disk | `local-zfs:vm-100-disk-0` 32 G, `iothread=1` |
| EFI disk | `local-zfs:vm-100-disk-1` 1 M |
| NIC | `virtio` `BC:24:11:C1:73:01` → `vmbr0`, **firewall=1** |
| Guest agent | aktif |
| ISO terpasang | `ubuntu-24.04.4-live-server-amd64.iso` |
| OS type | Linux 2.6+ (`l26`) |

**VM 200 — `dev-bioinfo`** — *VM pengembangan pipeline bioinformatika*

| Field | Nilai |
|---|---|
| CPU | 24 core, 1 socket, tipe **`host`** (passthrough penuh) |
| Memory | 65536 MB, balloon minimum 16384 MB |
| Firmware / Machine | OVMF (UEFI, `pre-enrolled-keys=0`) / `q35` |
| Disk OS | `local-zfs:vm-200-disk-1` 100 G, `ssd=1`, `discard=on`, `iothread=1` |
| Disk scratch | `nvme-scratch:vm-200-disk-0` **1 T**, `ssd=1`, `discard=on` |
| NIC | `virtio` `BC:24:11:44:79:8B` → `vmbr0`, **firewall=1** |
| **virtiofs** | `project-raw`, `project-results`, `reference` (semua `direct-io=1`) |
| Guest agent | aktif |

### 8.2 LXC Container

**Tidak ada container LXC.**

### 8.3 Ringkasan alokasi resource

| Resource | Host | Teralokasi ke VM | Sisa |
|---|---|---|---|
| Thread CPU | 128 | 48 (24 + 24) | 80 |
| RAM | 251 GiB | 72 GiB | 179 GiB *(dikurangi ARC hingga 200 GiB)* |
| Storage `local-zfs` | 158 G | ±21 G | — |
| Storage `nvme-scratch` | 3.5 T | 1 T (zvol VM 200, sparse) | — |

### 8.4 Perintah pengelolaan

```bash
qm list                             # daftar VM
qm config 200                       # konfigurasi satu VM
qm start 200                        # nyalakan
qm shutdown 200                     # matikan halus
qm snapshot 200 pre-upgrade         # snapshot sebelum perubahan
pct list                            # daftar container
pvesh get /nodes/proxmox/status     # status node via API
```

---

## 9. Backup

| Field | Status |
|---|---|
| **Job vzdump terjadwal** | ❌ **TIDAK ADA** — `/etc/pve/jobs.cfg` tidak ada |
| **`/etc/vzdump.conf`** | kosong (semua default) |
| **Isi `/var/lib/vz/dump/`** | **kosong** |
| **Proxmox Backup Server** | tidak terkonfigurasi (client `4.2.5-1` terpasang) |
| **Snapshot ZFS terjadwal** | tidak terdeteksi (tidak ada sanoid / zfs-auto-snapshot) |

> 🔴 **VM 100 dan VM 200 saat ini tidak punya backup sama sekali.**
> `backup-pool` (10.1 T terpakai) memang berisi data, tapi **bukan** hasil `vzdump`
> dan tidak dikelola oleh Proxmox. Ini risiko tertinggi di node ini.

Backup manual sementara, sampai job terjadwal dibuat:

```bash
# Daftarkan dulu sebuah storage bertipe backup, lalu:
vzdump 100 --storage <nama-storage> --mode snapshot --compress zstd
vzdump 200 --storage <nama-storage> --mode stop     --compress zstd
```

---

## 10. Keamanan

| Field | Nilai |
|---|---|
| **User Proxmox** | hanya `root@pam` (email `ilham@dharma.or.id`) |
| **2FA / TFA** | ❌ tidak aktif |
| **API Token** | tidak ada |
| **Firewall cluster** | ❌ `/etc/pve/firewall/cluster.fw` tidak ada |
| **Firewall host** | ❌ tidak ada berkas `*.fw` |
| **Firewall VM** | `firewall=1` di VM 100 & 200 — tapi **tidak berefek** selama firewall datacenter belum diaktifkan |
| **SSH `PermitRootLogin`** | ⚠️ `yes` |
| **SSH port** | 22 (default) |
| **SNMP BMC** | ⚠️ community `public` |

---

## 11. Health Check Cepat

```bash
#!/bin/bash
# quick-health-check proxmox
echo "=== UPTIME & LOAD ==="   ; uptime
echo "=== PVE VERSION ==="     ; pveversion
echo "=== ZFS POOL ==="        ; zpool list
echo "=== ZFS HEALTH ==="      ; zpool status -x
echo "=== KAPASITAS ==="       ; df -h / /var/lib/vz /nvme-scratch /backup-pool /zfs-storage
echo "=== VM ==="              ; qm list
echo "=== LUKS ==="            ; ls /dev/mapper/crypt* 2>/dev/null | wc -l   # harus 11
echo "=== SMART ==="           ; for d in /dev/sd? /dev/nvme0n1; do printf "%-14s " "$d"; smartctl -H "$d" | grep -i 'overall-health'; done
echo "=== SERVICE GAGAL ==="   ; systemctl --failed --no-pager
echo "=== MEMORY ==="          ; free -h
```

Ambang yang perlu tindakan:

| Indikator | Ambang | Kondisi sekarang |
|---|---|---|
| Kapasitas pool | > 80% | `backup-pool` **93%** 🔴 · `nvme-scratch` 73% 🟡 |
| SMART `Reallocated_Sector_Ct` | > 0 dan naik | semua disk PASSED ✅ |
| Jumlah device `crypt*` | harus **11** | 11 ✅ |
| Scrub terakhir | > 35 hari | `zfs-storage` 11 hari ✅ · `rpool` belum pernah ⚠️ |
| systemd failed units | > 0 | 0 ✅ |

---

## 12. Known Issues & Risiko

Diurutkan dari dampak paling besar. Semua temuan berasal dari pengumpulan data
**2026-08-28**; belum ada yang ditindaklanjuti.

| # | Temuan | Dampak | Prioritas |
|---|---|---|---|
| 1 | **Tidak ada backup VM sama sekali** — tidak ada job vzdump, dump dir kosong | VM 100 & 200 hilang permanen bila `rpool` / NVMe gagal | 🔴 Kritis |
| 2 | **`backup-pool` 93% penuh, single disk tanpa redundansi**, berisi 10.1 T data | 1 disk mati = 10 T hilang. Di atas 90% performa ZFS juga anjlok | 🔴 Kritis |
| 3 | **Passphrase LUKS & prosedur unlock belum terdokumentasi** | Kunci hilang = 140 TB `zfs-storage` tidak bisa dibuka selamanya | 🔴 Kritis |
| 4 | **`rpool` dan `nvme-scratch` berbagi satu NVMe fisik**, keduanya tanpa redundansi | 1 NVMe mati = OS hypervisor + scratch + disk VM hilang serentak | 🔴 Kritis |
| 5 | **Firewall Proxmox tidak aktif** (tidak ada `cluster.fw` / host `.fw`) | `firewall=1` di kedua VM tidak berefek; host & VM terbuka di LAN | 🟠 Tinggi |
| 6 | **IPMI satu segmen dengan jaringan data** (`192.168.18.13`, VLAN disabled) + **DHCP** | BMC bisa dijangkau siapa pun di LAN; IP bisa berubah sewaktu-waktu | 🟠 Tinggi |
| 7 | **RAM hanya mengisi 4 dari 8 channel** | Bandwidth memori ±50% dari kemampuan platform — terasa di assembly & index STAR | 🟠 Tinggi |
| 8 | **Uplink hanya 1 GbE** (`nic0`), `nic1` / `nic2` menganggur | Melayani 140 TB lewat pipa 1 Gb/s (±3 jam per TB); bonding belum dimanfaatkan | 🟠 Tinggi |
| 9 | **`zfs-storage` & `backup-pool` tidak terdaftar sebagai storage PVE** | Kapasitas terbesar tak terlihat di UI, tidak bisa jadi target `vzdump` | 🟡 Sedang |
| 10 | **`zfs_arc_max` 200 GiB** vs RAM 251 GiB dengan alokasi VM 72 GiB | Overcommit; ARC menyusut, tapi margin tipis saat VM 200 menyala | 🟡 Sedang |
| 11 | **SNMP BMC masih community `public`** | Informasi sensor & inventaris terbaca tanpa autentikasi | 🟡 Sedang |
| 12 | **`PermitRootLogin yes`**, hanya user `root@pam`, tanpa 2FA | Tidak ada pemisahan akun, tidak ada jejak audit per-orang | 🟡 Sedang |
| 13 | **`rpool` belum pernah tercatat scrub** | Corruption diam-diam di pool OS tidak terdeteksi | 🟡 Sedang |
| 14 | **Serial DMI default `0123456789`** | Identitas aset tidak unik — wajib pakai asset tag fisik | 🟢 Rendah |
| 15 | **Firmware HDD campuran** (`LDAZW110` 7 disk, `LDGNW240` 4 disk) | Perlu diperhatikan saat update firmware massal | 🟢 Rendah |
| 16 | **Standalone, tanpa cluster** | Tidak ada HA / live migration; maintenance = downtime | 🟢 Rendah *(sesuai desain)* |
| 17 | **`lm-sensors` belum terpasang** | Suhu & fan hanya bisa dibaca lewat IPMI | 🟢 Rendah |
| 18 | **Tidak ada swap** | OOM langsung membunuh proses tanpa buffer | 🟢 Rendah *(umum di host ZFS)* |

---

## 13. Cara Memperbarui Dokumen Ini

Jalankan ulang kolektor, lalu bandingkan hasilnya dengan isi dokumen:

```bash
bash scripts/collect-proxmox.sh 192.168.18.190 > /tmp/pve-$(date +%F).txt
```

Prosedur lengkap ada di [`docs/penginputan-node.md`](../../docs/penginputan-node.md).
Setiap perubahan fisik / konfigurasi **wajib** dicatat juga di
[`track-record/server-changelog.md`](../../track-record/server-changelog.md).

---

## 14. Lampiran — Gambar & Diagram

Belum ada. Simpan foto rak di `assets/images/racks/proxmox-rack.png` lalu panggil:

```markdown
![Posisi rak proxmox](../../assets/images/racks/proxmox-rack.png)
```

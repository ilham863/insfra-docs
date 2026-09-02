# proxmox — Proxmox VE Host (Bare-Metal)

> **Tipe Unit:** Bare-Metal Hypervisor Host — 1 chassis fisik
> **Status:** 🟢 Production
> **Terakhir Diperbarui:** 2026-09-02
> **PIC Node:** *(isi nama sysadmin)*
> **Sumber Data:** auto-collect via SSH — `scripts/collect-proxmox.sh`, 2026-09-02 02:24 WIB
> · koleksi ulang **2026-09-02 02:40 WIB** (verifikasi silang saat pendataan `T4-Storage`)

> **Dokumen Terkait:** [vm-101-smrtlink](vm-101-smrtlink.md) · [server-changelog](../../track-record/server-changelog.md) · [maintenance-log](../../track-record/maintenance-log.md) · [Panduan Penginputan](../../docs/penginputan-node.md)

> **Riwayat VM 300 → VM 101.** VM 300 `vega` dibuat 2026-09-01 16:34 lalu
> **dihapus** 2026-09-02 02:29:45 (`qmdestroy:300` di task log). Perannya kini
> digantikan **VM 101 `ubuntu24-desktop`** yang dibuat 2026-09-02 — lihat
> [`vm-101-smrtlink.md`](vm-101-smrtlink.md).
>
> Sisa yang belum dibersihkan: dataset `zfs-storage/vega-storage` (kosong, tipe
> `dir`, digantikan `vm-hdd`) dan `nvme-scratch/vega-filesystem` (6,17 G).


> **Peran node ini:** hypervisor tunggal (standalone, non-cluster) yang menjalankan
> VM pengembangan pipeline bioinformatika, sekaligus merangkap **host penyimpanan
> arsip 140 TB** (pool `zfs-storage`) dan target backup lokal (`backup-pool`).
>
> Sejak 2026-09-02 node ini juga menjadi **host SMRT Link untuk sekuenser PacBio
> Vega** (**VM 101**) sekaligus **gateway/NAT instrumen** — lihat
> [§8.1](#81-vm-kvm) dan [`vm-101-smrtlink.md`](vm-101-smrtlink.md).
>
> Peran ini justru **sejalan** dengan [README §2.2](../../README.md#22-arsitektur-target--proxmox-sebagai-ingress-data)
> yang menetapkan `PROXMOX-2U` sebagai **ingress data** — data sekuenser masuk
> lewat satu pintu di sini sebelum disalurkan ke tier analisis.

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

### 2.1 Identitas Chassis (FRU) — 🆕 2026-09-02

Diambil **in-band** (`ipmitool fru print` lewat `/dev/ipmi0`), jadi tidak perlu
kredensial dan tidak ada password yang lewat jaringan.

| Field | Nilai |
|---|---|
| **Board Serial (FRU)** | ✅ **`ZM253S601908`** |
| **Board Manufacturer** | Supermicro |
| **Tanggal Produksi Board** | **2025-03-29 07:17 WIB** |
| **Product Serial** | *(kosong — belum diprogram)* |

> ✅ **Ini identitas aset yang sahih untuk `PROXMOX-2U`.** DMI hanya melaporkan
> `0123456789` — nilai default yang **sama persis** dengan `T4-Storage`, jadi
> tidak bisa dipakai membedakan aset. **Gunakan `ZM253S601908`** untuk klaim
> garansi dan pelacakan inventaris.
>
> Tanggal produksi board **2025-03-29** adalah acuan awal menghitung garansi
> (tanggal pembelian sebenarnya masih perlu diisi di §1).

### 2.2 Akun BMC

| ID | Nama | Callin | Link Auth | IPMI Msg | Privilege |
|---|---|---|---|---|---|
| 2 | `ADMIN` | false | false | true | **ADMINISTRATOR** |
| 1, 3–16 | *(kosong)* | — | — | — | Unknown (0x00) |

> 🟢 Hanya **satu** akun aktif — jauh lebih rapi daripada `HPC-GPU` yang punya
> tiga akun ADMINISTRATOR. BMC ini juga punya **`Bad Password Threshold: 3`**
> dengan auto-disable aktif, jadi ada perlindungan brute-force.

### 2.3 Status Chassis & Daya

| Field | Nilai |
|---|---|
| **System Power** | 🟢 on |
| **Power Restore Policy** | `previous` |
| **Power Overload / Fault** | false |
| **Chassis Intrusion** | inactive |
| **Drive Fault** | false |
| **Cooling/Fan Fault** | false |
| **PSU terpasang** | ✅ **2 unit** — `PS1` & `PS2`, keduanya *Presence detected* |

> ✅ **PSU redundan (2 unit) terkonfirmasi.** Ini menjawab field yang selama ini
> kosong di §1.1 — meski jalur PDU-nya masih perlu disurvei fisik.

### 2.4 Suhu & Fan (dari BMC) — 2026-09-02 03:00 WIB

| Sensor | Nilai | Status |
|---|---|---|
| CPU Temp | **54 °C** | 🟢 ok |
| System Temp | 37 °C | 🟢 ok |
| Peripheral Temp | 45 °C | 🟢 ok |
| CPU_VRM Temp | 41 °C | 🟢 ok |
| SOC_VRM Temp | 51 °C | 🟢 ok |
| VRMABCD / VRMEFGH Temp | 44 / 47 °C | 🟢 ok |
| P1_DIMMA~D / E~H Temp | 40 / 45 °C | 🟢 ok |
| **GPU1 Temp** | **47 °C** | 🟢 ok — Tesla T4 slot 6 |
| **GPU2 Temp** | **48 °C** | 🟢 ok — Tesla T4 slot 7 |
| M2_SSD1 / M2_SSD2 Temp | No Reading | ⚪ sensor tidak terpakai |

| Fan | RPM | Status |
|---|---|---|
| FAN5 | 2.520 | 🟢 ok |
| FANB | **16.940** | 🟢 ok ⚠️ *sangat tinggi* |
| FAN1–FAN4, FANA | No Reading | ⚠️ tidak terpasang / tidak terbaca |

> ⚠️ **Hanya 2 dari 7 slot fan yang memberi pembacaan.** Perlu diperiksa fisik:
> apakah FAN1–4 & FANA memang tidak terpasang (wajar untuk sebagian chassis),
> atau terpasang tapi mati. **FANB berputar 16.940 RPM** — itu fan kecil
> berkecepatan tinggi yang sedang bekerja keras; kalau ternyata fan lain mati,
> FANB sedang menanggung beban pendinginan sendirian.

### 2.5 System Event Log — ⚠️ ada kejadian berulang

| Field | Nilai |
|---|---|
| **Entri** | 216 |
| **Kapasitas terpakai** | 36% (296 dari 512 unit alokasi bebas) |
| **Overflow** | 🟢 false |
| **Entri terakhir** | 2026-09-02 02:08:14 WIB |

> ⚠️ **`System Firmwares | Unrecoverable IDE device failure` muncul berulang kali**
> dan masih berlanjut. Dari 15 entri terakhir, **10 di antaranya** adalah event
> ini — tercatat pada 26/08, 27/08, 28/08, 31/08 (2×), 01/09 (4×), dan
> **02/09 02:08:14 — persis pada saat boot terakhir**.
>
> Pada Supermicro, pesan ini biasanya muncul saat BIOS gagal menginisialisasi
> sebuah perangkat penyimpanan pada tahap POST. Kandidat penyebab: slot M.2 kedua
> (`PCI-E M.2-M2` terisi, tapi sensor `M2_SSD1`/`M2_SSD2` sama-sama *No Reading*),
> atau salah satu disk di HBA.
>
> **Belum berdampak pada operasional** — seluruh pool ZFS `ONLINE` dan SMART
> semua disk `PASSED`. Tapi ini bukan noise: kejadiannya berulang tiap boot dan
> perlu ditelusuri sebelum menjadikan node ini titik ingress seluruh data.
>
> ```bash
> ipmitool sel elist | grep -i 'IDE device'      # lihat seluruh riwayatnya
> dmesg | grep -iE 'ata[0-9]|nvme|failed|error'  # korelasikan dengan sisi OS
> journalctl -b -p err                            # error pada boot terakhir
> ```

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

| Interface | MAC | Status | Speed | MTU | Driver | Bus | Keterangan |
|---|---|---|---|---|---|---|---|
| `nic0` | `7c:c2:55:c0:b7:ea` | 🟢 UP | **1000 Mb/s** | 1500 | `tg3` | PCI | uplink aktif, slave `vmbr0` |
| `nic1` | `7c:c2:55:c0:b7:eb` | ⚪ DOWN *(no-carrier)* | — | 1500 | `tg3` | PCI | 🆕 slave **`vmbr1`** — dicadangkan untuk instrumen **PacBio Vega** |
| `nic2` | `be:3a:f2:b6:05:9f` | ⚪ DOWN | — | 1500 | `rndis_host` | **USB** | ⚠️ **bukan port fisik** — NIC virtual BMC |
| `vmbr0` | `7c:c2:55:c0:b7:ea` | 🟢 UP | — | 1500 | — | virtual | bridge utama, LAN `192.168.18.0/24` |
| **`vmbr1`** 🆕 | `7c:c2:55:c0:b7:eb` | ⚪ DOWN | — | 1500 | — | virtual | **segmen instrumen Vega** — host sengaja **tanpa IP**, VM 101 yang jadi gateway. Lihat [vm-101-smrtlink](vm-101-smrtlink.md) |

> ⚠️ **Koreksi dari pendataan 2026-08-28:** `nic2` sebelumnya tercatat sebagai port
> fisik "belum dipakai". Sebenarnya itu **NIC virtual USB dari BMC**
> (`Insyde RNDIS/Ethernet Gadget` di balik `SMCI Virtual Hub`), bukan ethernet.
> Node ini hanya punya **2 port ethernet fisik**, keduanya 1 GbE onboard
> (Broadcom BCM5720, `45:00.0` dan `45:00.1`).

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

### 3.4 GPU

> ⚠️ **Baru terdata 2026-09-02.** Dua GPU ini **tidak tercatat sama sekali** pada
> pendataan 2026-08-28 karena kolektor waktu itu belum memanggil `lspci`.
> Kolektor sudah diperbaiki — lihat [§13](#13-cara-memperbarui-dokumen-ini).

| Field | Nilai |
|---|---|
| **Jumlah GPU** | **2× NVIDIA Tesla T4** (TU104GL, `10de:1eb8`) |
| **VRAM** | 16 GB per kartu — total **32 GB** |
| **Alamat PCI** | `01:00.0` (CPU SLOT6) · `81:00.0` (CPU SLOT7) |
| **Link** | x16 @ 8 GT/s — kecepatan penuh (T4 adalah kartu PCIe 3.0) |
| **Driver aktif** | ⚠️ **`nouveau`** — bukan driver NVIDIA |
| **`nvidia-smi`** | ❌ tidak terpasang di host |
| **`vfio` / passthrough** | ❌ tidak dimuat; tidak ada VM dengan `hostpci` |
| **Status pemakaian** | 🔴 **menganggur total** |

> 🔴 Kedua T4 menyala dan memakan daya tapi **tidak dipakai siapa pun**.
> `nouveau` tidak mendukung CUDA, jadi untuk kartu compute headless seperti T4
> praktis tidak berguna. `nouveau` juga **menghalangi passthrough** — untuk
> melempar T4 ke VM, `nouveau` harus di-blacklist dan kartunya di-bind ke
> `vfio-pci`. Lihat [§12](#12-known-issues--risiko).

### 3.5 Okupansi Slot PCIe

Dari `dmidecode -t slot` — berguna saat merencanakan penambahan kartu (mis. NIC 10 GbE).

| Slot | Tipe | Status | Isi |
|---|---|---|---|
| CPU SLOT1 | PCIe 4.0 x16 | ⚪ Available | — |
| CPU SLOT2 | PCIe 4.0 x8 | ⚪ Available | — |
| CPU SLOT3 | PCIe 4.0 x16 | ⚪ Available | — |
| CPU SLOT4 | PCIe 4.0 x8 | ⚪ Available | — |
| CPU SLOT5 | PCIe 4.0 x16 | ⚪ Available | — |
| CPU SLOT6 | PCIe 4.0 x16 | 🟢 In Use | Tesla T4 (`01:00.0`) |
| CPU SLOT7 | PCIe 4.0 x16 | 🟢 In Use | Tesla T4 (`81:00.0`) |
| PCI-E M.2-M1 | M.2 Socket 3 | ⚪ Available | — |
| PCI-E M.2-M2 | M.2 Socket 3 | 🟢 In Use | Lexar NM790 4TB (`02:00.0`) |

**Lima slot PCIe masih kosong.** Kalau kartu tambahan tidak muncul di `lspci`
*dan* slot-nya tetap `Available` di `dmidecode`, artinya BIOS belum melihatnya —
periksa dudukan riser, bifurcation di BIOS, lalu coba slot x16 lain.

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
- `/etc/crypttab` memetakan `crypt0`–`crypt10` lewat **UUID** (stabil terhadap
  pergeseran huruf `sdX`), semuanya dengan opsi **`noauto`** — jadi unlock manual
  setelah tiap reboot memang disengaja, bukan kesalahan konfigurasi.

**Prosedur unlock setelah reboot** *(terverifikasi 2026-09-02)*:

```bash
read -rsp "Passphrase LUKS: " P; echo
for i in $(seq 0 10); do
  uuid=$(awk -v n="crypt$i" '$1==n{print $2}' /etc/crypttab | sed 's/UUID=//')
  printf '%s' "$P" | cryptsetup luksOpen UUID="$uuid" "crypt$i" -
done
unset P

ls /dev/mapper/crypt* | wc -l    # harus 11
zpool import zfs-storage
zpool status zfs-storage
```

> ⚠️ **Gejala kalau lupa unlock:** `zpool list` tidak menampilkan `zfs-storage`
> sama sekali dan `zpool import` menjawab *"no pools available to import"* —
> karena label ZFS berada **di dalam** container LUKS. Ini **bukan** kehilangan
> data. Verifikasi disknya masih ada dengan `lsblk` dan `cryptsetup isLuks`.
> Kejadian nyata: reboot 2026-09-02 02:08, pool offline sampai di-unlock manual.

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
| `nvme-scratch` | **single vdev** `nvme0n1p4` | 3.52 T | **6.17 G** | 3.51 T | **0%** | ❌ tidak ada | 🟢 ONLINE |
| `rpool` | **single vdev** `nvme0n1p3` | 198 G | 55.7 G | 142 G | 28% | ❌ tidak ada | 🟢 ONLINE |

> ⚠️ Tiga dari empat pool **tanpa redundansi**, dan `rpool` + `nvme-scratch`
> berbagi **satu NVMe fisik yang sama**. Satu NVMe mati = OS dan scratch hilang bersamaan.

> **Perubahan sejak 2026-08-28:** `nvme-scratch` turun dari **73% → 0%**.
> Isi lamanya (`Folder-IT` 1.3 T dan `vm-images` 1.4 T) sudah disalin ke
> `zfs-storage/archive/` lalu sumbernya dihapus pada 2026-09-01, untuk
> memberi ruang bagi disk VM 300. Jumlah file di salinan diverifikasi cocok
> (14.683 dan 5 file) sebelum penghapusan.

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

> ⚠️ ARC max **masih 200 GiB** pada host 251 GiB, sementara alokasi VM kini
> **136 GiB** (8 + 64 + 64) setelah VM 300 dibuat.
> 200 + 136 = **336 GiB** jauh melebihi 251 GiB. ARC memang menyusut di bawah
> tekanan, tapi host ini **tidak punya swap** — tidak ada bantalan kalau ARC
> kalah cepat dari permintaan QEMU. Lihat [§12](#12-known-issues--risiko).
>
> Saran: turunkan ke 64 GiB.
> ```bash
> echo "options zfs zfs_arc_max=68719476736" > /etc/modprobe.d/zfs.conf
> echo 68719476736 > /sys/module/zfs/parameters/zfs_arc_max   # langsung berlaku
> update-initramfs -u -k all
> ```

### 6.4 Riwayat scrub

| Pool | Scrub terakhir | Durasi | Hasil |
|---|---|---|---|
| `zfs-storage` | 2026-08-17 18:56 | 03:06:40 | ✅ 0 error |
| `backup-pool` | 2026-08-16 05:00 | 13:53:31 | ✅ 0 error |
| `nvme-scratch` | 2026-08-15 03:54 | 00:08:09 | ✅ 0 error |
| `rpool` | **2026-09-01 12:55** | 00:00:27 | ✅ 0 error |

Semua pool melaporkan `errors: No known data errors`.

> ✅ `rpool` di-scrub pertama kali pada 2026-09-01 — sebelumnya **belum pernah
> sekali pun** sejak pool dibuat 2026-08-13. Hasilnya bersih (`repaired 0B`),
> yang berarti OS dan disk VM utuh meskipun NVMe-nya mencatat **34 unsafe
> shutdown**. Ini menutup temuan #13 pendataan sebelumnya.
>
> ⚠️ **Scrub otomatis belum terbukti jalan.** `zfs-scrub-monthly@.timer` dan
> `zfs-scrub-weekly@.timer` keduanya `disabled`; yang aktif hanya cron Debian
> (`/etc/cron.d/zfsutils-linux`) yang menembak **Minggu kedua tiap bulan** —
> jadwal berikutnya **2026-09-13 00:24**, dan itu akan jadi kali pertamanya
> (sistem baru dibangun 2026-08-13, setelah Minggu kedua Agustus lewat).
> Cron itu juga men-scrub **keempat pool serentak**, padahal `backup-pool`
> sendiri butuh ~14 jam. Lebih baik pakai timer per-pool bergiliran:
>
> ```bash
> systemctl enable --now zfs-scrub-monthly@rpool.timer
> systemctl enable --now zfs-scrub-monthly@nvme-scratch.timer
> systemctl enable --now zfs-scrub-monthly@zfs-storage.timer
> systemctl enable --now zfs-scrub-monthly@backup-pool.timer
> ```

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
| **`zfs-storage/vega-storage`** | `/zfs-storage/vega-storage` | 219 K | 🆕 data run PacBio Vega — **quota 10 T** |

### 7.2 Dataset `rpool` & lainnya

| Dataset | Mount | Terpakai |
|---|---|---|
| `rpool/ROOT/pve-1` | `/` | 6.68 G |
| `rpool/var-lib-vz` | `/var/lib/vz` | 27.5 G |
| `rpool/data/vm-100-disk-0` | zvol VM 100 | 16.0 G |
| `rpool/data/vm-200-disk-1` | zvol VM 200 | 5.58 G |
| `nvme-scratch/vm-200-disk-0` | zvol VM 200 (scsi1) | 56 K |
| **`nvme-scratch/vm-300-disk-0`** | zvol VM 300 (scsi0, sparse 1 T) | 🆕 6.70 G |
| **`nvme-scratch/vega-filesystem`** | `/nvme-scratch/vega-filesystem` | 🆕 6.17 G |
| `backup-pool` | `/backup-pool` | **10.1 T** |

> ⚠️ `nvme-scratch/vega-filesystem` berisi struktur direktori storage PVE
> (`dump/ images/ import/ private/ snippets/ template/`) tapi **tidak terdaftar**
> di `storage.cfg`. Sementara `vega-storage` yang terdaftar justru menunjuk ke
> `/zfs-storage/vega-storage`. Dua konfigurasi setengah jadi yang tidak
> terhubung — perlu diputuskan mana yang dipakai.

### 7.3 Storage terdaftar di Proxmox

| Name | Type | Content | Status | Total | Pakai |
|---|---|---|---|---|---|
| `local` | dir (`/var/lib/vz`) | backup, vztmpl, import, iso | 🟢 active | 164 G | 16.8% |
| `local-zfs` | zfspool (`rpool/data`) | rootdir, images (sparse) | 🟢 active | 158 G | 13.7% |
| `nvme-scratch` | zfspool (`/nvme-scratch`) | images, rootdir (sparse) | 🟢 active | 3.5 T | **0.4%** |
| **`vega-storage`** | dir (`/zfs-storage/vega-storage`) | images, rootdir | 🟢 active | **10 T** | 0.0% ⚠️ *sisa VM 300, kosong* |
| **`vm-hdd`** 🆕 | **zfspool** (`zfs-storage/vm-disks`) | images, rootdir — sparse, `blocksize 64k` | 🟢 active | **10 T** (quota) | 0.0% |
| **`pve-backup`** 🆕 | dir (`/zfs-storage/backup`) | **backup** — 7 harian / 4 mingguan / 3 bulanan | 🟢 active | **20 T** (quota) | 0.0% |

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

dir: vega-storage
	path /zfs-storage/vega-storage
	content images,rootdir
	prune-backups keep-all=1
	shared 0
```

> ⚠️ `vega-storage` didaftarkan bertipe **`dir`** dengan content `images,rootdir` —
> artinya untuk menyimpan **disk VM**, bukan data sekuensing yang dibaca dari
> dalam VM. Kalau tujuannya 10 TB data run Vega, bentuk yang tepat adalah
> dataset ZFS yang di-share ke VM lewat **virtiofs** (pola yang sudah dipakai
> VM 200), atau didaftarkan sebagai `zfspool`, bukan `dir`.

> ✅ **Diperbaiki 2026-09-02.** `zfs-storage` kini terdaftar lewat dua dataset:
> **`vm-hdd`** (`zfs-storage/vm-disks`, quota 10 TiB, tipe `zfspool`) untuk disk VM,
> dan **`pve-backup`** (`zfs-storage/backup`, quota 20 TiB) sebagai **target `vzdump`**
> — yang selama ini tidak ada sama sekali.
>
> ```bash
> zfs create -o quota=10T zfs-storage/vm-disks
> zfs create -o quota=20T -o compression=zstd-3 zfs-storage/backup
> pvesm add zfspool vm-hdd --pool zfs-storage/vm-disks --content images,rootdir --sparse 1 --blocksize 64k
> pvesm add dir pve-backup --path /zfs-storage/backup --content backup \n>         --prune-backups keep-daily=7,keep-weekly=4,keep-monthly=3
> ```
>
> ⚠️ **`backup-pool` (11 TB) masih belum terdaftar** dan sudah 93–95% penuh di atas
> single disk tanpa redundansi. `pve-backup` di `zfs-storage` (raidz2) adalah target
> yang jauh lebih layak.

> ⚠️ **`vega-storage` kini menjadi sisa.** Dibuat untuk VM 300 yang sudah dihapus,
> isinya 0 byte, dan tipenya `dir` — bukan bentuk yang tepat. Digantikan oleh
> `vm-hdd`. Kalau memang tidak dipakai:
> ```bash
> pvesm remove vega-storage && zfs destroy zfs-storage/vega-storage
> ```

---

## 8. Daftar VM & LXC

### 8.1 VM (KVM)

| VMID | Nama | Status | vCPU | RAM | Boot disk | Tags |
|---|---|---|---|---|---|---|
| **100** | `dev-pipeline` | ⚪ stopped | 24 | 8 GiB | 32 G (`local-zfs`) | `automation`, `dev` |
| **200** | `dev-bioinfo` | ⚪ stopped | 24 | 64 GiB (balloon 16 GiB) | 100 G (`local-zfs`) | `bioinformatika`, `dev` |
| **101** | **`ubuntu24-desktop`** 🆕 | ⚪ stopped | **32** | **64 GiB** (balloon off) | 1000 G (`nvme-scratch`) + 7,81 T (`vm-hdd`) | `desktop`, `ubuntu`, `vega` |

> 🆕 **VM 101 menggantikan VM 300 yang dihapus.** Ini host **SMRT Link** untuk
> sekuenser **PacBio Vega**, sekaligus gateway/NAT instrumen dan jalur akses ke HPC.
> **Dokumen lengkapnya terpisah:** [`vm-101-smrtlink.md`](vm-101-smrtlink.md) —
> memuat topologi, konfigurasi jaringan, standar NAT/isolasi, dan checklist penerapan.

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

**VM 300 — `vega`** 🆕 — *host SMRT Link untuk sekuenser PacBio Vega*

Dibuat 2026-09-01. Target: SMRT Link mode **single node** (analisis berjalan di
dalam VM ini, tidak menyerahkan job ke Slurm `HPC-GPU`).

| Field | Nilai |
|---|---|
| CPU | **16 core**, 1 socket — ⚠️ tipe **`x86-64-v2-AES`**, `[PENDING] cores: 32` |
| Memory | 65536 MB (64 GiB), tanpa balloon |
| Disk OS | `nvme-scratch:vm-300-disk-0` **1 T**, `iothread=1` (sparse, terpakai 6.70 G) |
| NIC | `virtio` `BC:24:11:54:47:55` → `vmbr0`, `firewall=1` |
| ISO terpasang | ⚠️ `ubuntu-24.04.4-**desktop**-amd64.iso` |
| SCSI controller | `virtio-scsi-single` |
| NUMA | 0 *(wajar — host NPS1, satu node)* |
| Guest agent | belum diaktifkan |
| virtiofs | ❌ belum ada — data 10 T belum tersambung ke VM |

Perbandingan dengan syarat PacBio (kolom *SMRT Link single node*):

| Komponen | Syarat PacBio | VM 300 | Status |
|---|---|---|---|
| CPU | 16 core / **32 thread** | 16 vCPU *(pending 32)* | ⚠️ perlu restart untuk berlaku |
| RAM | 64 GB | 64 GiB | ✅ |
| Local SSD | 1 TB | 1 T di `nvme-scratch` | ✅ |
| Storage data | *(tidak diatur)* | `vega-storage` 10 T | 🟡 belum tersambung ke VM |

> 🔴 **`cpu: x86-64-v2-AES` tidak punya AVX/AVX2.** Toolchain PacBio (`ccs`,
> `pbmm2`, turunan minimap2) dikompilasi dengan vektorisasi AVX2 — binari yang
> mensyaratkannya bisa mati dengan `SIGILL`. Bandingkan VM 200 yang memakai
> `cpu: host`. Perbaikan: `qm set 300 --cpu host` (aman di sini karena node
> standalone, tidak ada live migration yang dikorbankan).

> ⚠️ **ISO-nya Ubuntu Desktop, bukan Server.** GNOME + snap memakan RAM/CPU dan
> menambah permukaan serangan pada VM headless. Selain itu **matriks OS resmi
> SMRT Link perlu diverifikasi** — belum tentu Ubuntu 24.04 didukung oleh versi
> SMRT Link yang dikirim bersama Vega. Cek release notes sebelum instalasi.

### 8.2 LXC Container

**Tidak ada container LXC.**

### 8.3 Ringkasan alokasi resource

| Resource | Host | Teralokasi ke VM | Sisa |
|---|---|---|---|
| Thread CPU | 128 | **80** (24 + 24 + 32) | 48 |
| RAM | 251 GiB | **136 GiB** (8 + 64 + 64) | 115 GiB *(dikurangi ARC hingga 200 GiB)* |
| Storage `local-zfs` | 158 G | ±21 G | — |
| Storage `nvme-scratch` | 3.5 T | 2 T sparse (VM 200 + VM 101) | 3.39 T aktual |
| Storage `vm-hdd` 🆕 | 10 T (quota) | 7,81 T sparse (VM 101) | ± 2,2 T |
| Storage `pve-backup` 🆕 | 20 T (quota) | 0 | 20 T |
| Storage `vega-storage` | 10 T (quota) | 0 ⚠️ *sisa* | 10 T |

> ⚠️ Ketiga VM **tidak boleh menyala bersamaan** dengan ARC di 200 GiB:
> 136 GiB VM + 200 GiB ARC = 336 GiB pada host 251 GiB, tanpa swap.
> **Turunkan `zfs_arc_max` ke ± 96 GiB** sebelum VM 101 dipakai produksi —
> lihat [vm-101-smrtlink §8.1](vm-101-smrtlink.md#81-menurunkan-zfs_arc_max-ki-v04).

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
| 1 | **Tidak ada backup VM sama sekali** — belum ada job vzdump terjadwal | VM 100, 200 & 101 hilang permanen bila `rpool` / NVMe gagal. 🟡 *Sebagian tertangani 2026-09-02: target `pve-backup` (20 TiB di raidz2) sudah dibuat — tinggal menjadwalkan job* | 🔴 Kritis |
| 2 | **`backup-pool` 93% penuh, single disk tanpa redundansi**, berisi 10.1 T data | 1 disk mati = 10 T hilang. Di atas 90% performa ZFS juga anjlok | 🔴 Kritis |
| 3 | **Passphrase LUKS & prosedur unlock belum terdokumentasi** | Kunci hilang = 140 TB `zfs-storage` tidak bisa dibuka selamanya | 🔴 Kritis |
| 4 | **`rpool` dan `nvme-scratch` berbagi satu NVMe fisik**, keduanya tanpa redundansi | 1 NVMe mati = OS hypervisor + scratch + disk VM hilang serentak | 🔴 Kritis |
| 5 | **Firewall Proxmox tidak aktif** (tidak ada `cluster.fw` / host `.fw`) | `firewall=1` di kedua VM tidak berefek; host & VM terbuka di LAN | 🟠 Tinggi |
| 6 | **IPMI satu segmen dengan jaringan data** (`192.168.18.13`, VLAN disabled) + **DHCP** | BMC bisa dijangkau siapa pun di LAN; IP bisa berubah sewaktu-waktu | 🟠 Tinggi |
| 7 | **RAM hanya mengisi 4 dari 8 channel** | Bandwidth memori ±50% dari kemampuan platform — terasa di assembly & index STAR | 🟠 Tinggi |
| 8 | **Uplink hanya 1 GbE** (`nic0`), `nic1` / `nic2` menganggur | Melayani 140 TB lewat pipa 1 Gb/s (±3 jam per TB); bonding belum dimanfaatkan | 🟠 Tinggi |
| 9 | ~~**`zfs-storage` tidak terdaftar sebagai storage PVE**~~ | ✅ **Selesai 2026-09-02** — terdaftar sebagai `vm-hdd` + `pve-backup`. `backup-pool` masih belum terdaftar | 🟢 Selesai |
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

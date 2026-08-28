# hpc-node-01 — HPC Compute Node (Bare-Metal)

> **Tipe Unit:** Bare-Metal Compute Server — 1 chassis fisik
> **Status:** 🟢 Production
> **Terakhir Diperbarui:** 2026-08-28
> **PIC Node:** *(isi nama sysadmin)*
> **Dokumen Terkait:** [server-changelog](../../track-record/server-changelog.md) · [maintenance-log](../../track-record/maintenance-log.md) · [SOP Eksekusi](../../docs/sop/sop-bioinformatics-execution.md)

![Posisi rak hpc-node-01](../../assets/images/racks/hpc-node-01-rack.png)

---

## 1. Identitas & Aset Fisik

| Field | Nilai |
|---|---|
| **Hostname (short)** | `hpc-node-01` |
| **FQDN** | `hpc-node-01.hpc.local` |
| **Alias / Label Fisik** | `COMPUTE-GPU-01` |
| **Serial Number** | `SN-XXXXXXX` *(cek: `dmidecode -s system-serial-number`)* |
| **Asset Tag (internal)** | `AST-HPC-2024-0001` |
| **Service Tag / Express Code** | `XXXXXXX` *(Dell)* / `—` |
| **Vendor** | Dell EMC / Supermicro / HPE *(pilih)* |
| **Model** | PowerEdge R750xa / SYS-420GP-TNR *(sesuaikan)* |
| **Form Factor** | Rackmount 2U |
| **Tanggal Pembelian** | `2024-06-12` |
| **Tanggal Instalasi / Go-Live** | `2024-07-02` |
| **Garansi Berakhir** | `2029-06-11` (5 tahun, ProSupport NBD) |
| **Nomor Kontrak Support** | `CTR-XXXXXX` |
| **Nilai Aset (perolehan)** | `Rp —` |
| **Status Operasional** | 🟢 Production |

### 1.1 Lokasi Fisik

| Field | Nilai |
|---|---|
| **Gedung / Ruang** | Gedung Riset — Ruang Server Lt. 2 |
| **Nama Rak** | `RACK-A01` |
| **Posisi RU** | **RU 12 – RU 13** (2U, dihitung dari bawah) |
| **Orientasi** | Cold aisle menghadap depan rak |
| **Rail Kit** | Sliding rail + cable management arm |
| **PDU A (Primary)** | `PDU-A01-A` → outlet **C13 #7** |
| **PDU B (Redundant)** | `PDU-A01-B` → outlet **C13 #7** |
| **PSU** | 2× 2400W Platinum, mode redundant (1+1) |
| **Konsumsi Daya Idle** | ± 320 W |
| **Konsumsi Daya Peak** | ± 1.850 W (full load + GPU) |
| **Berat** | ± 32 kg |
| **Label Kabel** | `A01-RU12-NET1`, `A01-RU12-NET2`, `A01-RU12-IPMI`, `A01-RU12-PWR-A/B` |

**Verifikasi identitas fisik:**
```bash
sudo dmidecode -s system-manufacturer
sudo dmidecode -s system-product-name
sudo dmidecode -s system-serial-number
sudo dmidecode -t 1        # System Information lengkap
sudo dmidecode -t 2        # Baseboard
hostnamectl
```

---

## 2. Manajemen Out-of-Band (IPMI / iDRAC / BMC)

| Field | Nilai |
|---|---|
| **Tipe BMC** | iDRAC9 Enterprise / IPMI 2.0 (ASPEED AST2600) |
| **IP IPMI** | `10.10.30.11/24` |
| **Gateway IPMI** | `10.10.30.1` |
| **VLAN IPMI** | **VLAN 30** (isolated management, tidak routable ke internet) |
| **MAC BMC** | `AA:BB:CC:DD:EE:01` |
| **Hostname BMC** | `idrac-hpc-node-01.hpc.local` |
| **Versi Firmware BMC** | `7.10.30.00` |
| **Versi BIOS/UEFI** | `2.15.1` |
| **Web UI** | `https://10.10.30.11` (hanya dari jump host mgmt) |
| **Serial-over-LAN** | Aktif, baud `115200` |
| **Virtual Media** | Aktif (untuk reinstall OS) |
| **Akun Admin** | `sysadmin` — **password: lihat Vaultwarden entri `IPMI / hpc-node-01`** |
| **Akun Monitoring (read-only)** | `monitor-ro` — dipakai Prometheus IPMI exporter |
| **NTP BMC** | `10.10.10.5` |
| **SNMP Trap Destination** | `10.10.10.20` (Zabbix/Prometheus) |

> ⚠️ **Jangan pernah menulis password IPMI di file ini atau di commit manapun.**

### 2.1 Perintah IPMI yang sering dipakai

```bash
# Status daya
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<dari-vault>' chassis power status

# Nyalakan / matikan / reset
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<...>' chassis power on
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<...>' chassis power soft
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<...>' chassis power cycle

# Sensor suhu, fan, voltase
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<...>' sdr type Temperature
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<...>' sdr type Fan
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<...>' sensor list

# System Event Log (SEL) — cek dulu ini setiap ada crash
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<...>' sel list
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<...>' sel elist
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<...>' sel clear     # setelah dicatat!

# Console serial (butuh SOL aktif)
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<...>' sol activate
# keluar: tekan  ~.

# Nyalakan LED identifikasi chassis 60 detik (untuk cari fisik di rak)
ipmitool -I lanplus -H 10.10.30.11 -U sysadmin -P '<...>' chassis identify 60

# Khusus Dell — racadm
racadm -r 10.10.30.11 -u sysadmin -p '<...>' getsysinfo
racadm -r 10.10.30.11 -u sysadmin -p '<...>' getsel
racadm -r 10.10.30.11 -u sysadmin -p '<...>' hwinventory
```

---

## 3. Jaringan

| Interface | Tipe | MAC | Speed | Bonding | IP / Subnet | VLAN | Switch : Port | MTU | Fungsi |
|---|---|---|---|---|---|---|---|---|---|
| `eno1` | RJ45 | `AA:BB:CC:DD:EE:11` | 1 GbE | — | `10.10.10.11/24` | 10 | `SW-MGMT-01 : Gi1/0/11` | 1500 | Manajemen / SSH |
| `ens1f0` | SFP28 | `AA:BB:CC:DD:EE:12` | 25 GbE | `bond0` (slave) | — | 20 | `SW-DATA-01 : Eth1/11` | 9000 | Data / NFS |
| `ens1f1` | SFP28 | `AA:BB:CC:DD:EE:13` | 25 GbE | `bond0` (slave) | — | 20 | `SW-DATA-02 : Eth1/11` | 9000 | Data / NFS (redundan) |
| `bond0` | LACP 802.3ad | — | 50 GbE agg | master | `10.10.20.11/24` | 20 | LACP po11 | 9000 | Trafik NFS ke storage |
| `idrac` | RJ45 | `AA:BB:CC:DD:EE:01` | 1 GbE | — | `10.10.30.11/24` | 30 | `SW-MGMT-01 : Gi1/0/41` | 1500 | Out-of-band |

- **Default gateway:** `10.10.10.1` via `eno1`
- **DNS:** `10.10.10.5`, `10.10.10.6`
- **NTP:** `10.10.10.5` (chrony)
- **Jumbo frame:** wajib `MTU 9000` di `bond0` dan seluruh path ke `storage-node-01`.
  Kalau salah satu hop tidak jumbo, throughput NFS anjlok drastis.

```bash
# Verifikasi
ip -br addr
ip -br link
cat /proc/net/bonding/bond0
ethtool ens1f0 | grep -E 'Speed|Duplex|Link detected'

# Uji jumbo frame end-to-end (harus sukses tanpa fragmentasi)
ping -M do -s 8972 -c 4 10.10.20.50

# Uji throughput ke storage
iperf3 -c 10.10.20.50 -P 8 -t 30
```

---

## 4. CPU

| Field | Nilai |
|---|---|
| **Jumlah Socket** | **2** |
| **Model** | AMD EPYC 9554 64-Core Processor *(sesuaikan)* |
| **Arsitektur** | x86_64, Zen 4 |
| **Core per Socket** | **64** |
| **Total Physical Core** | **128** |
| **Thread per Core (SMT/HT)** | **2** |
| **Total Logical Thread** | **256** |
| **Base Clock** | 3.10 GHz |
| **Boost Clock** | 3.75 GHz |
| **Cache L3** | 256 MB per socket |
| **NUMA Node** | **2** (NPS1) — Node0 = CPU 0–63,128–191 · Node1 = CPU 64–127,192–255 |
| **TDP** | 360 W per socket |
| **Microcode** | `0x0a101144` |
| **Governor** | `performance` (bukan `powersave` — penting untuk konsistensi benchmark) |
| **SMT Status** | Aktif |
| **Core Dicadangkan untuk OS** | **CPU 0 dan CPU 64** (1 core per NUMA node) — tidak dialokasikan Slurm |
| **Core Tersedia untuk Job** | **126 physical core** (lihat SOP batas 80–90%) |

```bash
lscpu
lscpu | grep -E 'Model name|Socket|Core|Thread|NUMA|MHz'
numactl --hardware
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
lscpu -e            # mapping CPU→core→socket→node
turbostat --Summary --interval 5   # cek clock riil saat load
```

---

## 5. Memory (RAM)

| Field | Nilai |
|---|---|
| **Total RAM Terpasang** | **1.024 GB (1 TB)** |
| **Tipe** | DDR5 RDIMM ECC Registered |
| **Speed** | 4800 MT/s |
| **Jumlah DIMM Terpasang** | **16 × 64 GB** |
| **Total Slot DIMM** | 24 (8 slot kosong — masih bisa ekspansi ke 1,5 TB) |
| **Channel** | 12-channel per socket, terisi 8 per socket |
| **Distribusi NUMA** | Node0 = 512 GB · Node1 = 512 GB |
| **ECC** | Aktif, monitoring via `rasdaemon` |
| **Swap** | 64 GB pada NVMe OS (`/dev/nvme0n1p3`) |
| **Swappiness** | `10` |
| **HugePages** | Transparent HugePages = `madvise` |
| **RAM Dicadangkan untuk OS** | **32 GB** — Slurm `RealMemory` di-set 992000 MB |
| **RAM Maks per Job** | 960 GB (dibatasi QoS) |

### 5.1 Layout Slot DIMM

| Slot | Kapasitas | Part Number | Serial | Socket/Channel |
|---|---|---|---|---|
| A1 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0001` | CPU0 / Ch A |
| A2 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0002` | CPU0 / Ch B |
| A3 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0003` | CPU0 / Ch C |
| A4 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0004` | CPU0 / Ch D |
| A5 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0005` | CPU0 / Ch E |
| A6 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0006` | CPU0 / Ch F |
| A7 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0007` | CPU0 / Ch G |
| A8 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0008` | CPU0 / Ch H |
| A9–A12 | *(kosong)* | — | — | CPU0 |
| B1 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0009` | CPU1 / Ch A |
| B2 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0010` | CPU1 / Ch B |
| B3 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0011` | CPU1 / Ch C |
| B4 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0012` | CPU1 / Ch D |
| B5 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0013` | CPU1 / Ch E |
| B6 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0014` | CPU1 / Ch F |
| B7 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0015` | CPU1 / Ch G |
| B8 | 64 GB | `MTC40F2046S1RC48BA1` | `SN-M0016` | CPU1 / Ch H |
| B9–B12 | *(kosong)* | — | — | CPU1 |

```bash
free -h
sudo dmidecode -t 17 | grep -E 'Locator|Size|Speed|Serial|Part Number|Manufacturer'
numactl --hardware
sudo ras-mc-ctl --error-count       # hitung ECC error
sudo ras-mc-ctl --summary
sudo edac-util -v
```

> **Aturan ECC:** jika `Corrected Errors` pada satu DIMM > 100 dalam 24 jam,
> jadwalkan penggantian DIMM (catat di `maintenance-log.md`).
> Jika muncul **Uncorrected Error** → node langsung di-`drain` dari Slurm.

---

## 6. GPU

| Field | Nilai |
|---|---|
| **Jumlah GPU** | **4** |
| **Model** | NVIDIA A100 80GB PCIe / L40S *(sesuaikan)* |
| **VRAM per GPU** | **80 GB HBM2e** |
| **Total VRAM** | **320 GB** |
| **Interconnect** | NVLink Bridge antar pasangan (GPU0↔GPU1, GPU2↔GPU3) |
| **PCIe** | Gen4 x16 per GPU |
| **Driver NVIDIA** | `550.90.07` |
| **CUDA Toolkit** | `12.4` |
| **cuDNN** | `9.1.0` |
| **NCCL** | `2.21.5` |
| **Persistence Mode** | Aktif (`nvidia-smi -pm 1`) |
| **ECC VRAM** | Aktif |
| **MIG** | **Nonaktif** (job bioinformatics butuh VRAM penuh) |
| **Power Limit** | 300 W per GPU |
| **Container Toolkit** | `nvidia-container-toolkit` terpasang (untuk Singularity `--nv`) |

### 6.1 Detail per GPU

| Idx | UUID (potong) | Slot PCIe | Bus ID | NUMA Affinity | VRAM | Serial |
|---|---|---|---|---|---|---|
| 0 | `GPU-a1b2c3d4` | Riser 1 Slot 1 | `0000:31:00.0` | Node 0 | 80 GB | `SN-G0001` |
| 1 | `GPU-e5f6a7b8` | Riser 1 Slot 2 | `0000:4b:00.0` | Node 0 | 80 GB | `SN-G0002` |
| 2 | `GPU-c9d0e1f2` | Riser 2 Slot 1 | `0000:b1:00.0` | Node 1 | 80 GB | `SN-G0003` |
| 3 | `GPU-a3b4c5d6` | Riser 2 Slot 2 | `0000:ca:00.0` | Node 1 | 80 GB | `SN-G0004` |

### 6.2 Workload GPU yang dijalankan di node ini

| Tool | Kegunaan | VRAM Minimum |
|---|---|---|
| NVIDIA Parabricks | Akselerasi GATK/BWA/DeepVariant | 40 GB |
| Guppy / Dorado | Basecalling Nanopore | 24 GB |
| AlphaFold2 / ColabFold | Prediksi struktur protein | 40 GB (bisa >64 GB untuk multimer) |
| scVI / cellranger-atac GPU | Single-cell | 16 GB |

```bash
nvidia-smi
nvidia-smi -L                       # daftar GPU + UUID
nvidia-smi -q -d MEMORY,TEMPERATURE,POWER,ECC
nvidia-smi topo -m                  # matriks NVLink / PCIe affinity
nvidia-smi --query-gpu=index,name,serial,uuid,memory.total,memory.used,utilization.gpu,temperature.gpu --format=csv
nvidia-smi -pm 1                    # persistence mode ON
nvidia-smi dmon -s pucm             # monitoring real-time
```

---

## 7. Storage Lokal (Termasuk NVMe Scratch)

### 7.1 Perangkat fisik

| Dev | Model | Kapasitas | Tipe | Slot / Bay | Serial | Firmware | Peran |
|---|---|---|---|---|---|---|---|
| `/dev/nvme0n1` | Micron 7450 PRO | 960 GB | NVMe M.2 | Onboard M.2 #1 | `SN-D0001` | `E1MU23BC` | OS (mirror) |
| `/dev/nvme1n1` | Micron 7450 PRO | 960 GB | NVMe M.2 | Onboard M.2 #2 | `SN-D0002` | `E1MU23BC` | OS (mirror) |
| `/dev/nvme2n1` | Samsung PM9A3 | 3.84 TB | NVMe U.2 | Front Bay 0 | `SN-D0003` | `GDC7302Q` | Scratch (RAID0) |
| `/dev/nvme3n1` | Samsung PM9A3 | 3.84 TB | NVMe U.2 | Front Bay 1 | `SN-D0004` | `GDC7302Q` | Scratch (RAID0) |

### 7.2 Array & filesystem

| Array | Anggota | Level | Kapasitas Raw | Usable | FS | Mount | Opsi Mount |
|---|---|---|---|---|---|---|---|
| `/dev/md0` | `nvme0n1p2` + `nvme1n1p2` | RAID1 (mdadm) | 1.92 TB | 900 GB | XFS | `/` | `defaults,noatime` |
| `/dev/md1` | `nvme2n1` + `nvme3n1` | **RAID0 (mdadm)** | 7.68 TB | **7.0 TB** | XFS | **`/scratch`** | `defaults,noatime,nodiratime,inode64,largeio,logbsize=256k` |

> **RAID0 dipilih untuk scratch secara sengaja** — prioritasnya kecepatan, bukan keandalan.
> Data di `/scratch` **tidak pernah** dijadikan satu-satunya salinan. Jika salah satu
> NVMe mati, seluruh `/scratch` hilang dan itu diterima sebagai risiko desain.

### 7.3 Layout `/scratch`

```
/scratch/                       XFS on md1 (RAID0 NVMe) — 7.0 TB
├── <username>/                 quota 3 TB per user
│   ├── <SLURM_JOB_ID>/         workdir per job (dibuat & dihapus oleh script job)
│   │   ├── tmp/                TMPDIR job
│   │   ├── logs/
│   │   └── ...
│   └── persistent/             sementara, tetap kena purge 14 hari
└── .purge-exclude              daftar path yang dikecualikan dari auto-purge
```

| Field | Nilai |
|---|---|
| **Path Scratch** | `/scratch` |
| **Kapasitas Usable** | 7.0 TB |
| **Quota per User** | 3 TB (soft), 3.3 TB (hard), grace 7 hari |
| **Kebijakan Purge** | File dengan `atime` > **14 hari** dihapus otomatis |
| **Mekanisme Purge** | `systemd timer` `scratch-purge.timer` — jalan tiap hari 03:00 |
| **Threshold Alarm** | Warning 75%, Critical 88% |
| **Backup** | **TIDAK ADA — by design** |
| **Throughput Terukur** | ± 11 GB/s baca sekuensial, ± 8 GB/s tulis (fio, bs=1M, iodepth=32) |
| **IOPS Terukur** | ± 1.400.000 read 4K random |

```bash
lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL,MOUNTPOINT,FSTYPE
cat /proc/mdstat
sudo mdadm --detail /dev/md1
df -hT /scratch
sudo xfs_quota -x -c 'report -h' /scratch
sudo nvme list
sudo nvme smart-log /dev/nvme2n1     # cek percentage_used & media_errors
findmnt -t xfs
```

### 7.4 Kesehatan NVMe

| Dev | Percentage Used | Media Errors | Power On Hours | Temp | Status |
|---|---|---|---|---|---|
| `/dev/nvme0n1` | 2% | 0 | 18.240 | 41 °C | 🟢 OK |
| `/dev/nvme1n1` | 2% | 0 | 18.240 | 42 °C | 🟢 OK |
| `/dev/nvme2n1` | 14% | 0 | 18.120 | 48 °C | 🟢 OK |
| `/dev/nvme3n1` | 15% | 0 | 18.120 | 49 °C | 🟢 OK |

> **Ambang tindakan:** `percentage_used` ≥ 80% → jadwalkan penggantian.
> `media_errors` > 0 → segera `drain` node dan investigasi.

---

## 8. Mount Point Remote (NFS ke Storage Node)

| Mount Point | Sumber | Protokol | Opsi Mount | Sifat |
|---|---|---|---|---|
| `/mnt/storage` | `10.10.20.50:/tank/storage` | NFSv4.2 | `rw,hard,noatime,rsize=1048576,wsize=1048576,nconnect=8,_netdev` | Baca-tulis |
| `/mnt/storage/raw` | *(subdir)* | NFSv4.2 | `ro` di sisi export | Read-only |
| `/mnt/storage/reference` | `10.10.20.50:/tank/reference` | NFSv4.2 | `ro,hard,noatime,nconnect=8` | Read-only |
| `/home` | `10.10.20.50:/tank/home` | NFSv4.2 | `rw,hard,noatime,nconnect=4` | Baca-tulis |
| `/opt/containers` | `10.10.20.50:/tank/containers` | NFSv4.2 | `ro,hard,noatime` | Read-only |

Contoh baris `/etc/fstab`:
```fstab
10.10.20.50:/tank/storage    /mnt/storage      nfs4  rw,hard,noatime,rsize=1048576,wsize=1048576,nconnect=8,_netdev  0 0
10.10.20.50:/tank/reference  /mnt/storage/reference nfs4 ro,hard,noatime,nconnect=8,_netdev  0 0
10.10.20.50:/tank/home       /home             nfs4  rw,hard,noatime,nconnect=4,_netdev  0 0
10.10.20.50:/tank/containers /opt/containers    nfs4  ro,hard,noatime,_netdev  0 0
```

```bash
mount | grep nfs
nfsstat -m
nfsiostat 2 5          # cek latency & throughput per mount
showmount -e 10.10.20.50
```

---

## 9. Software Stack & Sistem Operasi

| Field | Nilai |
|---|---|
| **OS** | Rocky Linux 9.4 (Blue Onyx) *(atau Ubuntu 22.04.4 LTS)* |
| **Kernel** | `5.14.0-427.24.1.el9_4.x86_64` |
| **Kernel Terkunci?** | Ya — `dnf versionlock` aktif, upgrade kernel hanya lewat jendela maintenance |
| **Init** | systemd 252 |
| **Firewall** | `firewalld` — zona `internal`, port terbuka: 22, 6817–6819 (Slurm), 2049 (NFS client) |
| **SELinux** | `permissive` *(alasan: kompatibilitas Singularity — dicatat sebagai risiko diterima)* |
| **Time Sync** | `chronyd` → `10.10.10.5` |
| **Autentikasi User** | SSSD → LDAP `ldap://10.10.10.7` |
| **Config Management** | Ansible — playbook `hpc-compute.yml`, inventory group `hpc_nodes` |
| **Monitoring Agent** | `node_exporter` :9100, `nvidia_dcgm_exporter` :9400, `zabbix-agent2` |
| **Log Shipping** | `rsyslog` → `10.10.10.20:514` |
| **Update Policy** | Security patch bulanan; kernel & driver GPU hanya di jendela maintenance |

```bash
cat /etc/os-release
uname -a
uptime
systemctl --failed
journalctl -p err -b --no-pager | tail -50
dnf versionlock list
```

---

## 10. Scheduler — Slurm / PBS

| Field | Nilai |
|---|---|
| **Scheduler** | Slurm `23.11.6` |
| **Peran Node** | Compute node (`slurmd`) |
| **Controller** | `login-01` (`slurmctld`), backup `login-02` |
| **AccountingStorage** | `slurmdbd` di `login-01`, MariaDB |
| **SelectType** | `select/cons_tres` |
| **Cgroup** | v2, `ConstrainCores=yes`, `ConstrainRAMSpace=yes`, `ConstrainDevices=yes` |

### 10.1 Definisi node di `slurm.conf`

```conf
NodeName=hpc-node-01 \
    NodeAddr=10.10.10.11 \
    CPUs=256 Sockets=2 CoresPerSocket=64 ThreadsPerCore=2 \
    RealMemory=992000 \
    TmpDisk=7000000 \
    Gres=gpu:a100:4 \
    Feature=gpu,a100,nvme,epyc9554,avx512 \
    Weight=10 \
    State=UNKNOWN
```

`/etc/slurm/gres.conf` di node ini:
```conf
NodeName=hpc-node-01 Name=gpu Type=a100 File=/dev/nvidia0 Cores=0-63
NodeName=hpc-node-01 Name=gpu Type=a100 File=/dev/nvidia1 Cores=0-63
NodeName=hpc-node-01 Name=gpu Type=a100 File=/dev/nvidia2 Cores=64-127
NodeName=hpc-node-01 Name=gpu Type=a100 File=/dev/nvidia3 Cores=64-127
```

### 10.2 Partition tempat node ini terdaftar

| Partition | Anggota | MaxTime | DefaultTime | MaxCPUsPerJob | MaxMemPerJob | GRES | Prioritas | Keterangan |
|---|---|---|---|---|---|---|---|---|
| `gpu` | `hpc-node-01` | 7-00:00:00 | 04:00:00 | 128 | 960 GB | `gpu:a100:1-4` | 100 | Default untuk job GPU |
| `bigmem` | `hpc-node-01`, `hpc-node-03` | 14-00:00:00 | 08:00:00 | 128 | 960 GB | — | 80 | Assembly / STAR index |
| `short` | semua node | 04:00:00 | 00:30:00 | 32 | 128 GB | — | 200 | QC, test, job pendek |
| `long` | `hpc-node-01`, `hpc-node-02` | 30-00:00:00 | 24:00:00 | 64 | 512 GB | — | 50 | Pipeline panjang |

### 10.3 QoS

| QoS | MaxJobsPerUser | MaxCPUsPerUser | MaxWall | Prioritas |
|---|---|---|---|---|
| `normal` | 20 | 256 | 7 hari | 100 |
| `high` | 5 | 128 | 3 hari | 500 |
| `low` | 50 | 512 | 14 hari | 10 (preemptible) |

### 10.4 Perintah operasional Slurm

```bash
sinfo -N -l                                  # status semua node
sinfo -N -o "%N %C %m %G %T %E"              # ringkas: cpu(A/I/O/T), mem, gres, state
scontrol show node hpc-node-01               # detail lengkap node
squeue -w hpc-node-01                        # job yang jalan di node ini
sacct -N hpc-node-01 -S 2026-08-01 --format=JobID,JobName,User,Elapsed,MaxRSS,State

# Maintenance: keluarkan node dari pool tanpa membunuh job yang sedang jalan
sudo scontrol update NodeName=hpc-node-01 State=DRAIN Reason="maintenance RAM 2026-09-05 - PIC:sysadmin"

# Kembalikan ke pool
sudo scontrol update NodeName=hpc-node-01 State=RESUME

# Reservasi jendela maintenance
sudo scontrol create reservation ReservationName=maint-hpc01 \
    StartTime=2026-09-05T22:00:00 Duration=04:00:00 \
    Nodes=hpc-node-01 User=root Flags=MAINT,IGNORE_JOBS
```

---

## 11. Conda Environments

| Lokasi Instalasi | Path |
|---|---|
| **Base Conda** | `/opt/conda` (Miniforge3 `24.3.0-0`) |
| **Env bersama (shared)** | `/opt/conda/envs/` — read-only untuk user biasa |
| **Env personal** | `/home/$USER/.conda/envs/` |
| **Channel default** | `conda-forge`, `bioconda` (strict priority) |
| **Solver** | `libmamba` |
| **Kebijakan** | Setiap env shared **wajib** punya file `environment.yml` di repo pipeline, versi tool dikunci eksplisit |

### 11.1 Daftar environment bersama di node ini

| Nama Env | Path | Python | Tool Utama (versi terkunci) | Ukuran | Owner | Dibuat |
|---|---|---|---|---|---|---|
| `bio-align` | `/opt/conda/envs/bio-align` | 3.11 | `bwa=0.7.18`, `bwa-mem2=2.2.1`, `bowtie2=2.5.4`, `samtools=1.20`, `sambamba=1.0.1` | 3.2 GB | bioinfo-lead | 2024-07-10 |
| `bio-variant` | `/opt/conda/envs/bio-variant` | 3.11 | `gatk4=4.5.0.0`, `bcftools=1.20`, `freebayes=1.3.6`, `vcftools=0.1.16`, `snpeff=5.2` | 4.8 GB | bioinfo-lead | 2024-07-10 |
| `bio-rnaseq` | `/opt/conda/envs/bio-rnaseq` | 3.11 | `star=2.7.11b`, `salmon=1.10.3`, `hisat2=2.2.1`, `subread=2.0.6`, `stringtie=2.2.3` | 2.9 GB | bioinfo-lead | 2024-07-12 |
| `bio-qc` | `/opt/conda/envs/bio-qc` | 3.11 | `fastqc=0.12.1`, `multiqc=1.22`, `fastp=0.23.4`, `trimmomatic=0.39`, `cutadapt=4.8` | 1.4 GB | bioinfo-lead | 2024-07-10 |
| `bio-assembly` | `/opt/conda/envs/bio-assembly` | 3.10 | `spades=4.0.0`, `megahit=1.2.9`, `flye=2.9.4`, `quast=5.2.0`, `busco=5.7.1` | 5.1 GB | bioinfo-lead | 2024-08-02 |
| `bio-meta` | `/opt/conda/envs/bio-meta` | 3.11 | `kraken2=2.1.3`, `bracken=2.9`, `metaphlan=4.1.1`, `humann=3.9` | 3.7 GB | bioinfo-lead | 2024-09-15 |
| `bio-singlecell` | `/opt/conda/envs/bio-singlecell` | 3.11 | `scanpy=1.10.1`, `anndata=0.10.7`, `scvi-tools=1.1.2`, `harmonypy=0.0.10` | 4.4 GB | bioinfo-lead | 2025-01-20 |
| `bio-nanopore` | `/opt/conda/envs/bio-nanopore` | 3.10 | `minimap2=2.28`, `nanoplot=1.42.0`, `medaka=1.11.3`, `porechop=0.2.4` | 3.0 GB | bioinfo-lead | 2025-03-11 |
| `wf-tools` | `/opt/conda/envs/wf-tools` | 3.11 | `snakemake=8.14.0`, `nextflow=24.04.2`, `cromwell=87` | 1.1 GB | sysadmin | 2024-07-10 |

```bash
# Aktivasi
source /opt/conda/etc/profile.d/conda.sh
conda activate bio-align

# Inspeksi
conda env list
conda list -n bio-align
conda env export -n bio-align --no-builds > environment.yml
du -sh /opt/conda/envs/*

# Membuat env baru (SELALU kunci versi)
conda create -n bio-newtool -c conda-forge -c bioconda "tool=1.2.3" "samtools=1.20" -y
```

> **Aturan:** dilarang `conda install` ke env shared saat ada job berjalan.
> Buat env baru bernama `<nama>-v2`, uji, baru umumkan ke user.

---

## 12. Singularity / Apptainer Containers

| Field | Nilai |
|---|---|
| **Runtime** | Apptainer `1.3.2` (kompatibel `singularity` alias) |
| **Mode** | Unprivileged, `setuid` dinonaktifkan, user namespace aktif |
| **Direktori Image** | `/opt/containers` (NFS read-only dari `storage-node-01`) |
| **Cache Dir** | `/scratch/$USER/.apptainer/cache` (**jangan di `/home`** — cepat penuh) |
| **Bind Path Default** | `/scratch`, `/mnt/storage`, `/home` |
| **GPU Flag** | `--nv` (NVIDIA) |

`/etc/apptainer/apptainer.conf` (bagian penting):
```conf
bind path = /scratch
bind path = /mnt/storage
bind path = /home
enable overlay = yes
allow setuid = no
```

### 12.1 Daftar image `.sif` yang tersedia

| File Image | Versi Tool | Sumber | Ukuran | SHA256 (8 char) | Ditambahkan |
|---|---|---|---|---|---|
| `/opt/containers/gatk_4.5.0.0.sif` | GATK 4.5.0.0 | `docker://broadinstitute/gatk:4.5.0.0` | 3.4 GB | `a1b2c3d4` | 2024-07-15 |
| `/opt/containers/deepvariant_1.6.1-gpu.sif` | DeepVariant 1.6.1 | `docker://google/deepvariant:1.6.1-gpu` | 9.8 GB | `e5f6a7b8` | 2024-08-01 |
| `/opt/containers/parabricks_4.3.0.sif` | Parabricks 4.3.0 | `docker://nvcr.io/nvidia/clara/clara-parabricks:4.3.0-1` | 14.2 GB | `c9d0e1f2` | 2024-09-03 |
| `/opt/containers/nfcore_sarek_3.4.2.sif` | nf-core/sarek 3.4.2 | `docker://nfcore/sarek:3.4.2` | 2.1 GB | `a3b4c5d6` | 2024-10-11 |
| `/opt/containers/nfcore_rnaseq_3.14.0.sif` | nf-core/rnaseq 3.14.0 | `docker://nfcore/rnaseq:3.14.0` | 1.9 GB | `b7c8d9e0` | 2024-10-11 |
| `/opt/containers/cellranger_8.0.1.sif` | Cell Ranger 8.0.1 | build lokal dari `.def` (lisensi 10x) | 4.6 GB | `f1a2b3c4` | 2025-01-22 |
| `/opt/containers/alphafold_2.3.2.sif` | AlphaFold 2.3.2 | `docker://catgumag/alphafold:2.3.2` | 11.5 GB | `d5e6f7a8` | 2025-02-18 |
| `/opt/containers/dorado_0.7.2.sif` | Dorado 0.7.2 | build lokal dari `.def` | 2.8 GB | `b9c0d1e2` | 2025-04-05 |
| `/opt/containers/qiime2_2024.5.sif` | QIIME2 2024.5 | `docker://quay.io/qiime2/amplicon:2024.5` | 6.3 GB | `f3a4b5c6` | 2025-06-14 |

```bash
# Jalankan
apptainer exec \
  --bind /scratch:/scratch,/mnt/storage:/mnt/storage \
  /opt/containers/gatk_4.5.0.0.sif \
  gatk HaplotypeCaller --help

# Dengan GPU
apptainer exec --nv \
  --bind /scratch:/scratch,/mnt/storage:/mnt/storage \
  /opt/containers/parabricks_4.3.0.sif \
  pbrun fq2bam --help

# Inspeksi & verifikasi integritas
apptainer inspect /opt/containers/gatk_4.5.0.0.sif
apptainer inspect --deffile /opt/containers/dorado_0.7.2.sif
sha256sum /opt/containers/gatk_4.5.0.0.sif

# Build image baru (dilakukan di build host, BUKAN di node produksi)
apptainer build tool_1.0.0.sif docker://organisasi/tool:1.0.0
```

> **Aturan:** nama file `.sif` **wajib** mengandung versi tool.
> Dilarang `latest`. Image baru masuk lewat `storage-node-01` (read-only mount),
> bukan disalin manual ke tiap node.

---

## 13. Environment Modules (Lmod) — Opsional

| Field | Nilai |
|---|---|
| **Sistem** | Lmod `8.7.37` |
| **MODULEPATH** | `/opt/modulefiles` |

| Module | Versi | Isi |
|---|---|---|
| `gcc/13.2.0` | 13.2.0 | Compiler toolchain |
| `openmpi/4.1.6` | 4.1.6 | MPI (dibangun dengan `--with-slurm`) |
| `cuda/12.4` | 12.4 | CUDA toolkit |
| `R/4.4.1` | 4.4.1 | R + Bioconductor 3.19 |
| `java/17.0.11` | 17 | Untuk GATK, Picard |

```bash
module avail
module load gcc/13.2.0 openmpi/4.1.6
module list
module purge
```

---

## 14. Monitoring & Alerting

| Metrik | Sumber | Ambang Warning | Ambang Critical | Aksi |
|---|---|---|---|---|
| CPU Load 5m | node_exporter | > 200 | > 250 | Investigasi job runaway |
| RAM Used | node_exporter | > 85% | > 93% | Cek risiko OOM, drain node |
| `/scratch` used | node_exporter | > 75% | > 88% | Jalankan purge manual |
| `/` used | node_exporter | > 80% | > 90% | Bersihkan log, cek `/var` |
| Suhu CPU | IPMI exporter | > 78 °C | > 88 °C | Cek fan & aliran udara |
| Suhu GPU | DCGM exporter | > 80 °C | > 88 °C | Turunkan power limit, cek dust filter |
| ECC Correctable | rasdaemon | > 50/hari | > 200/hari | Jadwalkan ganti DIMM |
| ECC Uncorrectable | rasdaemon | ≥ 1 | ≥ 1 | **Drain node segera** |
| NVMe wear | smartctl | ≥ 80% | ≥ 90% | Jadwalkan penggantian |
| NFS latency | nfsiostat | > 20 ms | > 50 ms | Cek `storage-node-01` & jaringan |
| Slurm node state | slurm exporter | `DRAIN` | `DOWN` | Notifikasi PIC |

Dashboard: Grafana `http://10.10.10.20:3000/d/hpc-node-detail`

---

## 15. Health Check Cepat (jalankan saat troubleshooting)

```bash
#!/usr/bin/env bash
# quick-health-check hpc-node-01
echo "=== IDENTITAS ==="        ; hostnamectl; sudo dmidecode -s system-serial-number
echo "=== UPTIME/LOAD ==="      ; uptime
echo "=== CPU ==="              ; lscpu | grep -E 'Model name|Socket|Core|Thread|NUMA node\(s\)'
echo "=== MEMORY ==="           ; free -h; sudo ras-mc-ctl --error-count
echo "=== GPU ==="              ; nvidia-smi --query-gpu=index,name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv
echo "=== DISK ==="             ; lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE; df -hT
echo "=== MDADM ==="            ; cat /proc/mdstat
echo "=== NVMe SMART ==="       ; for d in /dev/nvme[0-3]n1; do echo "-- $d"; sudo nvme smart-log $d | grep -E 'percentage_used|media_errors|temperature'; done
echo "=== SCRATCH ==="          ; df -h /scratch; sudo xfs_quota -x -c 'report -h' /scratch | head -20
echo "=== NFS ==="              ; nfsstat -m | head -30; mount | grep nfs
echo "=== NETWORK ==="          ; ip -br addr; cat /proc/net/bonding/bond0 | grep -E 'Status|Slave Interface|MII Status'
echo "=== SLURM ==="            ; scontrol show node $(hostname -s) | head -20; squeue -w $(hostname -s)
echo "=== SERVICE GAGAL ==="    ; systemctl --failed
echo "=== ERROR LOG ==="        ; journalctl -p err -b --no-pager | tail -30
echo "=== OOM EVENT ==="        ; dmesg -T | grep -i -E 'oom|killed process' | tail -20
```

---

## 16. Riwayat Perubahan Node Ini

> Ringkasan saja. Detail lengkap ada di
> [`track-record/server-changelog.md`](../../track-record/server-changelog.md) dan
> [`track-record/maintenance-log.md`](../../track-record/maintenance-log.md).

| Tanggal | Jenis | Ringkasan | Ref |
|---|---|---|---|
| 2024-07-02 | Instalasi | Node masuk produksi, Rocky Linux 9.3, Slurm 23.02 | `SCL-2024-001` |
| 2024-11-20 | Firmware | iDRAC `7.00.00.171` → `7.10.30.00`, BIOS `2.10.2` → `2.15.1` | `MNT-2024-014` |
| 2025-02-08 | Hardware | RAM 512 GB → **1 TB** (tambah 8× 64 GB di slot A5–A8, B5–B8) | `SCL-2025-003` |
| 2025-05-17 | Software | Driver NVIDIA `535.161.07` → `550.90.07`, CUDA 12.2 → 12.4 | `MNT-2025-009` |
| 2025-09-30 | OS | Rocky Linux 9.3 → 9.4, kernel `5.14.0-362` → `5.14.0-427` | `SCL-2025-011` |
| 2026-03-14 | Hardware | Ganti NVMe scratch Bay 1 (wear 84%), serial `SN-D0004` baru | `MNT-2026-005` |
| 2026-06-22 | Network | `eno2` 10GbE diganti dual 25GbE SFP28, dibuat `bond0` LACP, MTU 9000 | `SCL-2026-007` |

---

## 17. Known Issues & Catatan Khusus

| ID | Deskripsi | Dampak | Workaround | Status |
|---|---|---|---|---|
| `KI-01` | SELinux di-set `permissive` karena Apptainer user-namespace bentrok dengan policy default | Risiko keamanan diterima; node ada di VLAN terisolasi | Pantau via auditd | Diterima |
| `KI-02` | GPU2 kadang laporkan `Xid 13` saat job AlphaFold multimer > 6 jam | Job gagal ~1× per bulan | Set `nvidia-smi -i 2 -pl 280`; job otomatis requeue | Dipantau |
| `KI-03` | `/scratch` bisa penuh dalam 6 jam kalau ada 3 job WGS paralel tanpa cleanup | Job lain gagal | SOP pre-flight check ≥3× input + purge harian | Mitigasi aktif |
| `KI-04` | Kabel PDU B pernah longgar (2025-11) | Kehilangan redundansi daya | Sudah dikencangkan + zip-tie, dicek tiap audit rak | Selesai |

---

## 18. Lampiran — Gambar & Diagram

| Gambar | Path | Keterangan |
|---|---|---|
| Foto rak | `../../assets/images/racks/hpc-node-01-rack.png` | Posisi RU 12–13 di RACK-A01 |
| Belakang chassis | `../../assets/images/racks/hpc-node-01-rear-cabling.png` | Kabel jaringan & daya berlabel |
| Layout DIMM | `../../assets/images/diagrams/hpc-node-01-dimm-layout.png` | Peta slot RAM terisi/kosong |
| Screenshot iDRAC | `../../assets/images/screenshots/hpc-node-01-idrac-dashboard.png` | Dashboard health |
| Output `nvidia-smi` | `../../assets/images/screenshots/hpc-node-01-nvidia-smi.png` | Kondisi 4 GPU |

```markdown
![Layout DIMM hpc-node-01](../../assets/images/diagrams/hpc-node-01-dimm-layout.png)
```

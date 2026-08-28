# HPC-GPU — HPC Compute Node (Bare-Metal, GPU)

> **Tipe Unit:** Bare-Metal Compute Server — 1 chassis fisik
> **Status:** 🟢 Production
> **Terakhir Diperbarui:** 2026-08-28
> **PIC Node:** *(isi nama sysadmin)*
> **Sumber Data:** auto-collect via SSH — `scripts/collect-hpc.sh`, 2026-08-28 15:00 WIB
> **Dokumen Terkait:** [server-changelog](../../track-record/server-changelog.md) · [maintenance-log](../../track-record/maintenance-log.md) · [SOP Eksekusi](../../docs/sop/sop-bioinformatics-execution.md) · [Panduan Penginputan](../../docs/penginputan-node.md)

> **Peran node ini:** satu-satunya node komputasi. Terdaftar di Slurm cluster
> `bioinfo` sebagai `compute001`, tapi **pada praktiknya dipakai sebagai server
> interaktif bersama** — lihat [§13 Known Issues](#13-known-issues--risiko) temuan #1.

---

## 1. Identitas & Aset Fisik

| Field | Nilai |
|---|---|
| **Hostname (short)** | `HPC-GPU` |
| **Nama di Slurm** | `compute001` |
| **Alias / Label Fisik** | *(isi label di chassis)* |
| **Vendor** | ASRockRack |
| **Motherboard** | **ROME2D32GM-2T** (dual socket SP3, 32 slot DDR4) |
| **Model Sistem (DMI)** | `ROME2D32GM-2T` |
| **Tipe Chassis** | Main Server Chassis |
| **Serial Number (DMI)** | ⚠️ `To Be Filled By O.E.M.` — **belum diprogram** |
| **Manufacturer (DMI)** | ⚠️ `To Be Filled By O.E.M.` |
| **Asset Tag (internal)** | *(isi — WAJIB, karena serial DMI kosong)* |
| **BIOS** | versi **P3.50**, rilis **2022-10-27** ⚠️ *± 4 tahun* |
| **Form Factor** | *(isi: rackmount xU / tower)* |
| **Tanggal Pembelian** | *(isi)* |
| **Tanggal Go-Live** | *(isi)* |
| **Garansi Berakhir** | *(isi)* |
| **Status Operasional** | 🟢 Production |
| **Uptime saat pendataan** | 8 hari 1 jam (boot 2026-08-20 13:29) |

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
| **Tipe BMC** | ASRock Rack BMC (AMI), IPMI **2.0** |
| **Firmware BMC** | **1.26** |
| **IP IPMI** | `192.168.18.119/24` |
| **Sumber IP** | Static ✅ |
| **Gateway** | `192.168.18.1` |
| **MAC BMC** | `9c:6b:00:72:1d:8e` |
| **VLAN 802.1q** | ⚠️ **Disabled** — IPMI satu segmen dengan jaringan data |
| **SNMP Community** | ⚠️ masih default `AMI` |
| **Bad Password Threshold** | ⚠️ **0** — tidak ada lockout, brute-force tak terbatas |
| **User Lockout Interval** | 600 detik *(tidak berlaku karena threshold 0)* |
| **RMCP+ Cipher Suites** | ⚠️ `0,1,2,3,...` — **cipher suite 0 aktif** (priv `CALLBACK`) |
| **Kredensial** | simpan di password manager, entri `IPMI / HPC-GPU` — **jangan tulis di sini** |

Perintah operasional:

```bash
ipmitool -I lanplus -H 192.168.18.119 -U <user> chassis power status
ipmitool -I lanplus -H 192.168.18.119 -U <user> sel list | tail -20
ipmitool -I lanplus -H 192.168.18.119 -U <user> sdr type Temperature
ipmitool -I lanplus -H 192.168.18.119 -U <user> chassis identify 60
```

---

## 3. CPU

| Field | Nilai |
|---|---|
| **Model** | AMD **EPYC 7763** 64-Core Processor |
| **Socket terpasang** | **2** |
| **Core / Thread** | **128 core / 256 thread** (SMT aktif) |
| **Frekuensi** | min 1500 MHz — max **3530 MHz** (boost enabled) |
| **Cache** | L1d 4 MiB · L1i 4 MiB · L2 64 MiB · **L3 512 MiB** (16× 32 MiB) |
| **NUMA** | **2 node** — `node0` CPU 0-63,128-191 · `node1` CPU 64-127,192-255 |
| **Jarak NUMA** | lokal 10, remote 32 |
| **Governor** | `schedutil` |
| **Virtualisasi** | AMD-V (SVM) |
| **Suhu saat pendataan** | Socket 0: Tctl 69.8 °C · Socket 1: Tctl 68.2 °C |

> ⚠️ **`Tsa: Vulnerable: No microcode`** — mitigasi *Transient Scheduler Attack*
> belum tersedia karena microcode AMD belum diperbarui. Semua mitigasi lain tertutup.
> Perbaikan: pasang `amd64-microcode` terbaru + update BIOS.

---

## 4. Memory (RAM)

| Field | Nilai |
|---|---|
| **Total terpasang** | **1 TB** (16× 64 GB) |
| **Tipe** | DDR4 ECC RDIMM, Micron |
| **Slot terisi** | **16 dari 32** — seluruh 16 channel (2 soket × 8) terisi 1 DIMM/channel ✅ |
| **Speed modul** | 15× 3200 MT/s · **1× 2933 MT/s** |
| **Speed efektif** | ⚠️ **2933 MT/s** — diturunkan oleh satu modul yang lebih lambat |
| **ECC** | Multi-bit ECC aktif |
| **Swap** | 8 GiB — ⚠️ **terpakai penuh (8.0 GiB, sisa 12 MiB)** |

### 4.1 Modul yang berbeda

| Bank | Part Number | Speed | Catatan |
|---|---|---|---|
| **P0 CHANNEL C** | `36ASF8G72PZ-2G9B1` | **2933 MT/s** | ⚠️ satu-satunya modul lambat |
| 15 slot lainnya | `36ASF8G72PZ-3G2B2` | 3200 MT/s | |

> Mengganti **satu** DIMM di `P0 CHANNEL C` dengan `36ASF8G72PZ-3G2B2` akan
> menaikkan kecepatan seluruh 1 TB dari 2933 → 3200 MT/s (**+9% bandwidth memori**),
> yang langsung terasa di assembly & alignment. Ini perbaikan termurah di node ini.

### 4.2 Distribusi NUMA saat pendataan

| Node | Kapasitas | Bebas |
|---|---|---|
| `node0` | 515.790 MB | ⚠️ **3.218 MB** |
| `node1` | 516.035 MB | 118.279 MB |

> ⚠️ `node0` praktis habis sementara `node1` masih longgar 118 GB. Kombinasi ini
> dengan swap yang penuh menandakan proses tidak di-pin ke NUMA node dan alokasi
> menumpuk di satu sisi. Perhatikan bahwa **kedua A100 ber-afinitas ke `node0`**.

---

## 5. GPU

| Field | Nilai |
|---|---|
| **Driver NVIDIA** | **595.84** |
| **CUDA (driver)** | 13.2 |
| **CUDA Toolkit (`nvcc`)** | ⚠️ **12.0** — tertinggal dari driver |
| **Jumlah GPU** | 3 (2× A100 + 1× GeForce) |
| **Persistence Mode** | ⚠️ **Disabled** di ketiganya (padahal `nvidia-persistenced` aktif) |

### 5.1 Detail per GPU

| # | Model | VRAM | Serial | PCI | VBIOS | Power Cap | ECC | NUMA |
|---|---|---|---|---|---|---|---|---|
| 0 | **NVIDIA A100-SXM4-40GB** | 40.960 MiB | `1325023031983` | `0000:02:00.0` | `92.00.19.00.01` | 400 W | ✅ Enabled | node0 |
| 1 | **NVIDIA A100-SXM4-40GB** | 40.960 MiB | `1323521112613` | `0000:2A:00.0` | `92.00.19.00.01` | 400 W | ✅ Enabled | node0 |
| 2 | NVIDIA GeForce **RTX 5060 Ti** | 16.311 MiB | *(tidak ada)* | `0000:82:00.0` | `98.06.39.00.E1` | 180 W | ❌ N/A | node1 |

UUID:

```
GPU 0: GPU-967b70ac-e2bb-9a55-d52f-51a55beed9b4
GPU 1: GPU-56ef0227-7048-7706-6e2f-f06e5359e7f8
GPU 2: GPU-cd79c569-5fc9-b53d-2553-c1edb656be01
```

### 5.2 Topologi

```
        GPU0   GPU1   GPU2    CPU Affinity        NUMA
GPU0     X     NODE   SYS     0-63,128-191        0
GPU1    NODE    X     SYS     0-63,128-191        0
GPU2    SYS    SYS     X      64-127,192-255      1
```

> ⚠️ Kedua A100 berbentuk **SXM4** tapi terhubung lewat `NODE` (PCIe dalam satu
> NUMA node), **bukan `NV#` (NVLink)**. Untuk form factor SXM4 ini tidak lazim —
> artinya komunikasi antar-GPU jalan di PCIe, bukan NVLink. Perlu diverifikasi
> fisik apakah NVLink bridge memang tidak terpasang / tidak aktif.
>
> `GPU2` di NUMA node berbeda (`SYS`) — jangan gabungkan RTX 5060 Ti dengan A100
> dalam satu job multi-GPU; latensinya lewat interkoneksi antar-soket.

### 5.3 Catatan penggunaan

- Ketiga GPU menjalankan **`/usr/lib/xorg/Xorg`** (2 instance) — server tampilan
  memakai GPU compute. Pemakaiannya kecil (4 MiB/GPU) tapi tidak semestinya ada
  di node komputasi headless.
- Utilisasi saat pendataan: 0% di semua GPU; suhu 27–36 °C; daya 5–31 W.
- RTX 5060 Ti **tanpa ECC** — jangan dipakai untuk perhitungan yang butuh integritas
  numerik jangka panjang.

---

## 6. Storage Lokal

### 6.1 Perangkat fisik

| Dev | Model | Kapasitas | Serial | Firmware | Peran | SMART |
|---|---|---|---|---|---|---|
| `nvme0n1` | **ADATA LEGEND 800** | 1.00 TB | `2N30291A1GDE` | `V1122B0` | OS — `/` dan `/boot/efi` | ✅ PASSED |
| `nvme1n1` | SAMSUNG MZ1LB960HAJQ-00007 | 960 GB | `S435NA0N816948` | `EDA7602Q` | anggota `md2` | ✅ PASSED |
| `nvme2n1` | SAMSUNG MZ1LB960HAJQ-00007 | 960 GB | `S435NA0N816953` | `EDA7602Q` | anggota `md2` | ✅ PASSED |
| `nvme3n1` | SAMSUNG MZ1LB960HAJQ-00007 | 960 GB | `S435NA0N816945` | `EDA7602Q` | anggota `md2` | ✅ PASSED |
| `nvme4n1` | SAMSUNG MZ1LB960HAJQ-00007 | 960 GB | `S435NA0N816949` | `EDA7602Q` | anggota `md2` | ✅ PASSED |

> ⚠️ **Disk OS adalah SSD konsumer** (ADATA LEGEND 800), bukan kelas datacenter,
> **tanpa redundansi**, dan menyimpan `/` berisi 387 GB. SMART-nya mencatat
> **`Warning Comp. Temperature Time: 1274` menit** dan
> **`Critical Comp. Temperature Time: 15` menit** — disk ini pernah throttling
> termal cukup lama. Kalau mati, seluruh node tidak bisa boot.

### 6.2 Array & filesystem

| Mount | Device | Tipe | Kapasitas | Terpakai | Redundansi |
|---|---|---|---|---|---|
| `/` | `nvme0n1p2` | ext4 | 915 G | 387 G (**45%**) | ❌ single disk |
| `/boot/efi` | `nvme0n1p1` | vfat | 1.1 G | 6.2 M (1%) | ❌ |
| **`/mnt/scratch`** | `md2` | **RAID0** 4× NVMe | **3.5 T** | 2.5 T (**77%**) | ❌ *(disengaja untuk scratch)* |
| `/media/bio-pool` | `192.168.30.2:/bio-pool` | nfs4 | 20 T | 5.0 T (25%) | di storage node |

Detail `md2`:

| Field | Nilai |
|---|---|
| **Level** | RAID0, 4 device |
| **Chunk** | 512 K |
| **Ukuran** | 3.49 TiB |
| **Dibuat** | 2026-01-19 11:56 |
| **State** | `clean`, 0 failed |
| **UUID** | `22188788:63222db4:3b2a2d74:2d87f4f1` |
| **Anggota** | `nvme1n1`, `nvme2n1`, `nvme3n1`, `nvme4n1` |

> **RAID0 berarti 1 NVMe mati = seluruh 3.5 TB hilang.** Untuk scratch ini
> wajar, **asalkan** benar-benar diperlakukan sebagai data sementara.
> Saat ini terisi **77%** dan tidak terlihat mekanisme auto-purge.

> **Beda dari standar repo:** [README §3](../../README.md#3-mapping-path-storage)
> mendefinisikan scratch di **`/scratch`**. Node ini memakai **`/mnt/scratch`**,
> dan `/scratch` tidak ada. Salah satu harus disesuaikan.

### 6.3 Suhu NVMe

| Device | Composite | Sensor tertinggi | Ambang kritis |
|---|---|---|---|
| `nvme-pci-2100` (OS) | 37.9 °C | — | 89.8 °C |
| `nvme-pci-2500` | 39.9 °C | 47.9 °C | 86.8 °C |
| `nvme-pci-2600` | 41.9 °C | 56.9 °C | 86.8 °C |
| `nvme-pci-2800` | 41.9 °C | 62.9 °C | 86.8 °C |
| `nvme-pci-2900` | 43.9 °C | **65.8 °C** | 86.8 °C |

Masih di bawah ambang, tapi sensor 3 pada dua drive sudah di 63–66 °C **saat GPU idle**.
Perlu dipantau ketika beban I/O penuh.

---

## 7. Mount Point Remote (NFS)

### 7.1 Yang aktif

| Mount | Sumber | Versi | Opsi penting |
|---|---|---|---|
| `/media/bio-pool` | `192.168.30.2:/bio-pool` | **NFS 4.2** | `rw`, `rsize/wsize=1048576`, `soft`, `timeo=30`, `retrans=2`, `proto=tcp` |

Klien terlihat sebagai `192.168.30.3` (jalur 10 GbE, MTU 9000).

### 7.2 Yang gagal mount

| Target | Sumber | Status |
|---|---|---|
| `/mnt/t4-storage` | `192.168.18.113:/media/t4/96-Storage` | 🔴 **failed** |
| `/media/t4-storage-nvme` | `192.168.30.2:/media/t4/NVME-3.6TB` | 🔴 **failed** |

Keduanya terdaftar di `/etc/fstab` tapi unit systemd-nya `failed`. Perlu dicek
apakah export-nya masih ada, atau entri fstab-nya sudah usang.

Isi `/etc/fstab` (baris jaringan):

```
192.168.18.113:/media/t4/96-Storage  /mnt/t4-storage  nfs  defaults,_netdev,nofail  0  0
192.168.30.2:/media/t4/NVME-3.6TB /media/t4-storage-nvme nfs defaults,nofail,user,soft,timeo=30,retrans=2,x-systemd.automount,x-systemd.requires=network-online.target,x-systemd.idle-timeout=10min 0 0
192.168.30.2:/bio-pool /media/bio-pool nfs defaults,nofail,user,soft,timeo=30,retrans=2,x-systemd.automount,x-systemd.requires=network-online.target,x-systemd.idle-timeout=10min 0 0
```

> **Catatan:** `192.168.30.2` (storage) dan `192.168.18.113` **belum didata**
> di repo ini. Lihat [§14](#14-node-terkait-yang-belum-didata).

---

## 8. Jaringan

| Interface | MAC | Status | Speed | MTU | IP | Peran |
|---|---|---|---|---|---|---|
| `enp1s0f0` | `c4:34:6b:fd:bc:58` | 🟢 UP | **10 Gb/s** | **9000** | `192.168.30.3/24` | jalur data ke storage |
| `enp1s0f1` | `c4:34:6b:fd:bc:5c` | ⚪ DOWN | — | 9000 | — | cadangan |
| `enp34s0f0` | `9c:6b:00:72:1f:2c` | 🟢 UP | **1 Gb/s** | 1500 | `192.168.18.178/24` | manajemen / LAN |
| `enp34s0f1` | `9c:6b:00:72:1f:2d` | ⚪ DOWN | — | 1500 | — | cadangan |
| `tailscale0` | — | 🟢 UP | — | 1280 | *(VPN)* | akses remote |

Kartu fisik:

```
01:00.0 / 01:00.1  Emulex OneConnect 10Gb NIC (be3)   → enp1s0f0 / enp1s0f1
22:00.0 / 22:00.1  Intel Ethernet Controller X550     → enp34s0f0 / enp34s0f1
```

### 8.1 Routing

```
default via 192.168.18.1 dev enp34s0f0  proto dhcp    metric 102     ← 1 GbE, MENANG
default via 192.168.30.1 dev enp1s0f0   proto static  metric 20100   ← 10 GbE
```

> ⚠️ **Ada dua default route dan yang menang adalah jalur 1 GbE** (metric 102 <
> 20100). Trafik umum keluar lewat NIC lambat; jalur 10 GbE hanya terpakai untuk
> subnet `192.168.30.0/24` (storage) karena route langsung. Selain itu IP LAN
> didapat lewat **DHCP** — bisa berubah sewaktu-waktu padahal dipakai sebagai
> `NodeAddr` di `slurm.conf`.

### 8.2 Jaringan virtual (Docker)

| Bridge | Subnet | Status |
|---|---|---|
| `docker0` | `172.17.0.0/16` | DOWN |
| `br-7d750b7f1979` | `172.18.0.0/16` | DOWN |
| `br-1d4746c471ed` | `172.19.0.0/16` | DOWN |
| `br-54f3979110fa` | `172.20.0.0/16` | DOWN |
| `docker_gwbridge` | `172.21.0.0/16` | 🟢 UP (+1 veth aktif) |

Docker Swarm aktif (`dockerd` mendengarkan di `127.0.0.1:2377` dan `:7946`).

### 8.3 DNS

`systemd-resolved` di `127.0.0.53`, `search .`.

---

## 9. Sistem Operasi & Software Stack

| Field | Nilai |
|---|---|
| **OS** | **Ubuntu 24.04.4 LTS** (Noble Numbat) |
| **Kernel** | `7.0.0-29-generic` (`#29~24.04.2`, build 2026-08-12) |
| **GCC / GFortran** | 13.3.0 |
| **Python sistem** | 3.12.3 |
| **Singularity CE** | **4.1.1** ✅ |
| **Docker** | 29.1.3 (+ Swarm) |
| **Conda** | ❌ **tidak ada** |
| **Image `.sif`** | ❌ tidak ditemukan di `/opt/containers`, `/opt/sif`, `/srv/containers` |
| **Lmod / Environment Modules** | ❌ tidak aktif |
| **NTP** | `systemd-timesyncd` aktif, jam tersinkron ✅ |
| **Zona waktu** | Asia/Jakarta (WIB, +07:00) |
| **AppArmor** | aktif ✅ |

> ⚠️ [SOP repo](../../docs/sop/sop-bioinformatics-execution.md) mensyaratkan setiap
> tool dikunci versi lewat **Conda env / Singularity image**. Singularity memang
> terpasang, tapi **tidak ada satu pun image `.sif`**, dan **Conda tidak ada**.
> Artinya reproducibility saat ini bergantung pada paket sistem — tidak memenuhi SOP.

### 9.1 Desktop environment

Node ini memasang **stack desktop lengkap**: GNOME (42 & 46), Firefox, VLC,
snap-store, firmware-updater, CUPS (`cupsd`), dan `Xorg` yang aktif di ketiga GPU.
22 snap ter-mount sebagai loop device.

Untuk node komputasi headless ini konsumsi sumber daya dan permukaan serangan
yang tidak perlu.

---

## 10. Scheduler — Slurm

| Field | Nilai |
|---|---|
| **Versi** | `slurm-wlm` **23.11.4** |
| **Cluster** | `bioinfo` |
| **Controller (`slurmctld`)** | **`pipeline` (`192.168.18.194`)** — host terpisah, ⚠️ belum didata |
| **`slurmd` di node ini** | 🟢 active |
| **`slurmctld` di node ini** | inactive *(wajar — controller di host lain)* |
| **`munge`** | 🟢 active |
| **NodeName** | `compute001` |
| **Terakhir restart `slurmd`** | 2026-08-28 14:45:18 |

### 10.1 Definisi node di `slurm.conf`

```
ClusterName=bioinfo
SlurmctldHost=pipeline(192.168.18.194)
NodeName=compute001 NodeHostname=HPC-GPU NodeAddr=192.168.18.178 \
  CPUs=256 Boards=1 SocketsPerBoard=2 CoresPerSocket=64 ThreadsPerCore=2 \
  RealMemory=1024000 Gres=gpu:a100:2,gpu:rtx5060ti:1 State=UNKNOWN
PartitionName=gpu   Nodes=compute001 Default=YES MaxTime=2-00:00:00 DefMemPerCPU=2000 State=UP
PartitionName=debug Nodes=compute001 Priority=100 MaxTime=00:30:00 DefMemPerCPU=2000 State=UP
```

### 10.2 Partisi

| Partisi | Default | MaxTime | Prioritas | DefMemPerCPU | GRES |
|---|---|---|---|---|---|
| `gpu` | ✅ Ya | 2 hari | 1 | 2000 MB | `gpu=3` |
| `debug` | Tidak | 30 menit | 100 | 2000 MB | `gpu=3` |

Keduanya `AllowGroups=ALL`, `AllowAccounts=ALL`, `QoS=N/A`, `DisableRootJobs=NO`,
`OverSubscribe=NO`, `PreemptMode=OFF`.

### 10.3 Status saat pendataan

```
NodeName=compute001  State=IDLE
CPUAlloc=0  CPUTot=256  CPULoad=132.39
RealMemory=1024000  AllocMem=0  FreeMem=117791
TmpDisk=0
Gres=gpu:a100:2,gpu:rtx5060ti:1   AllocTRES=(kosong)
```

Antrian `squeue`: **kosong**, tidak ada job sama sekali.

> 🔴 **Inilah temuan paling penting di node ini.** Slurm melaporkan
> `State=IDLE` dan `CPUAlloc=0` — dari sudut pandang scheduler node ini
> **kosong melompong**. Kenyataannya `CPULoad=132.39`, load average sistem
> **134.92**, dan ada **22 user login**. Artinya beban itu datang dari sesi
> interaktif langsung (SSH / VS Code Remote / R), **bukan** dari job Slurm.
>
> Konsekuensinya: kalau ada yang `sbatch`, Slurm akan menempatkan job sampai
> 256 CPU di mesin yang sudah jalan di load 134 — oversubscribe parah, dan
> semua pekerjaan yang sedang berjalan ikut melambat.

### 10.4 Perintah operasional

```bash
sinfo -N -l                          # status node
squeue -u $USER                      # job milik sendiri
scontrol show node compute001        # detail node
sbatch script.sh                     # submit job
srun --pty --gres=gpu:a100:1 bash    # sesi interaktif YANG BENAR (lewat Slurm)

# Maintenance: keluarkan node tanpa membunuh job berjalan
scontrol update NodeName=compute001 State=DRAIN Reason="maintenance"
scontrol update NodeName=compute001 State=RESUME
```

---

## 11. Monitoring

| Agen | Status | Port |
|---|---|---|
| **netdata** | 🟢 active | `127.0.0.1:8125` |
| **PCP** (`pmcd`) | 🟢 listening | `0.0.0.0:44321` |
| **PCP** (`pmproxy`) | 🟢 listening | `0.0.0.0:44322`, `:44323` |
| `otel-plugin` | listening | `127.0.0.1:4317` |
| node_exporter / DCGM exporter | ❌ tidak ada | — |

> `pmcd` dan `pmproxy` mendengarkan di **`0.0.0.0`** (semua interface), bukan
> localhost. Metrik sistem terbuka ke seluruh LAN tanpa firewall di depannya.

### 11.1 Layanan akses remote yang aktif

| Layanan | Status | Catatan |
|---|---|---|
| **Tailscale** | 🟢 UP (`tailscale0`) | VPN mesh — akses dari luar LAN |
| **cloudflared** | 🟢 listening `127.0.0.1:20241` | Cloudflare Tunnel |
| **TeamViewer** | 🟢 listening `127.0.0.1:5939` | remote desktop |
| **VS Code Remote** | 4 instance server aktif | `code-110a328ea5`, `code-6928394f91`, `code-08d4889f9e` |

> ⚠️ Ada **tiga jalur akses remote di luar SSH** (Tailscale, Cloudflare Tunnel,
> TeamViewer) yang semuanya melewati firewall perimeter. Perlu dipastikan
> ketiganya memang disengaja, dan siapa saja yang punya akses.

---

## 12. Health Check Cepat

```bash
#!/bin/bash
# quick-health-check HPC-GPU
echo "=== UPTIME & LOAD ==="  ; uptime
echo "=== SLURM vs NYATA ==="; echo "Slurm CPUAlloc: $(scontrol show node compute001 | grep -o 'CPUAlloc=[0-9]*')"; echo "Load nyata    : $(cut -d' ' -f1 /proc/loadavg)"; echo "User login    : $(who | wc -l)"
echo "=== MEMORY ==="        ; free -h
echo "=== SWAP TERPAKAI ===" ; swapon --show
echo "=== NUMA ==="          ; numactl --hardware | grep -E 'free'
echo "=== GPU ==="           ; nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,temperature.gpu --format=csv
echo "=== SCRATCH ==="       ; df -h /mnt/scratch
echo "=== RAID0 ==="         ; cat /proc/mdstat
echo "=== NFS ==="           ; df -h /media/bio-pool 2>&1
echo "=== MOUNT GAGAL ==="   ; systemctl --failed --no-pager | grep -i mount
echo "=== SMART ==="         ; for d in /dev/nvme[0-4]n1; do printf "%-14s " "$d"; smartctl -H "$d" | grep -i 'overall-health'; done
echo "=== SUHU ==="          ; sensors | grep -E 'Tctl|Composite'
echo "=== SERVICE GAGAL ===" ; systemctl --failed --no-pager
```

Ambang yang perlu tindakan:

| Indikator | Ambang | Kondisi 2026-08-28 |
|---|---|---|
| Load average vs 256 thread | > 200 | 134.92 🟡 |
| `CPUAlloc` Slurm vs load nyata | selisih > 50 | **0 vs 134** 🔴 |
| Swap terpakai | > 50% | **100%** 🔴 |
| `/mnt/scratch` | > 80% | 77% 🟡 |
| `/` | > 80% | 45% ✅ |
| Free memory per NUMA node | < 10 GB | node0 **3.2 GB** 🔴 |
| Suhu CPU (Tctl) | > 85 °C | 68–70 °C ✅ |
| Suhu NVMe (sensor tertinggi) | > 70 °C | 65.8 °C 🟡 |
| systemd failed units | > 0 | **4** 🔴 |

---

## 13. Known Issues & Risiko

Diurutkan dari dampak paling besar. Semua temuan berasal dari pengumpulan data
**2026-08-28**; belum ada yang ditindaklanjuti.

| # | Temuan | Dampak | Prioritas |
|---|---|---|---|
| 1 | **Slurm dilewati.** Node `State=IDLE`, `CPUAlloc=0`, antrian kosong — tapi load 134.92 dengan 22 user login dan 4 sesi VS Code Remote | Scheduler buta terhadap beban nyata. Job `sbatch` berikutnya akan ditumpuk di atas mesin yang sudah penuh. Melanggar [SOP §standar eksekusi](../../docs/sop/sop-bioinformatics-execution.md) | 🔴 Kritis |
| 2 | **Autentikasi SSH lemah.** `PermitRootLogin yes` + `PasswordAuthentication yes` di port 22, dan password root sangat lemah | Login root bisa ditebak. **Rotasi password root sekarang**, lalu matikan login password & root | 🔴 Kritis |
| 3 | **Swap 8 GiB terpakai 100%** (sisa 12 MiB), `node0` cuma bebas 3.2 GB dari 515 GB | Node di ambang OOM. Job berikutnya berisiko dibunuh OOM killer, atau sistem thrashing | 🔴 Kritis |
| 4 | **Disk OS SSD konsumer tanpa redundansi**, dengan riwayat throttling termal (Warning 1274 mnt, **Critical 15 mnt**) | ADATA LEGEND 800 mati = node tidak bisa boot. Riwayat suhu kritis memperbesar peluang gagal | 🔴 Kritis |
| 5 | **Firewall mati** (`ufw inactive`, hanya chain Docker), sementara `pmcd`/`pmproxy` mendengarkan di `0.0.0.0` | Metrik sistem dan layanan terbuka ke seluruh LAN | 🟠 Tinggi |
| 6 | **IPMI tanpa proteksi brute-force** — `Bad Password Threshold: 0`, cipher suite 0 aktif, SNMP community default `AMI`, VLAN disabled | BMC bisa digempur tanpa batas dari LAN yang sama dengan jaringan data | 🟠 Tinggi |
| 7 | **Tiga jalur akses remote di luar SSH**: Tailscale, Cloudflare Tunnel, TeamViewer | Melewati firewall perimeter. Perlu audit siapa yang punya akses | 🟠 Tinggi |
| 8 | **Dua mount NFS gagal** — `/mnt/t4-storage` dan `/media/t4-storage-nvme` | Data di kedua share tidak bisa diakses; pipeline yang mengacu ke path itu akan gagal | 🟠 Tinggi |
| 9 | **Default route lewat 1 GbE**, bukan 10 GbE (metric 102 vs 20100) | Trafik non-storage jalan di jalur 10× lebih lambat | 🟠 Tinggi |
| 10 | **Reproducibility tidak memenuhi SOP** — Conda tidak ada, tidak ada satu pun image `.sif`, Lmod tidak aktif | Versi tool tidak terkunci; hasil analisis sulit direproduksi | 🟠 Tinggi |
| 11 | **1 dari 16 DIMM lebih lambat** (`2G9B1` @2933 di P0 CHANNEL C) → seluruh 1 TB turun ke 2933 MT/s | Kehilangan ±9% bandwidth memori. Perbaikan termurah: ganti satu modul | 🟠 Tinggi |
| 12 | **`Tsa: Vulnerable: No microcode`** | Mitigasi Transient Scheduler Attack belum ada; perlu update microcode + BIOS | 🟠 Tinggi |
| 13 | **`/mnt/scratch` 77% penuh** di RAID0 tanpa auto-purge | Mendekati penuh; 1 NVMe mati = 3.5 TB hilang | 🟡 Sedang |
| 14 | **Slurm `TmpDisk=0`** — scratch 3.5 TB tidak terdaftar di scheduler | Job tidak bisa meminta ruang scratch; penjadwalan tidak sadar kapasitas disk | 🟡 Sedang |
| 15 | **Path scratch beda dari standar repo** — `/mnt/scratch`, bukan `/scratch` | Script yang mengikuti README akan menulis ke path yang tidak ada | 🟡 Sedang |
| 16 | **A100 SXM4 tidak ter-NVLink** (`topo` menunjukkan `NODE`, bukan `NV#`) | Job multi-GPU jalan di PCIe, jauh di bawah kemampuan SXM4. Perlu verifikasi fisik | 🟡 Sedang |
| 17 | **GPU persistence mode Disabled** di ketiga GPU | Latensi inisialisasi tiap job, driver bisa unload-reload | 🟡 Sedang |
| 18 | **CUDA Toolkit 12.0 vs driver CUDA 13.2** | Tidak bisa memakai fitur/optimasi CUDA terbaru | 🟡 Sedang |
| 19 | **IP LAN dari DHCP** padahal dipakai sebagai `NodeAddr` di `slurm.conf` | IP berubah = node lepas dari cluster | 🟡 Sedang |
| 20 | **Stack desktop lengkap di node compute** — GNOME, Firefox, VLC, CUPS, Xorg di ketiga GPU, 22 snap | Sumber daya dan permukaan serangan yang tidak perlu | 🟡 Sedang |
| 21 | **`logrotate.service` failed** | Log tidak dirotasi — `/` bisa penuh perlahan | 🟡 Sedang |
| 22 | **Serial & manufacturer DMI `To Be Filled By O.E.M.`** | Identitas aset tidak ada — wajib pakai asset tag fisik | 🟢 Rendah |
| 23 | **BIOS P3.50 (2022-10-27)**, ± 4 tahun | Tertinggal perbaikan stabilitas & microcode | 🟢 Rendah |
| 24 | **`NetworkManager-wait-online.service` failed** | Layanan yang butuh jaringan saat boot bisa start terlalu dini | 🟢 Rendah |
| 25 | **RTX 5060 Ti tanpa ECC** dicampur dengan A100 dalam GRES yang sama | Job bisa mendarat di GPU tanpa ECC tanpa disadari | 🟢 Rendah |

---

## 14. Node Terkait yang Belum Didata

Pendataan node ini memunculkan tiga host lain yang belum ada dokumennya:

| Host | Peran | Ditemukan dari |
|---|---|---|
| `pipeline` — `192.168.18.194` | **Slurm controller** (`slurmctld`) cluster `bioinfo` | `slurm.conf` |
| `192.168.30.2` | Storage NFS — export `/bio-pool` (20 T) dan `/media/t4/NVME-3.6TB` | mount aktif + fstab |
| `192.168.18.113` | Storage NFS — export `/media/t4/96-Storage` | fstab (mount gagal) |

Ketiganya perlu didata mengikuti [`docs/penginputan-node.md`](../../docs/penginputan-node.md).

---

## 15. Akun dengan Shell Login

| User | Shell |
|---|---|
| `root` | `/bin/bash` |
| `hpc-gpu` | `/bin/bash` |
| `ilham` | `/bin/bash` |
| `jeffrey` | `/bin/bash` |
| `dewi` | `/bin/bash` |
| `reinhart` | `/bin/bash` |
| `angelo` | `/bin/bash` |
| `kila` | `/bin/bash` |
| `autopipeline` | `/bin/bash` |

7 akun pengguna + `root` + 1 akun layanan (`autopipeline`).
Saat pendataan tercatat **22 sesi login aktif**.

---

## 16. Cara Memperbarui Dokumen Ini

```bash
bash scripts/collect-hpc.sh 192.168.18.178 root ~/.ssh/<key> > /tmp/hpc-$(date +%F).txt
```

Prosedur lengkap ada di [`docs/penginputan-node.md`](../../docs/penginputan-node.md).
Setiap perubahan fisik / konfigurasi **wajib** dicatat juga di
[`track-record/server-changelog.md`](../../track-record/server-changelog.md).

---

## 17. Lampiran — Gambar & Diagram

Belum ada. Simpan foto rak di `assets/images/racks/hpc-gpu-rack.png` lalu panggil:

```markdown
![Posisi rak HPC-GPU](../../assets/images/racks/hpc-gpu-rack.png)
```

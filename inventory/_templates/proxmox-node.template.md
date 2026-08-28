# proxmox-node-01 — Proxmox VE Host (Bare-Metal)

> **Tipe Unit:** Bare-Metal Hypervisor Host — 1 chassis fisik
> **Status:** 🟢 Production
> **Terakhir Diperbarui:** 2026-08-28
> **PIC Node:** *(isi nama sysadmin)*
> **Dokumen Terkait:** [server-changelog](../../track-record/server-changelog.md) · [maintenance-log](../../track-record/maintenance-log.md)

![Posisi rak proxmox-node-01](../../assets/images/racks/proxmox-node-01-rack.png)

> **Peran node ini:** menjalankan **layanan pendukung** cluster (Git, database,
> monitoring, LDAP, portal). **Bukan** untuk workload komputasi bioinformatics —
> semua job berat harus di HPC node bare-metal via Slurm.

---

## 1. Identitas & Aset Fisik

| Field | Nilai |
|---|---|
| **Hostname (short)** | `proxmox-node-01` |
| **FQDN** | `proxmox-node-01.hpc.local` |
| **Alias / Label Fisik** | `PVE-01` |
| **Serial Number** | `SN-ZZZZZZZ` |
| **Asset Tag (internal)** | `AST-PVE-2024-0001` |
| **Vendor** | Dell EMC / Supermicro |
| **Model** | PowerEdge R650 / SYS-121H-TNR |
| **Form Factor** | Rackmount 1U |
| **Tanggal Pembelian** | `2024-04-08` |
| **Tanggal Go-Live** | `2024-05-02` |
| **Garansi Berakhir** | `2029-04-07` |
| **Nomor Kontrak Support** | `CTR-ZZZZZZ` |
| **Status Operasional** | 🟢 Production |

### 1.1 Lokasi Fisik

| Field | Nilai |
|---|---|
| **Gedung / Ruang** | Gedung Riset — Ruang Server Lt. 2 |
| **Nama Rak** | `RACK-A01` |
| **Posisi RU** | **RU 20** (1U) |
| **PDU A** | `PDU-A01-A` → outlet **C13 #12** |
| **PDU B** | `PDU-A01-B` → outlet **C13 #12** |
| **PSU** | 2× 1100W Platinum (1+1) |
| **Daya Idle** | ± 180 W |
| **Daya Peak** | ± 520 W |
| **Berat** | ± 19 kg |
| **Label Kabel** | `A01-RU20-NET1/2`, `A01-RU20-IPMI`, `A01-RU20-PWR-A/B` |

---

## 2. Manajemen Out-of-Band (IPMI / iDRAC)

| Field | Nilai |
|---|---|
| **Tipe BMC** | iDRAC9 Enterprise |
| **IP IPMI** | `10.10.30.60/24` |
| **Gateway** | `10.10.30.1` |
| **VLAN** | **VLAN 30** |
| **MAC BMC** | `AA:BB:CC:DD:EE:60` |
| **Hostname BMC** | `idrac-proxmox-node-01.hpc.local` |
| **Firmware BMC** | `7.10.30.00` |
| **BIOS** | `1.14.0` |
| **Web UI** | `https://10.10.30.60` |
| **SOL** | Aktif |
| **Akun Admin** | `sysadmin` — password di Vaultwarden `IPMI / proxmox-node-01` |

```bash
ipmitool -I lanplus -H 10.10.30.60 -U sysadmin -P '<...>' chassis power status
ipmitool -I lanplus -H 10.10.30.60 -U sysadmin -P '<...>' sel elist
ipmitool -I lanplus -H 10.10.30.60 -U sysadmin -P '<...>' chassis identify 60
```

---

## 3. Spesifikasi Hardware Host

| Komponen | Spesifikasi |
|---|---|
| **CPU** | 2× Intel Xeon Gold 6338 (32C/64T @ 2.00 GHz) |
| **Total Core / Thread** | **64 core / 128 thread** |
| **RAM** | **512 GB** DDR4 ECC RDIMM 3200 MT/s (16× 32 GB) |
| **NUMA** | 2 node |
| **Boot Disk** | 2× Micron 7450 PRO 480 GB NVMe M.2 → ZFS mirror `rpool` |
| **VM Datastore** | 4× Samsung PM9A3 3.84 TB NVMe U.2 → ZFS `vmdata` (2× mirror, striped) |
| **NIC** | 2× 1 GbE onboard + 2× 25 GbE SFP28 |
| **GPU** | Tidak ada |
| **TPM** | TPM 2.0 aktif |

```bash
lscpu | grep -E 'Model name|Socket|Core|Thread|NUMA'
free -h
sudo dmidecode -t 17 | grep -E 'Locator|Size|Speed'
lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL
```

---

## 4. Proxmox VE & Cluster

| Field | Nilai |
|---|---|
| **Versi Proxmox VE** | `8.2.4` |
| **Kernel** | `6.8.8-2-pve` |
| **Basis OS** | Debian 12 (Bookworm) |
| **Web UI** | `https://10.10.10.60:8006` |
| **Repository** | `pve-no-subscription` *(ganti ke `pve-enterprise` bila berlangganan)* |
| **Nama Cluster** | `hpc-cluster-pve` |
| **Anggota Cluster** | `proxmox-node-01` (saat ini node tunggal) |
| **Quorum** | 1/1 — **tidak ada HA otomatis** |
| **QDevice** | Belum ada — direncanakan saat node kedua ditambahkan |
| **Corosync Ring0** | `10.10.10.60` (VLAN 10) |
| **Fencing** | Tidak aktif (node tunggal) |

```bash
pveversion -v
pvecm status
pvecm nodes
systemctl status pve-cluster corosync
```

---

## 5. Konfigurasi Jaringan: Bridge & VLAN

### 5.1 Interface fisik

| Interface | MAC | Speed | Bonding | Fungsi |
|---|---|---|---|---|
| `eno1` | `AA:BB:CC:DD:EE:61` | 1 GbE | — | Manajemen host (VLAN 10) |
| `eno2` | `AA:BB:CC:DD:EE:62` | 1 GbE | — | Cadangan / tidak terpakai |
| `ens3f0` | `AA:BB:CC:DD:EE:63` | 25 GbE | `bond0` | Trafik VM & storage |
| `ens3f1` | `AA:BB:CC:DD:EE:64` | 25 GbE | `bond0` | Trafik VM & storage |

### 5.2 Bridge

| Bridge | Uplink | VLAN Aware | IP Host | Fungsi |
|---|---|---|---|---|
| `vmbr0` | `eno1` | Tidak | `10.10.10.60/24` | Manajemen host + web UI |
| `vmbr1` | `bond0` (LACP) | **Ya** | *(tanpa IP)* | Trafik VM/LXC, VLAN tagged |
| `vmbr2` | *(tanpa uplink)* | Tidak | `192.168.99.1/24` | Jaringan internal isolated antar VM |

### 5.3 VLAN yang dipakai

| VLAN ID | Nama | Subnet | Gateway | Fungsi |
|---|---|---|---|---|
| 10 | `MGMT` | `10.10.10.0/24` | `10.10.10.1` | Manajemen server & switch |
| 20 | `DATA` | `10.10.20.0/24` | `10.10.20.1` | Trafik NFS/storage berkecepatan tinggi |
| 30 | `IPMI` | `10.10.30.0/24` | `10.10.30.1` | Out-of-band terisolasi |
| 40 | `SERVICES` | `10.10.40.0/24` | `10.10.40.1` | VM layanan (Git, DB, monitoring) |
| 50 | `DMZ` | `10.10.50.0/24` | `10.10.50.1` | Layanan yang dipublikasi terbatas |
| 99 | `ISOLATED` | `192.168.99.0/24` | `192.168.99.1` | Jaringan uji tanpa uplink |

### 5.4 `/etc/network/interfaces`

```
auto lo
iface lo inet loopback

# --- Manajemen host ---
iface eno1 inet manual
iface eno2 inet manual

auto vmbr0
iface vmbr0 inet static
        address 10.10.10.60/24
        gateway 10.10.10.1
        bridge-ports eno1
        bridge-stp off
        bridge-fd 0
#Manajemen host + Proxmox Web UI

# --- Bond 25GbE untuk trafik VM ---
iface ens3f0 inet manual
        mtu 9000
iface ens3f1 inet manual
        mtu 9000

auto bond0
iface bond0 inet manual
        bond-slaves ens3f0 ens3f1
        bond-miimon 100
        bond-mode 802.3ad
        bond-xmit-hash-policy layer3+4
        bond-lacp-rate fast
        mtu 9000

auto vmbr1
iface vmbr1 inet manual
        bridge-ports bond0
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes
        bridge-vids 2-4094
        mtu 9000
#Trafik VM/LXC, VLAN aware

# --- Akses host ke VLAN 20 (untuk mount NFS backup) ---
auto vmbr1.20
iface vmbr1.20 inet static
        address 10.10.20.60/24
        mtu 9000
#Akses storage-node-01 untuk vzdump

# --- Jaringan isolated tanpa uplink ---
auto vmbr2
iface vmbr2 inet static
        address 192.168.99.1/24
        bridge-ports none
        bridge-stp off
        bridge-fd 0
#Jaringan uji internal, tanpa akses keluar

source /etc/network/interfaces.d/*
```

```bash
ip -br addr
brctl show
bridge vlan show
cat /proc/net/bonding/bond0
ping -M do -s 8972 -c 4 10.10.20.50
```

---

## 6. ZFS Datastore Lokal

### 6.1 Pool

| Pool | Topologi | Perangkat | Raw | Usable | Kompresi | Fungsi |
|---|---|---|---|---|---|---|
| `rpool` | mirror | 2× Micron 7450 PRO 480 GB M.2 | 960 GB | 440 GB | `lz4` | OS Proxmox |
| `vmdata` | 2× mirror (striped) | 4× Samsung PM9A3 3.84 TB U.2 | 15.36 TB | **6.9 TB** | `lz4` | Disk VM & LXC |

```
vmdata
├── mirror-0
│    ├── nvme-SAMSUNG_MZQL23T8HCLS_V001
│    └── nvme-SAMSUNG_MZQL23T8HCLS_V002
└── mirror-1
     ├── nvme-SAMSUNG_MZQL23T8HCLS_V003
     └── nvme-SAMSUNG_MZQL23T8HCLS_V004
```

> **Mirror, bukan raidz** — disk VM adalah beban random I/O.
> raidz punya IOPS setara satu disk per vdev; mirror memberi IOPS jauh lebih tinggi.

### 6.2 Properti dataset ZFS untuk VM

| Properti | Nilai | Alasan |
|---|---|---|
| `compression` | `lz4` | Hemat ruang, overhead CPU minim |
| `volblocksize` | `16K` | Cocok untuk beban campuran VM |
| `atime` | `off` | Kurangi write amplification |
| `sync` | `standard` | — |
| `ashift` | `12` | 4K sector |
| `autotrim` | `on` | Jaga performa NVMe |
| ARC max | **64 GB** | Sisakan RAM untuk VM (`/etc/modprobe.d/zfs.conf`) |

### 6.3 Storage yang terdaftar di Proxmox

| Storage ID | Tipe | Path / Target | Konten | Shared | Kapasitas | Terpakai |
|---|---|---|---|---|---|---|
| `local` | Directory | `/var/lib/vz` | ISO, template CT, snippet | Tidak | 440 GB | 68 GB |
| `local-zfs` | ZFS Pool | `rpool/data` | Disk VM (`images`), `rootdir` | Tidak | 440 GB | 12 GB |
| `vmdata` | ZFS Pool | `vmdata` | Disk VM (`images`), `rootdir` | Tidak | 6.9 TB | 2.4 TB |
| `nfs-backup` | NFS | `10.10.20.50:/tank/backup` | `backup`, `vztmpl`, `iso` | Ya | 40 TB | 12 TB |

`/etc/pve/storage.cfg`:
```
dir: local
        path /var/lib/vz
        content iso,vztmpl,snippets
        prune-backups keep-all=1

zfspool: local-zfs
        pool rpool/data
        content images,rootdir
        sparse 1

zfspool: vmdata
        pool vmdata
        content images,rootdir
        sparse 1
        blocksize 16k

nfs: nfs-backup
        export /tank/backup
        path /mnt/pve/nfs-backup
        server 10.10.20.50
        content backup,iso,vztmpl
        options vers=4.2
        prune-backups keep-daily=7,keep-weekly=4,keep-monthly=6
```

```bash
zpool status
zpool list -v
zfs list -o name,used,avail,refer,volblocksize
pvesm status
pvesm list vmdata
arc_summary | head -20
```

---

## 7. Daftar VM & LXC Aktif

### 7.1 Tabel VM (KVM)

| VMID | Nama | OS | vCPU | RAM | Disk | Storage | IP | VLAN | Bridge | Autostart | Boot Order | Fungsi | PIC |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `101` | `gitlab-server` | Ubuntu 22.04 | 8 | 32 GB | 500 GB | `vmdata` | `10.10.40.11/24` | 40 | `vmbr1` | Ya | 1 | GitLab CE — repo pipeline & dokumentasi | sysadmin |
| `102` | `db-postgres` | Debian 12 | 8 | 64 GB | 1 TB | `vmdata` | `10.10.40.12/24` | 40 | `vmbr1` | Ya | 2 | PostgreSQL 16 — metadata sampel, DB Slurm accounting | sysadmin |
| `103` | `monitoring` | Debian 12 | 6 | 32 GB | 800 GB | `vmdata` | `10.10.40.13/24` | 40 | `vmbr1` | Ya | 3 | Prometheus + Grafana + Alertmanager | sysadmin |
| `104` | `galaxy-web` | Ubuntu 22.04 | 12 | 64 GB | 600 GB | `vmdata` | `10.10.40.14/24` | 40 | `vmbr1` | Ya | 5 | Galaxy Project — antarmuka web bioinformatics | bioinfo-lead |
| `105` | `ldap-auth` | Debian 12 | 4 | 8 GB | 100 GB | `local-zfs` | `10.10.10.7/24` | 10 | `vmbr1` | Ya | 0 | OpenLDAP + SSSD backend | sysadmin |
| `106` | `backup-proxy` | Debian 12 | 4 | 16 GB | 200 GB | `vmdata` | `10.10.20.61/24` | 20 | `vmbr1` | Ya | 6 | Proxmox Backup Server | sysadmin |
| `107` | `jupyterhub` | Ubuntu 22.04 | 16 | 96 GB | 500 GB | `vmdata` | `10.10.40.15/24` | 40 | `vmbr1` | Ya | 7 | JupyterHub — analisis interaktif ringan (R/Python) | bioinfo-lead |
| `108` | `test-sandbox` | Rocky 9.4 | 4 | 16 GB | 200 GB | `vmdata` | `192.168.99.10/24` | 99 | `vmbr2` | **Tidak** | — | Sandbox uji, tanpa akses jaringan luar | sysadmin |

### 7.2 Tabel LXC Container

| CTID | Nama | Template | vCPU | RAM | Swap | Disk | Storage | IP | VLAN | Bridge | Autostart | Unprivileged | Fungsi | PIC |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `201` | `dns-dhcp` | debian-12 | 2 | 2 GB | 512 MB | 20 GB | `local-zfs` | `10.10.10.5/24` | 10 | `vmbr1` | Ya | Ya | Pi-hole/Unbound + DHCP + NTP | sysadmin |
| `202` | `docs-wiki` | debian-12 | 2 | 4 GB | 512 MB | 50 GB | `vmdata` | `10.10.40.21/24` | 40 | `vmbr1` | Ya | Ya | Wiki.js — dokumentasi internal | sysadmin |
| `203` | `log-server` | debian-12 | 4 | 16 GB | 2 GB | 500 GB | `vmdata` | `10.10.10.20/24` | 10 | `vmbr1` | Ya | Ya | rsyslog + Loki — agregasi log semua node | sysadmin |
| `204` | `vaultwarden` | debian-12 | 2 | 2 GB | 512 MB | 20 GB | `vmdata` | `10.10.40.22/24` | 40 | `vmbr1` | Ya | Ya | Password manager (kredensial IPMI dll.) | sysadmin |
| `205` | `reverse-proxy` | debian-12 | 2 | 4 GB | 512 MB | 20 GB | `vmdata` | `10.10.50.10/24` | 50 | `vmbr1` | Ya | Ya | Nginx/Caddy + TLS termination | sysadmin |

### 7.3 Ringkasan alokasi resource

| Resource | Kapasitas Host | Teralokasi | Rasio | Terpakai Riil | Catatan |
|---|---|---|---|---|---|
| **vCPU** | 128 thread | 78 vCPU | **0.61×** | ± 22% | Overcommit CPU aman (rasio < 3× umumnya oke) |
| **RAM** | 512 GB | 356 GB | **0.70×** | ± 61% | **Tidak overcommit RAM** — ZFS ARC 64 GB + host ± 16 GB harus punya ruang |
| **Disk (`vmdata`)** | 6.9 TB | 4.32 TB (thin) | 0.63× | 2.4 TB | Thin provisioning aktif; pantau agar tidak melewati 80% pool |
| **Disk (`local-zfs`)** | 440 GB | 120 GB | 0.27× | 12 GB | |

> ⚠️ **Jangan overcommit RAM di host ZFS.** Jika total RAM VM + ARC + host melebihi
> RAM fisik, ZFS akan mengecilkan ARC secara agresif atau OOM Killer akan membunuh
> proses VM. Batas aman yang dipakai: **total RAM VM ≤ 400 GB**.

### 7.4 Perintah pengelolaan VM/LXC

```bash
# Daftar
qm list
pct list
pvesh get /cluster/resources --type vm

# Konfigurasi satu VM
qm config 101
pct config 201

# Siklus hidup
qm start 101 ; qm shutdown 101 ; qm stop 101 ; qm reboot 101
pct start 201 ; pct shutdown 201

# Snapshot
qm snapshot 101 pre-upgrade-2026-09-05 --description "Sebelum upgrade GitLab 17"
qm listsnapshot 101
qm rollback 101 pre-upgrade-2026-09-05

# Migrasi (bila cluster sudah >1 node)
qm migrate 101 proxmox-node-02 --online

# Konsol
qm terminal 101
pct enter 201

# Cek resource
qm monitor 101
pvesh get /nodes/proxmox-node-01/status
```

---

## 8. Backup

| Field | Nilai |
|---|---|
| **Metode Utama** | `vzdump` → storage `nfs-backup` (`storage-node-01`) |
| **Metode Sekunder** | Proxmox Backup Server (VM `106`) — deduplikasi & verifikasi |
| **Mode** | `snapshot` (VM tetap berjalan) |
| **Kompresi** | `zstd` |
| **Jadwal Harian** | 01:00 — semua VM/LXC kecuali `108 test-sandbox` |
| **Jadwal Mingguan** | Minggu 03:00 — backup penuh + verifikasi |
| **Retensi** | `keep-daily=7, keep-weekly=4, keep-monthly=6` |
| **Notifikasi** | Email saat gagal |
| **Uji Restore Terakhir** | `2026-07-19` — VM `102` di-restore ke sandbox, sukses, RTO 38 menit |

`/etc/pve/jobs.cfg`:
```
vzdump: backup-harian
        schedule 01:00
        storage nfs-backup
        mode snapshot
        compress zstd
        exclude 108
        mailnotification failure
        notes-template "{{guestname}} - {{node}}"
        prune-backups keep-daily=7,keep-weekly=4,keep-monthly=6
```

```bash
# Backup manual satu VM
vzdump 101 --storage nfs-backup --mode snapshot --compress zstd

# Daftar backup
pvesm list nfs-backup

# Restore
qmrestore /mnt/pve/nfs-backup/dump/vzdump-qemu-101-2026_08_27-01_00_02.vma.zst 999 --storage vmdata
pct restore 999 /mnt/pve/nfs-backup/dump/vzdump-lxc-201-2026_08_27-01_05_11.tar.zst --storage vmdata
```

---

## 9. Firewall & Keamanan

| Field | Nilai |
|---|---|
| **Firewall Proxmox** | Aktif di level datacenter dan node |
| **Policy Default In** | `DROP` |
| **Policy Default Out** | `ACCEPT` |
| **Akses Web UI** | Hanya dari `10.10.10.0/24` |
| **SSH Host** | Hanya key-based, `PermitRootLogin prohibit-password` |
| **2FA Web UI** | TOTP aktif untuk semua akun admin |
| **Akun** | `root@pam` (emergency), `sysadmin@pve` (harian), `readonly@pve` (audit) |
| **Sertifikat TLS** | Let's Encrypt via DNS-01 *(atau CA internal)* |

Aturan firewall node (`/etc/pve/firewall/cluster.fw` — potongan):
```
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT

[RULES]
IN SSH(ACCEPT) -source 10.10.10.0/24 -log nolog
IN ACCEPT -source 10.10.10.0/24 -p tcp -dport 8006 -log nolog   # Web UI
IN ACCEPT -source 10.10.10.0/24 -p tcp -dport 3128 -log nolog   # SPICE proxy
IN ACCEPT -source 10.10.10.0/24 -p icmp
```

```bash
pve-firewall status
pve-firewall compile
iptables -L -n -v | head -40
```

---

## 10. Health Check Cepat

```bash
#!/usr/bin/env bash
# quick-health-check proxmox-node-01
echo "=== VERSI ==="       ; pveversion -v | head -10
echo "=== CLUSTER ==="     ; pvecm status
echo "=== UPTIME/LOAD ===" ; uptime
echo "=== RESOURCE ==="    ; pvesh get /nodes/$(hostname -s)/status --output-format yaml | head -30
echo "=== VM ==="          ; qm list
echo "=== LXC ==="         ; pct list
echo "=== STORAGE ==="     ; pvesm status
echo "=== ZFS ==="         ; zpool status; zpool list -v; zfs list
echo "=== ARC ==="         ; arc_summary | head -20
echo "=== NETWORK ==="     ; ip -br addr; brctl show; cat /proc/net/bonding/bond0 | grep -E 'Status|MII'
echo "=== BRIDGE VLAN ===" ; bridge vlan show
echo "=== BACKUP ==="      ; pvesm list nfs-backup | tail -20
echo "=== FIREWALL ==="    ; pve-firewall status
echo "=== SERVICE GAGAL ==="; systemctl --failed
echo "=== ERROR LOG ==="   ; journalctl -p err -b --no-pager | tail -30
```

---

## 11. Riwayat Perubahan Node Ini

| Tanggal | Jenis | Ringkasan | Ref |
|---|---|---|---|
| 2024-05-02 | Instalasi | Go-live Proxmox VE 8.1, `rpool` mirror, `vmdata` 2× mirror | `SCL-2024-003` |
| 2024-08-19 | Software | Deploy VM `101 gitlab-server` & `103 monitoring` | `SCL-2024-011` |
| 2025-01-27 | Hardware | RAM 256 GB → **512 GB** (tambah 8× 32 GB) | `SCL-2025-002` |
| 2025-06-30 | Network | Tambah dual 25GbE, buat `bond0` + `vmbr1` VLAN-aware, MTU 9000 | `SCL-2025-008` |
| 2025-10-14 | Software | Upgrade Proxmox VE 8.1 → 8.2, kernel `6.5` → `6.8` | `SCL-2025-014` |
| 2026-02-11 | Storage | Tambah `vmdata` mirror-1 (2× PM9A3 3.84 TB), kapasitas naik 3.45 → 6.9 TB | `SCL-2026-002` |
| 2026-05-06 | Keamanan | Aktifkan TOTP 2FA untuk semua akun admin, policy_in DROP | `SCL-2026-005` |

---

## 12. Known Issues & Risiko

| ID | Deskripsi | Dampak | Mitigasi | Status |
|---|---|---|---|---|
| `KI-P01` | Cluster node tunggal — tidak ada HA / live migration | Semua VM layanan mati jika host mati | Backup harian + PBS + RTO 1 jam; usulan `proxmox-node-02` di anggaran | Risiko diterima |
| `KI-P02` | LXC `201 dns-dhcp` adalah DNS satu-satunya | Resolusi nama seluruh cluster mati bila CT ini down | Semua node punya entri fallback di `/etc/hosts`; autostart prioritas 0 | Mitigasi aktif |
| `KI-P03` | VM `107 jupyterhub` sering dipakai user untuk analisis berat | Menghabiskan CPU host, mengganggu VM lain | Batas cgroup `cpuunits=500`; user diarahkan ke Slurm sesuai SOP | Dipantau |
| `KI-P04` | Repository `pve-no-subscription` | Tidak ada dukungan enterprise & update kurang tervalidasi | Uji upgrade di VM `108 test-sandbox` dulu | Diterima |
| `KI-P05` | `vmdata` thin provisioning teralokasi 4.32 TB dari 6.9 TB | Risiko pool penuh bila semua VM mengisi disknya | Alarm di 75% pool; audit alokasi tiap kuartal | Dipantau |

---

## 13. Lampiran — Gambar & Diagram

| Gambar | Path | Keterangan |
|---|---|---|
| Foto rak | `../../assets/images/racks/proxmox-node-01-rack.png` | Posisi RU 20 |
| Topologi jaringan | `../../assets/images/diagrams/proxmox-node-01-network-bridge.png` | vmbr0/vmbr1/vmbr2 + VLAN |
| Peta VM | `../../assets/images/diagrams/proxmox-node-01-vm-map.png` | VM/LXC ↔ VLAN ↔ IP |
| Screenshot dashboard | `../../assets/images/screenshots/proxmox-node-01-dashboard.png` | Ringkasan resource host |
| Screenshot storage | `../../assets/images/screenshots/proxmox-node-01-storage.png` | Status datastore |

```markdown
![Topologi bridge proxmox-node-01](../../assets/images/diagrams/proxmox-node-01-network-bridge.png)
```

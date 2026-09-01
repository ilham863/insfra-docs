# VM 101 — SMRT Link / PacBio Vega (di `PROXMOX-2U`)

> **Tipe Unit:** Virtual Machine (KVM) di atas [`proxmox`](proxmox.md) — bukan unit fisik
> **Status:** 🔵 Staging — VM sudah dibuat, **OS belum diinstall**
> **Terakhir Diperbarui:** 2026-09-02
> **PIC:** *(isi)*
> **Sumber Data:** dibuat & diverifikasi langsung via `qm` di host, 2026-09-02
> **Dokumen Terkait:** [proxmox](proxmox.md) · [network-map](../network-map.md) · [zyxel-switch](../network-devices/zyxel-switch.md) · [hpc-gpu](../hpc-nodes/hpc-gpu.md) · [README §2.2](../../README.md#22-arsitektur-target--proxmox-sebagai-ingress-data)

> **Peran VM ini:** menjalankan **SMRT Link** untuk sekuenser **PacBio Vega**,
> sekaligus menjadi **gateway/NAT** bagi instrumen dan **jalur akses ke HPC**.
> Ini adalah perwujudan pertama dari desain *ingress data* di
> [README §2.2](../../README.md#22-arsitektur-target--proxmox-sebagai-ingress-data):
> data dari sekuenser masuk lewat satu pintu di `PROXMOX-2U`, bukan langsung
> mendarat di storage analisis.

---

## 1. Topologi

```
                              ☁ INTERNET
                                   │
                        ┌──────────┴───────────┐
                        │   ONT Huawei HG8245  │  192.168.18.1
                        └──────────┬───────────┘
                                   │
                        Zyxel MGS3520-28FX  e0/0/3
                                   │  1 GbE
                        ┌──────────┴───────────┐
                        │   PROXMOX-2U host    │  192.168.18.190
                        │   nic0 ── vmbr0      │
                        └──────────┬───────────┘
                                   │
   ╔═══════════════════════════════╧════════════════════════════════════╗
   ║                    VM 101  —  SMRT Link                            ║
   ║              32 vCPU · 64 GB RAM · Ubuntu 24.04 Desktop            ║
   ║                                                                    ║
   ║   net0 (ens18) ── vmbr0 ── 192.168.18.60/24                        ║
   ║        └─► internet · akses HPC-GPU · akses T4-Storage             ║
   ║                                                                    ║
   ║   net1 (ens19) ── vmbr1 ── 192.168.50.1/24   ◄── GATEWAY VEGA      ║
   ║        └─► NAT keluar · isolasi ke arah LAN                        ║
   ║                                                                    ║
   ║   scsi0  1000 GiB SSD  (nvme-scratch)  → OS + SMRT Link + DB       ║
   ║   scsi1  7,81 TiB HDD  (vm-hdd)        → data run                  ║
   ╚═══════════════════════════════╤════════════════════════════════════╝
                                   │
                        ┌──────────┴───────────┐
                        │  PROXMOX-2U  nic1    │  ⚠️ host TIDAK punya IP
                        │       vmbr1          │     di bridge ini
                        └──────────┬───────────┘
                                   │  kabel LAN langsung
                        ┌──────────┴───────────┐
                        │   PacBio Vega        │  192.168.50.10/24
                        │   (sekuenser)        │  gw 192.168.50.1
                        └──────────────────────┘
```

### 1.1 Alur data

```
Vega ──run data──► VM 101 (SMRT Link)
                      │
                      ├── scsi1 7,81 TiB  ← data run mendarat di sini
                      │
                      ├── arsip ──► zfs-storage/archive  (di host yang sama)
                      │
                      └── analisis ──► HPC-GPU 192.168.18.178
                                        ⚠️ sekarang lewat 1 GbE — lihat §7
```

### 1.2 Alur internet Vega

```
Vega 192.168.50.10
   │  gateway 192.168.50.1
   ▼
VM ens19 ──[ip_forward=1]──► VM ens18 ──[masquerade]──► 192.168.18.60
                                                              │
                                                              ▼
                                                   ONT 192.168.18.1 ──► internet
```

> **ONT tidak perlu route apa pun ke `192.168.50.0/24`.** Karena memakai
> *masquerade*, semua paket Vega keluar dengan alamat asal `192.168.18.60` —
> bagi ONT seolah-olah VM itu sendiri yang mengakses internet.

---

## 2. Spesifikasi VM

| Field | Nilai |
|---|---|
| **VMID** | `101` |
| **Nama** | `ubuntu24-desktop` |
| **Tags** | `desktop`, `ubuntu`, `vega` |
| **Status** | ⚪ stopped — OS belum diinstall |
| **vCPU** | **32** (`sockets 1` × `cores 32`), `cpu: host` |
| **RAM** | **64 GiB** (`memory 65536`), **ballooning off** (`balloon 0`) |
| **BIOS** | OVMF (UEFI), `pre-enrolled-keys=0` — Secure Boot **off** |
| **Machine** | `q35` |
| **SCSI controller** | `virtio-scsi-single` |
| **VGA** | `std` |
| **Guest agent** | aktif (`agent: enabled=1`) — perlu `qemu-guest-agent` di dalam VM |
| **ISO** | `ubuntu-24.04.4-desktop-amd64.iso` |
| **Boot order** | `ide2` (CD) → `scsi0` |

> **Soal "16 core / 32 thread":** Proxmox tidak punya opsi `threads` — yang
> dihitung jumlah vCPU. 32 vCPU memberi kapasitas komputasi yang setara.
> Kalau guest perlu benar-benar *melihat* topologi 16c×2t, tambahkan
> `args: -smp 32,sockets=1,cores=16,threads=2` — kosmetik, bukan performa.

---

## 3. Storage

| Disk | Storage PVE | Backing ZFS | Ukuran | Opsi | Peruntukan |
|---|---|---|---|---|---|
| `scsi0` | `nvme-scratch` | `nvme-scratch/vm-101-disk-0` | **1000 GiB** | `ssd=1`, `discard=on`, `iothread=1` | OS + instalasi SMRT Link + database |
| `scsi1` | **`vm-hdd`** | `zfs-storage/vm-disks/vm-101-disk-0` | **7,81 TiB** | `discard=on`, `iothread=1`, `volblocksize 64K` | Data run PacBio |
| `efidisk0` | `nvme-scratch` | `nvme-scratch/vm-101-disk-1` | 1 MiB | `efitype=4m` | Variabel UEFI |

### 3.1 Storage PVE yang dibuat untuk ini

| Nama | Tipe | Dataset | Quota | Content |
|---|---|---|---|---|
| **`vm-hdd`** | `zfspool` | `zfs-storage/vm-disks` | **10 TiB** | `images`, `rootdir` — `sparse`, `blocksize 64k` |
| **`pve-backup`** | `dir` | `zfs-storage/backup` | **20 TiB** | `backup` — retensi 7 harian / 4 mingguan / 3 bulanan |

```bash
zfs create -o quota=10T zfs-storage/vm-disks
zfs create -o quota=20T -o compression=zstd-3 zfs-storage/backup
pvesm add zfspool vm-hdd --pool zfs-storage/vm-disks --content images,rootdir --sparse 1 --blocksize 64k
pvesm add dir pve-backup --path /zfs-storage/backup --content backup \
        --prune-backups keep-daily=7,keep-weekly=4,keep-monthly=3
```

> **Kenapa disk 7,81 TiB padahal quota 10 TiB:** `zfs-storage` itu **raidz2 11 disk**,
> yang menambah paritas ± 25%. Disk 10 TiB yang terisi penuh akan memakan
> ± 12,5 TiB dan **menabrak quota sebelum penuh**. 7,81 TiB dipilih agar benar-benar
> muat. Kalau ingin guest melihat 10 TB utuh:
> ```bash
> zfs set quota=13T zfs-storage/vm-disks
> qm resize 101 scsi1 +2200G
> ```

> **Kenapa `volblocksize 64K`, bukan default 16K:** pada raidz2 selebar 11 disk
> dengan `ashift=12`, blok 16K menimbulkan padding besar. 64K memangkas overhead
> itu secara signifikan untuk beban tulis berkas besar seperti data sekuenser.

---

## 4. Jaringan

| Interface VM | MAC | Bridge | NIC fisik | Alamat (rencana) | Fungsi |
|---|---|---|---|---|---|
| `net0` → `ens18` | `BC:24:11:FD:2A:12` | `vmbr0` | `nic0` (bersama host) | **`192.168.18.60/24`** | LAN, internet, akses HPC |
| `net1` → `ens19` | `BC:24:11:0E:E2:7A` | **`vmbr1`** | **`nic1`** (khusus) | **`192.168.50.1/24`** | Gateway segmen Vega |

`vmbr1` di host — **sengaja tanpa IP**, murni bridge L2 supaya VM yang jadi gateway:

```
auto vmbr1
iface vmbr1 inet manual
	bridge-ports nic1
	bridge-stp off
	bridge-fd 0
```

> ⚠️ **Verifikasi `192.168.18.60` di luar rentang DHCP ONT**, atau buat reservasi.
> Kalau tidak, suatu saat akan bentrok dengan perangkat lain.

> **Kenapa Vega diberi segmen sendiri, bukan dicolok ke LAN utama:** instrumen
> sekuenser menjalankan firmware vendor yang jarang di-patch, sedangkan LAN utama
> adalah tempat **ketiga BMC** berada — kendali setara akses fisik ke seluruh server.
> Dengan segmen terpisah, seluruh trafik instrumen melewati satu titik yang bisa
> dikendalikan dan dicatat.

---

## 5. Konfigurasi di Dalam VM (standar)

Belum diterapkan — VM belum diinstall. Cek nama interface dulu dengan `ip -br link`.

### 5.1 Alamat IP — `/etc/netplan/01-smrtlink.yaml`

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
      addresses: [192.168.18.60/24]
      routes: [{to: default, via: 192.168.18.1}]
      nameservers: {addresses: [192.168.18.1]}
    ens19:
      dhcp4: false
      addresses: [192.168.50.1/24]
```

```bash
sudo chmod 600 /etc/netplan/01-smrtlink.yaml
sudo netplan apply
```

### 5.2 Routing — `/etc/sysctl.d/99-vega.conf`

```
net.ipv4.ip_forward = 1
```

### 5.3 NAT & isolasi — `/etc/nftables.conf`

```nft
#!/usr/sbin/nft -f
flush ruleset

table inet vega {
  chain input {
    type filter hook input priority 0; policy accept;
  }

  chain forward {
    type filter hook forward priority 0; policy drop;

    ct state established,related accept

    # Vega DILARANG menjangkau jaringan internal
    iifname "ens19" ip daddr 192.168.18.0/24 drop     # LAN server + SELURUH BMC
    iifname "ens19" ip daddr 192.168.30.0/24 drop     # jalur data 10 GbE
    iifname "ens19" ip daddr 192.168.0.0/22  drop     # LAN kantor

    # sisanya = internet, diizinkan
    iifname "ens19" oifname "ens18" accept
  }
}

table ip vega_nat {
  chain prerouting {
    type nat hook prerouting priority -100;
    iifname "ens18" tcp dport 8443 dnat to 192.168.50.10:443   # akses UI Vega dari LAN
  }
  chain postrouting {
    type nat hook postrouting priority 100;
    ip saddr 192.168.50.0/24 oifname "ens18" masquerade
  }
}
```

```bash
sudo systemctl enable --now nftables
```

> **Urutan aturan itu penting.** Baris `drop` harus berada **di atas** baris
> `accept`. Kalau dibalik, Vega bisa menjangkau seluruh LAN termasuk BMC.

### 5.4 Kalau Vega memaksa DHCP

Instrumen lab **sebaiknya statis**. Kalau firmware-nya memaksa DHCP, pasang
`dnsmasq` dan kunci alamatnya:

```
interface=ens19
bind-interfaces
dhcp-range=192.168.50.10,192.168.50.20,12h
dhcp-host=<MAC-Vega>,192.168.50.10
```

---

## 6. SMRT Link

| Field | Nilai |
|---|---|
| **Versi SMRT Link** | *(isi)* |
| **Web UI** | HTTPS port **`8243`** |
| **Direktori instalasi** | *(isi — taruh di `scsi0` / SSD)* |
| **Direktori data run** | *(isi — mount `scsi1` ke sini)* |
| **User service** | *(isi — jangan `root`)* |
| **Integrasi scheduler** | *(isi — lihat §7)* |

> 🔴 **Verifikasi dukungan OS sebelum install.** PacBio mendaftarkan OS yang
> didukung per versi SMRT Link, dan daftarnya biasanya tertinggal beberapa rilis
> di belakang (Rocky 8/9, Ubuntu 20.04/22.04). **Pastikan Ubuntu 24.04 ada di
> daftar versi SMRT Link yang dipakai** — jangan mengandalkan dokumen ini.
> Kalau ternyata belum didukung, `ubuntu-22.04.5-desktop-amd64.iso` sudah
> tersedia di `local:iso/`:
> ```bash
> qm set 101 --ide2 local:iso/ubuntu-22.04.5-desktop-amd64.iso,media=cdrom
> ```

> **Daftar port lengkap SMRT Link ambil dari install guide versi yang dipakai** —
> selain `8243` ada beberapa port layanan internal yang berbeda antar versi.
> Yang perlu diizinkan: dari LAN ke `8243` (akses UI), dan dari `192.168.50.0/24`
> ke VM (instrumen mengirim data).

---

## 7. Akses ke HPC — dua ganjalan

Secara jaringan VM ini **sudah bisa** menjangkau `HPC-GPU` (`192.168.18.178`) dan
`T4-Storage` (`192.168.18.193`) lewat `net0`. Tapi dua hal menahan pemanfaatannya:

| # | Ganjalan | Dampak | Rujukan |
|---|---|---|---|
| 1 | **`slurmctld` mati** — controller di `192.168.18.194` tidak merespons | SMRT Link tidak bisa melempar job ke cluster. Analisis hanya jalan lokal di VM ini (32 vCPU / 64 GB), **tidak memakai A100** | [hpc-gpu §14](../hpc-nodes/hpc-gpu.md#14-node-terkait) |
| 2 | **Jalur hanya 1 GbE** — `net0` → `vmbr0` → `nic0` | ± **3 jam per TB**. Untuk data run PacBio ini menyakitkan | [network-map §2.2](../network-map.md#22-rencana-proxmox-2u-masuk-ke-jalur-data-sebagai-ingress) |

**Solusi untuk ganjalan 2 — sudah terverifikasi bisa dikerjakan:**

Pasang NIC SFP+ 10 GbE di `PROXMOX-2U` ke port **`e0/0/25`** switch Zyxel (terbukti
kosong), masukkan ke **VLAN 30**, lalu beri VM ini **NIC ketiga** di bridge tersebut.
VM langsung bicara 10 GbE ke `HPC-GPU` dan `T4-Storage`.

| Prasyarat | Status |
|---|---|
| Slot PCIe kosong di proxmox | ✅ 5 slot (`CPU SLOT1/3/5` x16, `SLOT2/4` x8) |
| Port SFP+ kosong di switch | ✅ `e0/0/25` dan `e0/0/27` |
| Jumbo frame diteruskan switch | ✅ MTU 10248 di seluruh port |
| VLAN data sudah ada | ✅ VLAN 30 `SERVERS` |
| NIC + transceiver | ⚠️ **belum dibeli** |

---

## 8. Ketergantungan & Risiko

| ID | Temuan | Dampak | Prioritas |
|---|---|---|---|
| `KI-V01` | **`zfs-storage` pakai LUKS `none`+`noauto`** — 11 disk butuh passphrase manual saat boot | `scsi1` ada di pool ini, jadi **VM tidak bisa start setelah reboot** sebelum ada orang membuka pool secara manual | 🔴 **Kritis** |
| `KI-V02` | **Belum ada job backup** untuk VM ini | Target `pve-backup` sudah ada, tapi belum dijadwalkan. Data run tanpa salinan | 🔴 **Kritis** |
| `KI-V03` | **`scsi0` dan `rpool` berbagi satu NVMe fisik** (Lexar NM790, SSD konsumer, tanpa redundansi) | NVMe mati = OS hypervisor **dan** OS VM hilang bersamaan | 🔴 **Kritis** |
| `KI-V04` | **RAM overcommit** — VM 8+64+64 = 136 GiB, `zfs_arc_max` 200 GiB, RAM host 251 GiB | ARC akan menyusut sendiri, tapi marginnya tipis | 🟠 Tinggi |
| `KI-V05` | **`slurmctld` mati** | SMRT Link tidak bisa memakai HPC-GPU | 🟠 Tinggi |
| `KI-V06` | **Jalur ke HPC hanya 1 GbE** | ± 3 jam per TB | 🟠 Tinggi |
| `KI-V07` | **Dukungan Ubuntu 24.04 oleh SMRT Link belum diverifikasi** | Bisa berarti install ulang | 🟠 Tinggi |
| `KI-V08` | **`192.168.18.60` belum dipastikan di luar rentang DHCP ONT** | Potensi bentrok alamat | 🟡 Sedang |
| `KI-V09` | **Firewall Proxmox tidak aktif** — `firewall=1` di `net0`/`net1` tidak berefek | Isolasi hanya bergantung pada `nftables` di dalam VM | 🟡 Sedang |

### 8.1 Menurunkan `zfs_arc_max` (`KI-V04`)

```bash
echo "options zfs zfs_arc_max=103079215104" > /etc/modprobe.d/zfs.conf   # 96 GiB
update-initramfs -u
# berlaku setelah reboot
```

### 8.2 Menjadwalkan backup (`KI-V02`)

```bash
# backup manual pertama
vzdump 101 --storage pve-backup --mode snapshot --compress zstd

# jadwal harian 01:00
# Datacenter -> Backup -> Add:  storage=pve-backup, mode=snapshot, compress=zstd
```

---

## 9. Checklist Penerapan

- [x] Dataset `zfs-storage/vm-disks` (quota 10 TiB) + storage PVE `vm-hdd`
- [x] Dataset `zfs-storage/backup` (quota 20 TiB) + storage PVE `pve-backup`
- [x] Bridge `vmbr1` di `nic1` (host tanpa IP)
- [x] VM 101 dibuat — 32 vCPU, 64 GB, SSD 1000 GiB, HDD 7,81 TiB
- [x] `net1` terpasang ke `vmbr1`
- [ ] **Verifikasi dukungan Ubuntu 24.04 oleh SMRT Link** (`KI-V07`)
- [ ] Install OS: `qm start 101`, lalu konsol di `https://192.168.18.190:8006`
- [ ] Lepas ISO setelah install: `qm set 101 --ide2 none,media=cdrom --boot order=scsi0`
- [ ] Terapkan netplan, `ip_forward`, dan `nftables` (§5)
- [ ] Mount `scsi1` ke direktori data SMRT Link
- [ ] Install `qemu-guest-agent`
- [ ] Install SMRT Link, catat versi & port di §6
- [ ] Colok kabel LAN Vega ke **`nic1`** proxmox
- [ ] Set Vega: IP `192.168.50.10/24`, gw `192.168.50.1`, DNS `192.168.18.1`
- [ ] **Uji isolasi** — dari Vega, `ping 192.168.18.13` **harus gagal**
- [ ] Jadwalkan backup (`KI-V02`)
- [ ] Turunkan `zfs_arc_max` (`KI-V04`)

### 9.1 Uji sebelum Vega datang

Colok laptop ke port `nic1`, set manual:

```bash
# di laptop
ip addr add 192.168.50.99/24 dev <iface>
ip route add default via 192.168.50.1

ping -c2 192.168.50.1      # sampai ke VM?
ping -c2 1.1.1.1           # NAT jalan?
ping -c2 google.com        # DNS jalan?
ping -c2 192.168.18.13     # HARUS GAGAL — kalau berhasil, isolasi bocor
```

---

## 10. Perintah Pengelolaan

```bash
qm start 101 / qm stop 101 / qm shutdown 101
qm config 101
qm status 101
qm monitor 101

# konsol: https://192.168.18.190:8006  ->  VM 101  ->  Console

# ganti ISO
qm set 101 --ide2 local:iso/<nama>.iso,media=cdrom

# perbesar disk data
qm resize 101 scsi1 +1000G

# snapshot sebelum perubahan besar
qm snapshot 101 pre-smrtlink-install
qm listsnapshot 101
```

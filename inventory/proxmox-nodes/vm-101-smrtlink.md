# VM 101 — SMRT Link / PacBio Vega (di `PROXMOX-2U`)

> **Tipe Unit:** Virtual Machine (KVM) di atas [`proxmox`](proxmox.md) — bukan unit fisik
> **Status:** 🟢 **SMRT Link v26.2.0.292923 terinstall & berjalan** — instrumen Vega belum tersambung
> **Terakhir Diperbarui:** 2026-09-02
> **PIC:** *(isi)*
> **Sumber Data:** dibuat & dikonfigurasi langsung via `qm` dan **QEMU guest agent** dari host, 2026-09-02
> **Rujukan Vendor:** *SMRT Link software installation guide (v26.2)*, PN 103-891-700 Ver. 01 (Agustus 2026)
> **SOP Operasional:** [`docs/sop/sop-smrtlink-operasional.md`](../../docs/sop/sop-smrtlink-operasional.md)
> **Dokumen Terkait:** [proxmox](proxmox.md) · [network-map](../network-map.md) · [zyxel-switch](../network-devices/zyxel-switch.md) · [ont-huawei](../network-devices/ont-huawei.md) · [hpc-gpu](../hpc-nodes/hpc-gpu.md)

> **Peran VM ini:** menjalankan **SMRT Link** untuk sekuenser **PacBio Vega**,
> sekaligus **gateway/NAT** bagi instrumen dan **jalur akses ke HPC**.
> Ini perwujudan pertama desain *ingress data* di
> [README §2.2](../../README.md#22-arsitektur-target--proxmox-sebagai-ingress-data).

---

## 1. Ringkasan Status

| Bagian | Status |
|---|---|
| VM dibuat, disk & NIC terpasang | ✅ selesai |
| Ubuntu 24.04.4 LTS terinstall | ✅ selesai |
| Jaringan LAN + segmen Vega + NAT | ✅ **selesai & terverifikasi jalan** |
| Disk data 7,8 TB ter-mount permanen | ✅ selesai |
| Prasyarat SMRT Link (user, ulimit, locale, NTP, direktori) | ✅ selesai |
| **SMRT Link v26.2.0.292923 terinstall** | ✅ **selesai** — `SMRT Link Install successful` |
| **Layanan berjalan** | ✅ **`SMRT Link status: ok`** — UI di `https://192.168.18.60:8243` |
| **Site Acceptance Test** | ✅ **LULUS** — job HiFi Mapping `Job successful`, 136 detik |
| Audit terhadap dokumen resmi | ✅ lihat [§12](#12-audit-terhadap-dokumen-instalasi-resmi) |
| Ganti password `admin` & `pbinstrument` | 🔴 **belum — masih default pabrik** |
| Jadwal backup database SMRT Link | 🔴 belum |
| Autostart saat boot | 🔴 belum |
| Instrumen Vega tersambung | 🔴 belum |
| Backup VM (`vzdump`) terjadwal | 🔴 belum |

---

## 2. Topologi

```
                              ☁ INTERNET
                                   │
                        ONT Huawei HG8245  192.168.18.1
                                   │
                        Zyxel MGS3520-28FX  e0/0/3
                                   │  1 GbE
                        PROXMOX-2U host  192.168.18.190
                                   │  nic0 ── vmbr0
   ╔═══════════════════════════════╧════════════════════════════════════╗
   ║                 VM 101  —  hostname: smrtlink                      ║
   ║           32 vCPU · 64 GB RAM · Ubuntu 24.04.4 LTS                 ║
   ║                                                                    ║
   ║   enp6s18 ── vmbr0 ── 192.168.18.60/24   gw .18.1  dns .18.1       ║
   ║        └─► internet · UI SMRT Link · akses HPC-GPU & T4-Storage    ║
   ║                                                                    ║
   ║   enp6s19 ── vmbr1 ── 192.168.50.1/24    ◄── GATEWAY VEGA          ║
   ║        └─► NAT keluar · isolasi ke arah LAN & BMC                  ║
   ║                                                                    ║
   ║   /            1000 GiB SSD (nvme-scratch) → OS + SMRT Link + DB   ║
   ║   /data/smrtlink  7,8 TiB HDD (vm-hdd)     → data run & jobs_root  ║
   ╚═══════════════════════════════╤════════════════════════════════════╝
                                   │
                        PROXMOX-2U nic1 ── vmbr1   ⚠️ host tanpa IP
                                   │
                        [media converter] ──FO── [media converter]
                                   │
                        PacBio Vega  192.168.50.10/24  gw 192.168.50.1
```

> **Media converter bersifat Layer 1 — transparan.** Ia tidak mengubah apa pun
> soal IP, routing, atau NAT. Bagi jaringan, rangkaian RJ45→FO→RJ45 itu identik
> dengan kabel LAN panjang. Konfigurasi di dokumen ini berlaku sama persis.

### 2.1 Alur internet Vega (terverifikasi jalan)

```
Vega 192.168.50.10  ──gw 192.168.50.1──►  enp6s19
                                              │ ip_forward = 1
                                              ▼
                                          enp6s18 ──masquerade──► 192.168.18.60
                                                                        │
                                                              ONT 192.168.18.1 ──► internet
```

> **ONT tidak perlu route apa pun ke `192.168.50.0/24`.** Karena memakai
> *masquerade*, seluruh paket Vega keluar beralamat asal `192.168.18.60`.

---

## 3. Spesifikasi VM

| Field | Nilai |
|---|---|
| **VMID** | `101` |
| **Nama di PVE** | `ubuntu24-desktop` |
| **Hostname OS** | **`smrtlink`** *(diubah dari `vega-Standard-PC-Q35-ICH9-2009`)* |
| **Tags** | `desktop`, `ubuntu`, `vega` |
| **OS** | **Ubuntu 24.04.4 LTS**, kernel `6.17.0-14-generic` |
| **vCPU** | **32** (`sockets 1` × `cores 32`), `cpu: host` |
| **RAM** | **64 GiB**, ballooning **off** |
| **BIOS** | OVMF (UEFI), Secure Boot off, `machine q35` |
| **SCSI** | `virtio-scsi-single` |
| **Guest agent** | ✅ aktif — dipakai untuk administrasi dari host tanpa SSH |

### 3.1 Disk

| Disk | Storage PVE | Ukuran | Mount | Peruntukan |
|---|---|---|---|---|
| `scsi0` | `nvme-scratch` | 1000 GiB | `/` (`/dev/sda2`, 983 G) | OS + SMRT Link + database |
| `scsi1` | **`vm-hdd`** | 7,81 TiB | **`/data/smrtlink`** (`/dev/sdb`, ext4) | Data run & `jobs_root` |
| `efidisk0` | `nvme-scratch` | 1 MiB | — | Variabel UEFI |

`/etc/fstab` — memakai **UUID**, bukan `/dev/sdX`, dan `nofail` agar boot tidak
tertahan bila disk belum tersedia:

```
UUID=9691cdad-56b0-44d3-bd0b-d3e8f1ab0775 /data/smrtlink ext4 defaults,noatime,nofail 0 2
```

> Sebelumnya disk ini ter-mount di `/media/vega/Storage-Vega` lewat automount
> GNOME — **tidak permanen** dan bergantung sesi desktop. Sudah dipindahkan.

---

## 4. Jaringan

| Interface | MAC | Bridge | Alamat | Fungsi |
|---|---|---|---|---|
| `enp6s18` | `BC:24:11:FD:2A:12` | `vmbr0` | **`192.168.18.60/24`** | LAN, internet, UI, akses HPC |
| `enp6s19` | `BC:24:11:0E:E2:7A` | **`vmbr1`** | **`192.168.50.1/24`** | Gateway segmen Vega |

| Field | Nilai |
|---|---|
| Default route | `via 192.168.18.1 dev enp6s18` — **hanya satu** |
| DNS | `192.168.18.1` (ONT) |
| `ip_forward` | `1` (`/etc/sysctl.d/99-vega.conf`) |
| Pengelola jaringan | **NetworkManager** (`nmcli`), koneksi bernama `lan` & `vega` |

> **Ubuntu Desktop memakai NetworkManager, bukan systemd-networkd.** Menulis
> netplan biasa akan berebut dengan NM. Konfigurasi di sini dibuat lewat `nmcli`.
> Koneksi `vega` diberi `ipv4.never-default yes` agar tidak memasang default
> route kedua.

### 4.1 Firewall — `nftables` (aktif, `enabled`)

```nft
table inet vega {
  chain input   { type filter hook input priority 0; policy accept; }
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related counter accept
    iifname "enp6s19" ip daddr 192.168.18.1 udp dport 53 counter accept  # izin-DNS-ONT
    iifname "enp6s19" ip daddr 192.168.18.1 tcp dport 53 counter accept  # izin-DNS-ONT-tcp
    iifname "enp6s19" ip daddr 192.168.18.0/24 counter drop              # blok-LAN-server-BMC
    iifname "enp6s19" ip daddr 192.168.30.0/24 counter drop              # blok-jalur-data
    iifname "enp6s19" ip daddr 192.168.0.0/22  counter drop              # blok-LAN-kantor
    iifname "enp6s19" oifname "enp6s18" counter accept                   # izin-internet
  }
}
table ip vega_nat {
  chain postrouting {
    type nat hook postrouting priority 100;
    ip saddr 192.168.50.0/24 oifname "enp6s18" counter masquerade
  }
}
```

**Terverifikasi jalan** — counter pada 2026-09-02 12:05 WIB:

| Aturan | Paket | Arti |
|---|---|---|
| `izin-DNS-ONT` | 43 | Resolusi nama dari segmen Vega berhasil |
| `izin-internet` | 313 | Trafik keluar diteruskan |
| `masquerade` | 225 | NAT diterapkan |
| `blok-*` | 0 | Tidak ada percobaan ke jaringan internal sejak counter direset |

> 🔴 **Urutan aturan menentukan.** Baris `izin-DNS-ONT` **wajib di atas**
> `blok-LAN-server-BMC`. Sempat terjadi: DNS Vega diarahkan ke `192.168.18.1`
> yang justru berada di dalam rentang yang diblokir, sehingga `ping 1.1.1.1`
> jalan tapi semua nama domain mati — terasa seperti "tidak ada internet".
>
> Lubang yang dibuka **sesempit mungkin**: satu alamat (`192.168.18.1`), satu
> port (53). Seluruh `192.168.18.0/24` selebihnya — termasuk **ketiga BMC** —
> tetap tertutup dari segmen Vega.

---

## 5. Yang Sudah Dipasang & Dikonfigurasi

### 5.1 Paket

| Paket | Versi | Alasan |
|---|---|---|
| `qemu-guest-agent` | `1:8.2.2+ds-0ubuntu1.18` | Administrasi dari host tanpa SSH; **`fs-freeze` saat `vzdump`** agar backup konsisten |
| `openssh-server` | `1:9.6p1-3ubuntu13.18` | Akses SSH ke `192.168.18.60` |
| `nftables` | `1.0.9-1ubuntu0.1` | NAT + isolasi segmen Vega |

### 5.2 Akun

| User | UID | Grup | Peran |
|---|---|---|---|
| `vega` | 1000 | `vega` | Akun desktop, dibuat saat instalasi OS |
| **`smrtanalysis`** | 1001 | `smrtanalysis`, `sudo` | **`$SMRT_USER`** — akun instalasi & layanan SMRT Link |

> Dokumen PacBio (hlm. 6 & 28) melarang install atau menjalankan SMRT Link
> sebagai `root`, dan mensyaratkan install dilakukan oleh **user yang sama**
> dengan yang menjalankan layanannya.

### 5.3 Batas sumber daya

`/etc/security/limits.d/99-smrtlink.conf` — dokumen mensyaratkan `nofile` dan
`nproc` **minimal 8192** (hlm. 7). Bawaan Ubuntu hanya `nofile=1024`.

```
smrtanalysis soft nofile 8192      # terverifikasi: nofile=8192 nproc=8192
smrtanalysis hard nofile 65536
smrtanalysis soft nproc  8192
smrtanalysis hard nproc  65536
```

### 5.4 Direktori

| Path | Pemilik | Lokasi fisik | Peran menurut dokumen |
|---|---|---|---|
| `/opt/pacbio/smrtlink` | — | SSD | **`$SMRT_ROOT`** — ⚠️ **sengaja belum dibuat**, installer menolak jika sudah ada (hlm. 9) |
| `/data/smrtlink/jobs_root` | `smrtanalysis` | HDD 7,8 T | `jobs_root` — keluaran analisis |
| `/opt/pacbio/db_datadir` | `smrtanalysis` | SSD | `db_datadir` — **wajib lokal, bukan NFS** (hlm. 7) |
| `/opt/pacbio/tmp_dir` | `smrtanalysis` | SSD | `tmp_dir` — **wajib lokal, bukan NFS** (hlm. 7) |
| `/opt/pacbio/installer` | `smrtanalysis` | SSD | Tempat menaruh berkas `.run` |

### 5.5 Sistem

| Item | Nilai | Syarat dokumen |
|---|---|---|
| Hostname | `smrtlink` (`hostname -f` = `smrtlink`) | ✅ SMRT Link **tidak tahan perubahan hostname** (hlm. 7) — sudah final sebelum install |
| `/etc/hosts` | `127.0.1.1 smrtlink` + `192.168.18.60 smrtlink` | ✅ konsisten |
| Locale | `en_US.UTF-8` | ✅ diwajibkan (hlm. 7) |
| NTP | `systemd-timesyncd` aktif, jam tersinkron, TZ `Asia/Jakarta` | ✅ sangat dianjurkan (hlm. 7) |
| Service `enabled` | `ssh`, `nftables`, `systemd-timesyncd` | ✅ bertahan setelah reboot |

### 5.6 SMRT Link — terinstall 2026-09-02

| Field | Nilai |
|---|---|
| **Versi** | **`smrtlink-release_26.2.0.292923`** |
| **Installer** | `smrtlink-release_26.2.0.292923_linux_x86-64_libc-2.17_anydistro.run` (1,33 GB) |
| **`$SMRT_ROOT`** | `/opt/pacbio/smrtlink` — **4,3 GB** terpakai |
| **`$SMRT_USER`** | `smrtanalysis` |
| **`dnsName` terdaftar** | `192.168.18.60` |
| **UI & REST API** | **`https://192.168.18.60:8243`** |
| **Port mendengarkan** | `8243` di `0.0.0.0` (UI/API) · `9091` di localhost (services) · `9095`/`9096` PostgreSQL internal |
| **Keycloak admin (`9443`)** | ⚪ **nonaktif** — sesuai bawaan v26.2, biarkan begitu |
| **JMS** | `NONE` (lihat §7) |
| **`nworkers` / `nproc` / `maxchunks`** | `4` / `12` / `1` — rekomendasi resmi single node |

Symlink `userdata` — terverifikasi mengarah ke lokasi yang direncanakan:

```
db_datadir -> /opt/pacbio/db_datadir      (SSD lokal)
jobs_root  -> /data/smrtlink/jobs_root    (HDD 7,8 T)
tmp_dir    -> /opt/pacbio/tmp_dir         (SSD lokal)
```

**Perintah instalasi yang dipakai** (mode `--batch`, non-interaktif):

```bash
su - smrtanalysis          # login shell, supaya ulimit 8192 berlaku
/opt/pacbio/installer/smrtlink-release_26.2.0.292923_*.run   --rootdir   /opt/pacbio/smrtlink   --batch   --jobsroot  /data/smrtlink/jobs_root   --dbdatadir /opt/pacbio/db_datadir   --tmpdir    /opt/pacbio/tmp_dir   --jmstype   NONE   --nworkers  4   --nproc     12   --maxchunks 1
```

> ⚠️ **Installer membutuhkan `curl`** yang tidak ada di Ubuntu Desktop bawaan.
> Percobaan pertama gagal dengan `Error! Cannot find 'curl'` **setelah** tarball
> 1,3 GB terekstrak. Perbaikannya: `apt install curl`, lalu ulangi dengan
> **`--no-extract`** agar tidak mengekstrak ulang (dokumen hlm. 9).
>
> `curl` dan `wget` kini sudah terpasang.

> **Snapshot `pre-smrtlink-install`** dibuat sebelum instalasi. Guest agent
> melakukan `fs-freeze`/`thaw` sehingga snapshot-nya konsisten.
> ```bash
> qm listsnapshot 101
> qm rollback 101 pre-smrtlink-install   # kalau perlu mengulang dari nol
> ```

### 5.7 Yang **belum** dipasang

| Komponen | Status | Catatan |
|---|---|---|
| Google Chrome | ⚪ belum | Diwajibkan untuk UI (hlm. 5). Tidak perlu di VM kalau diakses dari laptop |
| Singularity | ⚪ belum | Hanya untuk Variant Calling / Target Enrichment — **dan keduanya butuh JMS** |
| SLURM (`sbatch`) | ⚪ belum | Lihat §7 |

## 6. Kesesuaian dengan Syarat SMRT Link v26.2

| Komponen | Syarat *single node* (hlm. 6) | VM 101 | |
|---|---|---|---|
| OS | Rocky 9/10, **Ubuntu 22.04 & 24.04** | Ubuntu 24.04.4 LTS | ✅ |
| CPU | 16 core | **32 vCPU** | ✅ |
| RAM | 64 GB | **64 GB** | ✅ |
| Local storage | 1 TB SSD | 1000 GiB (983 G usable) | ✅ |
| Analysis storage | ~2× data SMRT Cell | **7,8 TiB** | ✅ |

> ✅ **Ubuntu 24.04 resmi didukung.** Kekhawatiran pada revisi dokumen ini
> sebelumnya (temuan `KI-V07`) **tidak terbukti** — dokumen v26.2 halaman 5
> mencantumkan Ubuntu 24.04 dalam daftar OS yang didukung. Tidak perlu install ulang.

> **Kapasitas Vega:** dokumen memperkirakan ± **6 TB/tahun** (±30 GB per SMRT Cell,
> 200 cell/tahun). Dengan analysis storage menggandakan kebutuhan, disk 7,8 TiB
> cukup untuk sekitar **satu tahun** operasi. Rencanakan ekspansi atau
> pemindahan arsip ke `zfs-storage` sebelum penuh.

---

## 7. Job Management System — pilih `NONE`

Dokumen mensyaratkan **SLURM** untuk menjalankan workflow SMRT Analysis
terdistribusi. `slurmctld` di `192.168.18.194` **tidak merespons**, jadi tidak ada
JMS yang bisa disambungkan saat ini.

Tanpa JMS, sistem berjalan **non-distributed** — semua job dieksekusi lokal di
VM ini (32 vCPU / 64 GB), **bukan** di A100 milik `HPC-GPU`.

Batasan yang mengikuti (hlm. 6):

| Workflow | Batas pada single node |
|---|---|
| HiFi Mapping | 150 Gb |
| Target Enrichment | hanya dengan variant calling **nonaktif** |
| **Variant Calling** | **tidak didukung** |
| Iso-Seq Analysis | 20 juta read |
| Single-Cell Iso-Seq | 60 juta read |
| Microbial Genome, PureTarget, Read Segmentation | tanpa batas |

> Konfigurasi JMS bisa diubah **tanpa install ulang** begitu SLURM hidup kembali.

---

## 8. Port & Protokol

Dari tabel resmi dokumen (hlm. 26), disaring untuk topologi di sini:

| Sumber | Tujuan | Port | Status di konfigurasi kita |
|---|---|---|---|
| **Vega** | SMRT Link (`192.168.50.1`) | **`8243/tcp`** | ✅ satu segmen — tidak lewat chain `forward` |
| **SMRT Link** | Vega (`192.168.50.10`) | **`9243/tcp`** | ✅ keluar dari VM, tidak difilter |
| Vega | NTP eksternal | `123/udp` | ✅ lewat NAT |
| Vega | Nameserver | `53/udp,tcp` | ✅ diizinkan khusus ke `192.168.18.1` |
| Vega | SecureLink / PacBio Insight | `22`, `80`, `443` | ✅ lewat NAT |
| Laptop/desktop | SMRT Link (`192.168.18.60`) | **`8243/tcp`** | ✅ dari LAN |
| Laptop/desktop | Keycloak admin | `9443/tcp` | ⚪ **nonaktif secara bawaan** — biarkan begitu |
| SMRT Link | PacBio Event & Update server | `443/tcp` | ✅ lewat gateway |

> 🔴 **Alamat SMRT Link untuk instrumen: gunakan IP `192.168.50.1`, bukan hostname.**
> Vega berada di segmen `192.168.50.0/24` dan DNS-nya mengarah ke ONT yang tidak
> mengenal nama `smrtlink`. Mengisi hostname akan membuat instrumen gagal menemukannya.

---

## 9. Langkah Instalasi SMRT Link

**1. Unduh & salin installer** *(butuh akun PacBio — tidak tersedia publik)*

```bash
scp smrtlink_26.2.*.run vega@192.168.18.60:/opt/pacbio/installer/
```

**2. Install sebagai `smrtanalysis`**

```bash
ssh vega@192.168.18.60
sudo -iu smrtanalysis
cd /opt/pacbio/installer
chmod +x smrtlink_26.2.*.run
./smrtlink_26.2.*.run --rootdir /opt/pacbio/smrtlink
```

**3. Jawaban prompt** — sesuai layout yang sudah disiapkan di §5.4:

| Prompt | Isi |
|---|---|
| `jobs_root` | `/data/smrtlink/jobs_root` |
| `db_datadir` | `/opt/pacbio/db_datadir` |
| `tmp_dir` | `/opt/pacbio/tmp_dir` |
| JMS type | **`NONE`** (lihat §7) |
| `nproc` | **12** |
| `nchunks` | **1** |
| `nworkers` | **4** |

*Tiga angka terakhir adalah rekomendasi resmi untuk single node (hlm. 9).*

**4. Jalankan & uji**

```bash
/opt/pacbio/smrtlink/admin/bin/services-start
/opt/pacbio/smrtlink/admin/bin/run-sat-services      # Site Acceptance Test
```

**5. Akses UI:** `https://192.168.18.60:8243/sl/home` dengan **Google Chrome**,
terima peringatan sertifikat self-signed.

**6. Setelah install — wajib**

```bash
# Backup database TIDAK otomatis (hlm. 28). Buat jadwal mingguan:
/opt/pacbio/smrtlink/admin/bin/generate-cron-backup

# Ganti password bawaan admin & pbinstrument (hlm. 11):
/opt/pacbio/smrtlink/admin/bin/set-keycloak-creds --user admin \
    --password 'BARU' --adminpassword 'LAMA'

# Autostart saat boot (hlm. 29):
# lihat /opt/pacbio/smrtlink/admin/template/smrtlink.service.tmpl
```

---

## 10. Ketergantungan & Risiko

| ID | Temuan | Dampak | Prioritas |
|---|---|---|---|
| `KI-V01` | **`zfs-storage` pakai LUKS `none`+`noauto`** — 11 disk butuh passphrase manual saat boot | `scsi1` (`/data/smrtlink`) ada di pool ini, jadi **VM tidak bisa start setelah reboot** sebelum pool dibuka manual | 🔴 **Kritis** |
| `KI-V02` | **Belum ada job backup** untuk VM ini | Target `pve-backup` (20 TiB, raidz2) sudah ada tapi belum dijadwalkan | 🔴 **Kritis** |
| `KI-V03` | **`scsi0` dan `rpool` berbagi satu NVMe fisik** (Lexar NM790 konsumer, tanpa redundansi) | NVMe mati = OS hypervisor **dan** OS VM hilang bersamaan | 🔴 **Kritis** |
| `KI-V04` | **RAM overcommit** — VM 8+64+64 = 136 GiB, `zfs_arc_max` 200 GiB, RAM host 251 GiB | ARC menyusut sendiri, margin tipis | 🟠 Tinggi |
| `KI-V05` | **`slurmctld` mati** → JMS `NONE` | Variant Calling tidak didukung; job tidak memakai A100 | 🟠 Tinggi |
| `KI-V06` | **Jalur ke HPC hanya 1 GbE** | ± 3 jam per TB | 🟠 Tinggi |
| ~~`KI-V07`~~ | ~~Dukungan Ubuntu 24.04 belum diverifikasi~~ | ✅ **Selesai** — dokumen v26.2 hlm. 5 mencantumkan Ubuntu 24.04 sebagai OS yang didukung | 🟢 Selesai |
| `KI-V08` | **`192.168.18.60` belum dipastikan di luar rentang DHCP ONT** | Potensi bentrok alamat | 🟡 Sedang |
| `KI-V09` | **Firewall Proxmox tidak aktif** — `firewall=1` di `net0`/`net1` tidak berefek | Isolasi bergantung sepenuhnya pada `nftables` di dalam VM | 🟡 Sedang |
| `KI-V10` | **`input` chain `policy accept`** | Segmen Vega bisa menjangkau **semua** layanan VM, termasuk SSH. Wajar untuk instrumen lab, tapi bisa diperketat ke `8243` saja | 🟡 Sedang |
| `KI-V11` | **Kapasitas data ± 1 tahun** (7,8 TiB vs ±6 TB/tahun + analisis) | Perlu rencana ekspansi atau rotasi arsip ke `zfs-storage` | 🟡 Sedang |

### 10.1 Menurunkan `zfs_arc_max` (`KI-V04`)

```bash
# di PROXMOX-2U
echo "options zfs zfs_arc_max=103079215104" > /etc/modprobe.d/zfs.conf   # 96 GiB
update-initramfs -u    # berlaku setelah reboot
```

### 10.2 Menjadwalkan backup (`KI-V02`)

```bash
# di PROXMOX-2U
vzdump 101 --storage pve-backup --mode snapshot --compress zstd
# jadwal: Datacenter -> Backup -> Add (storage=pve-backup, mode=snapshot)
```

---

## 11. Checklist

- [x] Dataset `zfs-storage/vm-disks` (quota 10 TiB) + storage PVE `vm-hdd`
- [x] Dataset `zfs-storage/backup` (quota 20 TiB) + storage PVE `pve-backup`
- [x] Bridge `vmbr1` di `nic1` (host tanpa IP)
- [x] VM 101 — 32 vCPU, 64 GB, SSD 1000 GiB, HDD 7,81 TiB, 2 NIC
- [x] Ubuntu 24.04.4 LTS terinstall
- [x] `qemu-guest-agent`, `openssh-server`, `nftables` terpasang & `enabled`
- [x] Hostname `smrtlink` + `/etc/hosts` konsisten
- [x] IP statis `192.168.18.60` & `192.168.50.1` via `nmcli`
- [x] `ip_forward` + NAT + isolasi ke BMC — **terverifikasi dari counter**
- [x] Disk 7,8 TiB ter-mount permanen di `/data/smrtlink` (UUID + `nofail`)
- [x] User `smrtanalysis`, ulimit 8192, direktori SMRT Link
- [x] Unduh installer SMRT Link v26.2 dari akun PacBio
- [x] Snapshot `pre-smrtlink-install` sebelum instalasi
- [x] Pasang `curl` (prasyarat installer yang tidak ada di Ubuntu Desktop)
- [x] **Install SMRT Link v26.2.0.292923** — `SMRT Link Install successful`
- [x] **`services-start`** — `SMRT Link status: ok`, UI di `https://192.168.18.60:8243`
- [x] Verifikasi symlink `jobs_root` / `db_datadir` / `tmp_dir` mengarah benar
- [x] Verifikasi UI terjangkau dari LAN (HTTP 200 dari `PROXMOX-2U`)
- [x] Jalankan `run-sat-services` — **LULUS**, job HiFi Mapping `Job successful` 136 detik, hasil di `jobs_root/0000/0000000/0000000027`
- [ ] **Ganti password `admin` & `pbinstrument`** — masih default pabrik ⚠️
- [ ] Jadwalkan backup database (`generate-cron-backup`)
- [ ] Aktifkan autostart saat boot (`admin/template/smrtlink.service.tmpl`)
- [ ] Jadwalkan `vzdump` VM (`KI-V02`)
- [ ] Turunkan `zfs_arc_max` (`KI-V04`)
- [ ] Pasang media converter + kabel FO ke Vega
- [ ] Set Vega: `192.168.50.10/24`, gw `192.168.50.1`, DNS `192.168.18.1`, SMRT Link `192.168.50.1:8243`
- [ ] **Uji isolasi** — dari Vega, `ping 192.168.18.13` **harus gagal**

### 11.1 Uji sebelum Vega datang

Colok laptop ke port `nic1` proxmox:

```bash
ip addr add 192.168.50.99/24 dev <iface>      # .10 dicadangkan untuk Vega
ip route add default via 192.168.50.1

ping -c2 192.168.50.1      # sampai ke VM
ping -c2 1.1.1.1           # NAT jalan
ping -c2 google.com        # DNS jalan
ping -c2 192.168.18.13     # HARUS GAGAL — ujian isolasi
```

Verifikasi objektif dari sisi VM — angka, bukan tebakan:

```bash
nft list ruleset | grep -E 'counter|comment'
```

---

## 12. Audit terhadap Dokumen Instalasi Resmi

Ditelusuri langkah demi langkah terhadap *SMRT Link software installation guide
(v26.2)*, PN 103-891-700 Ver. 01. Diverifikasi 2026-09-02.

### 12.1 Syarat sistem (hlm. 5–7)

| # | Syarat | Halaman | Status |
|---|---|---|---|
| 1 | OS didukung (Rocky 9/10, Ubuntu 22.04/24.04) | 5 | ✅ Ubuntu 24.04.4 LTS |
| 2 | Host Linux 64-bit, `libc` ≥ 2.17 | 5 | ✅ |
| 3 | Google Chrome untuk UI | 5 | ⚪ tidak di VM — diakses dari laptop |
| 4 | JMS (SLURM) bila menjalankan SMRT Analysis | 5 | ⚠️ **`NONE`** — `slurmctld` mati, lihat §7 |
| 5 | Singularity ≥ 3.10.5 untuk Variant Calling / Target Enrichment | 5 | ⚪ belum — **butuh JMS lebih dulu**, jadi belum ada gunanya |
| 6 | CPU 16 core / RAM 64 GB / 1 TB SSD (single node) | 6 | ✅ 32 vCPU / 64 GB / 1000 GiB |
| 7 | Analysis storage ~2× data SMRT Cell | 6 | ✅ 7,8 TiB |
| 8 | Install oleh **non-root** `$SMRT_USER` yang sama dengan pengelola layanan | 6 | ✅ `smrtanalysis` |
| 9 | `$SMRT_USER` punya izin penuh rekursif di install dir, `jobs_root`, `db_datadir`, `tmp_dir` | 6 | ✅ **diverifikasi — tidak ada berkas milik user lain** |
| 10 | Tidak ada layanan lain yang memakai port SMRT Link | 6 | ✅ |
| 11 | Jam tersinkron NTP | 7 | ✅ `systemd-timesyncd`, TZ `Asia/Jakarta` |
| 12 | `nofile` & `nproc` soft ≥ 8192 | 7 | ✅ 8192 lewat `limits.d` |
| 13 | Locale `en_US.UTF-8` | 7 | ✅ |
| 14 | Hostname stabil & terjangkau (SMRT Link tidak tahan perubahan hostname) | 7 | ✅ `smrtlink` difinalkan **sebelum** install |
| 15 | Port `8243` terjangkau user & instrumen; SMRT Link bisa ke `9243` instrumen | 7 | ✅ `8243` `LISTEN 0.0.0.0`; jalur ke Vega terbuka |
| 16 | `db_datadir` & `tmp_dir` **lokal, bukan NFS** | 7 | ✅ keduanya di SSD lokal |

### 12.2 Langkah instalasi (hlm. 8–9)

| # | Langkah | Status |
|---|---|---|
| 1 | Unduh & ekstrak installer | ✅ `smrtlink-release_26.2.0.292923` |
| 2 | Login sebagai `$SMRT_USER` | ✅ `su - smrtanalysis` (login shell, agar `ulimit` berlaku) |
| 3 | Install `--rootdir $SMRT_ROOT` | ✅ **`SMRT Link Install successful`** |
| 3b | Setelan single node `nproc=12, nchunks=1, nworkers=4` | ✅ dipakai persis |
| 5 | `services-start` | ✅ **`SMRT Link status: ok`** |
| 6 | `run-sat-services` (Site Acceptance Test) | ✅ **LULUS** — job HiFi Mapping `Job successful`, 136 detik |
| 7 | *(Opsional)* Bersihkan cache browser | ⚪ sisi klien |
| 8 | *(Opsional)* Konfigurasi LDAP / user lokal | ⚪ **belum** — lihat §12.4 |
| 9 | *(Opsional)* Sertifikat TLS dari CA | ⚪ **belum** — masih `pb-smrtlink-default.crt` self-signed |
| 10 | *(Opsional tapi dianjurkan)* **Ganti password `admin` & `pbinstrument`** | 🔴 **BELUM — masih default pabrik** |

### 12.3 Appendix — yang sering terlewat

| Item | Halaman | Status |
|---|---|---|
| **Backup database terjadwal** (`generate-cron-backup`) | 28 | 🔴 **BELUM** — tidak ada entri cron. Dokumen: *"strongly recommend"* |
| **Autostart saat boot** (`smrtlink.service.tmpl`) | 29 | 🔴 **BELUM** — tidak ada unit systemd |
| Usage tracking (`accept-user-agreement`) | 29 | ⚠️ **ter-set `true` tanpa disengaja** pada 2026-09-02 05:24 UTC — lihat catatan di bawah |
| Keycloak admin console (`9443`) nonaktif | 12 | ✅ nonaktif, sesuai anjuran keamanan |
| Jangan jalankan sebagai `root` | 28 | ✅ |
| Server di jaringan tepercaya, di belakang firewall | 28 | ✅ LAN internal, tidak terekspos internet |

> ⚠️ **Catatan `accept-user-agreement`.** Perintah ini dijalankan untuk *memeriksa*
> status, tetapi dokumen hlm. 29 menyatakan: bila dijalankan **tanpa argumen** dan
> setelannya belum pernah diisi, ia otomatis mengeset `install-metrics` dan
> `job-metrics` menjadi `true` **dan langsung memberi tahu PacBio**. Jadi perintah
> itu menulis, bukan membaca.
>
> Untuk mematikan:
> ```bash
> /opt/pacbio/smrtlink/admin/bin/accept-user-agreement --install-metrics false --job-metrics false
> ```
> Dokumen sendiri menganjurkan menerimanya karena mempermudah troubleshooting
> oleh PacBio. Membiarkan atau mematikan sama-sama sah — ini keputusan pemilik sistem.

### 12.4 Yang belum dikerjakan — berurutan

| # | Pekerjaan | Kenapa penting | Prioritas |
|---|---|---|---|
| 1 | **Ganti password `admin` & `pbinstrument`** | Dokumen hlm. 11: nilainya **sama di semua instalasi SMRT Link**. `pbinstrument` dipakai Vega untuk bicara ke SMRT Link | 🔴 **Kritis** |
| 2 | **Jadwalkan backup database** | Hlm. 28: SMRT Link **tidak** backup berkala. Gagal backup = seluruh record (user, Data Set, analisis, barcode) hilang bila filesystem bermasalah | 🔴 **Kritis** |
| 3 | **Autostart saat boot** | Tanpa ini, setelah reboot layanan harus dinyalakan manual | 🟠 Tinggi |
| 4 | Tentukan sikap soal usage tracking | Saat ini `true` tanpa keputusan sadar | 🟠 Tinggi |
| 5 | Tambah user SMRT Link + peran (LDAP atau lokal via Keycloak) | Hlm. 14–18. Sekarang hanya akun `admin` bawaan | 🟡 Sedang |
| 6 | Sertifikat TLS dari CA | Hlm. 19. Tanpa ini setiap user harus menerima peringatan browser | 🟡 Sedang |
| 7 | Pasang Chrome di VM *(bila UI diakses dari desktop VM)* | Hlm. 5 mensyaratkan Chrome | 🟢 Rendah |
| 8 | SLURM + Singularity | Membuka Variant Calling & pemakaian A100 | 🟢 Rendah *(tergantung `slurmctld`)* |

**Perintah untuk tiga yang teratas:**

```bash
sudo -iu smrtanalysis

# 1. ganti password bawaan (hlm. 11)
/opt/pacbio/smrtlink/admin/bin/set-keycloak-creds --user admin     --password 'PASSWORD-BARU' --adminpassword 'admin'
/opt/pacbio/smrtlink/smrtcmds/developer/bin/pbservice-instrument     set-smrtlink-password --user admin --ask-pass
# verifikasi:
/opt/pacbio/smrtlink/smrtcmds/bin/pbservice status --host localhost --user admin --ask-pass

# 2. jadwal backup database mingguan (hlm. 28) - ulangi tiap upgrade
/opt/pacbio/smrtlink/admin/bin/generate-cron-backup

# 3. autostart saat boot (hlm. 29)
cat /opt/pacbio/smrtlink/admin/template/smrtlink.service.tmpl
# sesuaikan lalu pasang sebagai unit systemd
```

---

## 12A. Jebakan Operasional yang Sudah Terbukti

### 12A.1 🔴 `services-status` memberi hasil PALSU bila salah akun

| Akun | Hasil |
|---|---|
| **`smrtanalysis`** | ✅ `SMRT Link status: ok` — **benar** |
| `vega` | 🔴 **`SMRT Link status: Not Running`** — **PALSU** |
| `root` | ✅ `ok`, tapi jangan dibiasakan |

Dijalankan sebagai `vega`, skrip gagal membaca berkas internal milik
`smrtanalysis` (`Permission denied` pada `get-status`) lalu menyimpulkan layanan
tidak berjalan — padahal hidup normal.

> **Ini jenis kesalahan yang bikin panik tak perlu.** Bila teknisi atau siapa pun
> menjalankannya dari akun yang salah, mereka akan mengira instalasi gagal.
> **Selalu `sudo -iu smrtanalysis` lebih dulu.**

### 12A.2 `$SMRT_ROOT` bukan variabel bawaan

`$SMRT_ROOT` hanyalah notasi di dokumen PacBio. Menyalin perintah dokumen
mentah-mentah menghasilkan `/admin/bin/services-status` → *command not found*.

Sejak 2026-09-02 sudah didefinisikan di `~/.profile` milik `smrtanalysis`:

```bash
export SMRT_ROOT=/opt/pacbio/smrtlink
export PATH="$SMRT_ROOT/admin/bin:$SMRT_ROOT/smrtcmds/bin:$PATH"
```

Sehingga `services-status`, `pbservice`, `generate-cron-backup` bisa diketik pendek.

> ⚠️ Ditaruh di **`.profile`**, bukan `.bashrc`. `.bashrc` bawaan Ubuntu punya
> guard yang langsung `return` untuk shell non-interaktif, sehingga `export`
> di dalamnya tidak pernah terbaca oleh `su - user -c '...'`.
>
> Karena `.profile` hanya dibaca **login shell**, gunakan `sudo -iu` (dengan `-i`),
> bukan `sudo -u`.

### 12A.3 UI hanya melayani HTTPS

`http://...:8243` → **`400 Bad Request — The plain HTTP request was sent to
HTTPS port`**. Bukan kerusakan, cuma kurang `s`. Browser modern menyembunyikan
skema di address bar, jadi ketik `https://` eksplisit.

---

## 13. Administrasi dari Host Tanpa SSH

Karena `qemu-guest-agent` aktif, seluruh VM dapat dikelola dari `PROXMOX-2U`
**tanpa kredensial dan tanpa jaringan VM** — komunikasinya lewat virtio serial.
Ini juga jalur pemulihan bila konfigurasi jaringan VM rusak.

```bash
# di PROXMOX-2U
qm agent 101 ping
qm guest exec 101 --timeout 30 -- /bin/bash -c "ip -br addr; nft list ruleset"

# keluarannya JSON; untuk dibaca:
qm guest exec 101 -- /bin/bash -c "<perintah>" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin).get("out-data",""))'
```

---

## 14. Perintah Pengelolaan

```bash
qm start 101 / qm shutdown 101 / qm status 101
qm config 101
qm snapshot 101 pre-smrtlink-install       # sebelum install SMRT Link
qm listsnapshot 101

# konsol: https://192.168.18.190:8006 -> VM 101 -> Console
# ssh   : ssh vega@192.168.18.60
```

# Peta Jaringan & Hasil Discovery On-Premise

> **Terakhir Diperbarui:** 2026-09-02
> **Metode:** probe TCP dari laptop admin (`192.168.0.53`, lewat **Cloudflare Zero
> Trust / WARP**) ke `192.168.18.0/24`, dilengkapi probe dari **dalam** LAN server
> lewat `proxmox` (`192.168.18.190`), fingerprint TLS/HTTP, `ssh-keyscan`,
> `showmount -e`, tabel ARP, dan pembacaan `node_exporter` / `smartctl_exporter`
> di `T4-Storage`.
> **Cakupan:** server Linux + perangkat jaringan yang menopang jalur data.

> ⚠️ **Catatan metode — ICMP tidak bisa dipakai dari laptop admin.**
> Rute ke `192.168.18.0/24` melewati tunnel WARP (`192.0.2.1` via `100.96.0.4`),
> yang meneruskan **TCP tapi tidak ICMP**. Akibatnya `ping` selalu gagal padahal
> host hidup. **Gunakan probe TCP, bukan `ping`**, atau jalankan pemindaian dari
> `proxmox` yang berada langsung di segmen tersebut.

---

## 1. Segmen Jaringan

| Segmen | Fungsi | Keterangan |
|---|---|---|
| `192.168.0.0/22` | **LAN klien / kantor** | Laptop admin (`.0.53`), workstation, printer. Netmask `255.255.252.0` |
| `192.168.18.0/24` | **LAN server + IPMI** | Semua server dan seluruh BMC ada di sini — ⚠️ tidak dipisah VLAN |
| `192.168.30.0/24` | **Jalur data storage (SFP+)** | 10 GbE. Sekarang hanya `T4-Storage` & `HPC-GPU`; **`PROXMOX-2U` direncanakan menyusul** di `.30.4` (§2.2) |
| `100.64.0.0/10` | **Cloudflare WARP / Zero Trust** | Jalur akses admin ke LAN server; laptop `100.96.0.4` |

> ⚠️ **IPMI/BMC satu segmen dengan jaringan data** (`192.168.18.0/24`).
> Ketiga BMC (`.13`, `.119`, `.200`) terjangkau dari setiap host di LAN server —
> siapa pun yang masuk ke LAN punya jalan ke kendali setara akses fisik.
> Memisahkannya ke VLAN manajemen tersendiri ada di daftar tindak lanjut (§10).

---

## 2. Server yang Menyala & Sudah Didata

Tiga server bare-metal, seluruhnya aktif per 2026-09-02.

| Nama | Host IP | BMC / IPMI | Hostname OS | Peran | Dokumentasi |
|---|---|---|---|---|---|
| **T4-Storage** | `192.168.18.193` | **`192.168.18.200`** (Supermicro) | `t4-Super-Server` | Storage NFS/SMB + **server monitoring** | [storage-nodes/t4-storage.md](storage-nodes/t4-storage.md) |
| **HPC-GPU** | `192.168.18.178` | **`192.168.18.119`** (ASRock/AMI) | `HPC-GPU` | Compute 2× A100, Slurm `compute001` | [hpc-nodes/hpc-gpu.md](hpc-nodes/hpc-gpu.md) |
| **PROXMOX-2U** | `192.168.18.190` | **`192.168.18.13`** (Supermicro) | `proxmox.server` | Hypervisor PVE 9.2 + arsip ZFS 140 TB | [proxmox-nodes/proxmox.md](proxmox-nodes/proxmox.md) |

> **"PROXMOX-2U" adalah label fisik**; hostname OS-nya `proxmox.server`, dan nama
> file dokumennya mengikuti hostname sesuai konvensi repo. Begitu juga
> **"T4-Storage"** — hostname OS-nya `t4-Super-Server`.

### 2.1 Jalur data 10 GbE (`192.168.30.0/24`)

| Node | Interface | IP data | Speed | MTU | Status |
|---|---|---|---|---|---|
| `T4-Storage` | `enp65s0f0` (SFP+) | `192.168.30.2` | 10 Gb/s | ⚠️ *(belum terverifikasi)* | 🟢 terpasang |
| `HPC-GPU` | `enp1s0f0` (SFP+) | `192.168.30.3` | 10 Gb/s | 9000 | 🟢 terpasang |
| **`PROXMOX-2U`** | *(NIC belum ada)* | **`192.168.30.4`** | 10 Gb/s | 9000 | 🔵 **direncanakan** — lihat §2.2 |

Alamat cadangan di segmen ini: `192.168.30.5`–`.20` masih bebas.
Gateway `192.168.30.1` disebut di tabel routing `HPC-GPU` tapi **belum
terverifikasi ada wujudnya**.

**Keadaan sekarang:**

```
  T4-Storage                Zyxel Switch                HPC-GPU
 192.168.30.2  ──SFP+──►  192.168.18.250  ──SFP+──►  192.168.30.3
   (enp65s0f0)   10 GbE      (jalur data)    10 GbE    (enp1s0f0)
        │                                                   │
        │                  ✗ tidak tersambung               │
        │                  ke jalur 10 GbE                  │
        │                         ▲                         │
        │                         │                         │
        └──── LAN server 192.168.18.0/24 (1 GbE) ───────────┘
             .193              .190              .178
                         PROXMOX-2U
```

> ⚠️ **`PROXMOX-2U` tidak ikut di jalur 10 GbE.** Ia hanya punya uplink 1 GbE
> (`nic0` Broadcom BCM5720), padahal menyimpan arsip 140 TB. Setiap transfer
> arsip ke/dari proxmox berjalan di 1 Gb/s — **± 3 jam per TB**.

### 2.2 Rencana: `PROXMOX-2U` masuk ke jalur data sebagai ingress

[README §2.2](../README.md#22-arsitektur-target--proxmox-sebagai-ingress-data)
menetapkan `PROXMOX-2U` sebagai **titik masuk seluruh data**. Supaya itu masuk
akal, proxmox harus berada di jalur 10 GbE — bukan di 1 GbE.

**Target:**

```
                        PROXMOX-2U  (INGRESS)
                        192.168.30.4  ⭐ baru
                              │
                              │ 10 GbE SFP+ (MTU 9000)
                              ▼
                   ┌─────────────────────┐
                   │    Zyxel Switch     │
                   │   192.168.18.250    │
                   │   VLAN data 30      │
                   └──────┬───────┬──────┘
                   10 GbE │       │ 10 GbE
              ┌───────────┘       └───────────┐
              ▼                               ▼
        T4-Storage                        HPC-GPU
       192.168.30.2 ◄────NFS 10 GbE────► 192.168.30.3
```

**Kelayakan — sudah diverifikasi:**

| Syarat | Status | Bukti |
|---|---|---|
| Slot PCIe kosong di proxmox untuk NIC SFP+ | ✅ **Ada, 5 slot** | `dmidecode -t slot`: `CPU SLOT1/3/5` PCIe 4.0 **x16**, `CPU SLOT2/4` **x8**, semuanya `Available`. Slot 6 & 7 `In Use` |
| Alamat IP tersedia di `192.168.30.0/24` | ✅ Ada | Hanya `.2` dan `.3` terpakai |
| Port SFP+ kosong di switch Zyxel | ⚠️ **Belum diketahui** | Model switch belum terdata — butuh login atau label fisik |
| Jumbo frame diteruskan switch | ⚠️ **Belum diketahui** | Harus dipastikan, `HPC-GPU` sudah MTU 9000 |
| Kabel/transceiver SFP+ | ⚠️ Belum diketahui | Perlu dicocokkan dengan tipe port switch (DAC vs fiber) |

**Langkah penerapan:**

```bash
# 1. Setelah NIC terpasang, cek terdeteksi
lspci | grep -i ethernet
ip -br link

# 2. Tambahkan ke /etc/network/interfaces di proxmox
#    (ganti <ifname> dengan nama interface yang muncul)
#
#    auto <ifname>
#    iface <ifname> inet static
#        address 192.168.30.4/24
#        mtu 9000

# 3. Terapkan, lalu uji jumbo frame ke kedua node
ifreload -a
ping -M do -s 8972 -c4 192.168.30.2    # ke T4-Storage
ping -M do -s 8972 -c4 192.168.30.3    # ke HPC-GPU
```

> **Kalau `ping -M do -s 8972` gagal tapi `ping` biasa jalan**, berarti switch
> **tidak** meneruskan jumbo frame. Jangan dibiarkan — MTU tidak cocok membuat
> throughput anjlok diam-diam tanpa pesan error.

> ⚠️ **Jangan pindahkan beban ingress ke proxmox sebelum `backup-pool` dibereskan.**
> Pool itu sekarang **93–95% penuh di atas single disk tanpa redundansi**, dan
> belum ada job backup VM sama sekali. Lihat
> [`proxmox.md` §12](proxmox-nodes/proxmox.md#12-known-issues--risiko).

---

## 3. Koreksi Terhadap Discovery 2026-08-28

Pemindaian sebelumnya menghasilkan beberapa kesimpulan yang **terbukti keliru**.
Dicatat di sini agar kekeliruan yang sama tidak terulang.

| Host | Dugaan lama (2026-08-28) | Kenyataan (2026-09-02) | Cara memastikan |
|---|---|---|---|
| `192.168.18.200` | "Server web/aplikasi" — ⚠️ host key SSH berubah | **BMC Supermicro milik `T4-Storage`** | Sertifikat TLS `O=Super Micro Computer, CN=IPMI`; judul halaman `Supermicro BMC Login`; port `623` (IPMI RMCP) & `5900` (KVM) terbuka |
| `192.168.18.250` | "Appliance / printer" | **Switch Zyxel** — pembawa jalur SFP+ | `Server: WebServer`, redirect ke `/index.asp`, footer `ZyXEL Communications Corp.` |
| `192.168.18.193` | "Server storage, diduga sama dengan `192.168.30.2`" | ✅ **Dugaan benar** — ini `T4-Storage`, dual-homed `.18.193` + `.30.2` | `showmount -e` menampilkan `/bio-pool` + `/media/t4/*`; MAC `3c:ec:ef` (Supermicro) |
| `192.168.18.193:9090` | "Cockpit" | **Prometheus 2.52.0** | `/` redirect ke `/graph`; `/api/v1/status/buildinfo` |
| `192.168.18.113` | "Storage — tidak merespons" | **IP lama `T4-Storage`**, sudah pindah ke `.193` | Export `/media/t4/96-Storage` kini dilayani `.193`; seluruh job Prometheus masih menunjuk `.113` |
| *(host key `.200` berubah)* | "Mesin di-install ulang / IP dipakai perangkat lain" | **Bukan keduanya** — itu SSH milik BMC, bukan OS | `ssh-keyscan` → `SSH-2.0-OpenSSH_9.8`, hanya menawarkan kunci RSA |

> **Pelajaran metode:** menebak peran host dari port yang terbuka saja mudah
> menyesatkan. Sertifikat TLS, judul halaman, dan OUI MAC jauh lebih menentukan.
> Port `623` terbuka adalah penanda BMC yang hampir pasti.

---

## 4. BMC / IPMI

Bukan server terpisah — modul manajemen dari server di §2.

| IP | Milik | Tipe | Port terbuka | Catatan |
|---|---|---|---|---|
| `192.168.18.13` | `PROXMOX-2U` | Supermicro BMC (ASPEED), FW `1.05` | 22, 80, 443, 623 | ⚠️ **DHCP**, SNMP `public`, VLAN disabled. Sertifikat TLS 2024-09-04 → 2034 |
| `192.168.18.119` | `HPC-GPU` | ASRock Rack BMC (AMI MegaRAC) | 443, 623 | ⚠️ SNMP `AMI`, tanpa lockout brute-force. Sertifikat AMI 2020-11-18 → 2030 |
| `192.168.18.200` | **`T4-Storage`** | Supermicro BMC (ASPEED) | 22, 80, 443, 623, **5900** | 🔴 **kredensial bocor — wajib rotasi**, lihat [`t4-storage.md` `KI-T02`](storage-nodes/t4-storage.md#12-known-issues--risiko). Sertifikat TLS 2023-03-23 → 2033 |

> 🔴 **Ketiga BMC terbuka di LAN server tanpa segmentasi.** BMC memberi kendali
> setara akses fisik: power cycle, mount media virtual, konsol KVM. Memisahkannya
> ke VLAN manajemen adalah perbaikan keamanan dengan dampak terbesar per usaha
> di infrastruktur ini.

---

## 5. Perangkat Jaringan

### 5.1 Switch Zyxel — `192.168.18.250`

| Field | Nilai |
|---|---|
| **Peran** | **Switch pembawa jalur SFP+ 10 GbE** antara `T4-Storage` ↔ `HPC-GPU` |
| **IP Manajemen** | `192.168.18.250` |
| **Vendor** | **ZyXEL Communications Corp.** *(dari footer web configurator)* |
| **Model** | *(isi — tidak diumumkan sebelum login; baca dari label fisik)* |
| **Web UI** | `http://192.168.18.250/index.asp` — `Server: WebServer`, charset `gb2312` |
| **Port terbuka** | **`23` (Telnet)**, `80` (HTTP) |
| **HTTPS** | 🔴 **tidak tersedia** |
| **Firmware** | *(isi)* |
| **Kredensial** | simpan di password manager, entri `Switch / zyxel-192.168.18.250` |
| **Konfigurasi VLAN** | *(isi — penting: bagaimana `192.168.30.0/24` dipisah dari `.18`)* |

> 🔴 **Manajemen switch hanya lewat Telnet (23) dan HTTP (80) — keduanya
> plaintext.** Kredensial admin switch terkirim tanpa enkripsi dan bisa disadap
> siapa pun di LAN. Matikan Telnet, aktifkan SSH/HTTPS bila firmware mendukung;
> kalau tidak, batasi akses manajemen ke satu host admin saja.

> **Yang perlu didata dari switch ini** (butuh login) — tiga yang pertama
> **memblokir** rencana ingress di §2.2:
> - 🔴 **Berapa port SFP+ yang masih kosong** — dibutuhkan **1 port** untuk
>   menyambungkan `PROXMOX-2U` ke jalur data
> - 🔴 **Apakah jumbo frame (MTU 9000) diaktifkan** — `HPC-GPU` memakai MTU 9000,
>   dan kalau switch tidak meneruskan jumbo frame, throughput akan anjlok diam-diam
> - 🔴 **Tipe port SFP+** (DAC / SR fiber / RJ45) — menentukan transceiver & kabel
>   yang harus dibeli untuk proxmox
> - Model & versi firmware
> - Pemetaan VLAN — apakah `192.168.30.0/24` benar-benar terisolasi
> - Port mana yang dipakai SFP+ `T4-Storage` dan `HPC-GPU`

> 📄 **Dokumen lengkap switch:** [`network-devices/zyxel-switch.md`](network-devices/zyxel-switch.md)
> — termasuk peta port, daftar yang belum diketahui, dan 9 temuan Known Issues.

### 5.2 ONT Huawei — `192.168.18.1` (uplink internet)

| Field | Nilai |
|---|---|
| **Peran** | **ONT / gateway internet**, merangkap router, DHCP, dan **DNS** |
| **MAC** | `78:5C:5E:C5:9A:72` → OUI **Huawei Technologies** |
| **Port** | `53/tcp` **open** (DNS) · `80/tcp` **open** (ssl/http) · `22/tcp` filtered · `443/tcp` closed |
| **Sambungan** | **ONT → Zyxel lewat LAN/RJ45** — seluruh infrastruktur ada di belakangnya |
| **Model** | ⚠️ *(isi — halaman webnya memuat string `ONT` dan `ZTE` padahal OUI Huawei; baca label fisik)* |

> 🔴 **Ini satu-satunya batas antara internet dan seluruh infrastruktur**,
> termasuk ketiga BMC. Perangkat dipasok ISP, jadi konfigurasinya belum tentu
> sepenuhnya di bawah kendali tim. **Audit port-forward, UPnP, dan DMZ** adalah
> pemeriksaan paling murah dengan risiko terbesar bila diabaikan.
>
> 📄 Dokumen lengkap + checklist audit: [`network-devices/ont-huawei.md`](network-devices/ont-huawei.md)

### 5.3 Gateway segmen klien

| IP | Peran | Catatan |
|---|---|---|
| `192.168.0.1` | Gateway segmen klien (kantor) | ⚠️ `OpenSSH_6.6.0` — sangat tua |

---

## 5A. Akses Admin Jarak Jauh — Cloudflare Zero Trust

Akses admin ke LAN server berjalan lewat **Cloudflare Zero Trust (WARP)**,
bukan VPN konvensional atau port-forward.

| Field | Nilai |
|---|---|
| **Mekanisme** | Cloudflare WARP client di laptop admin |
| **IP WARP laptop** | `100.96.0.4` (interface `CloudflareWARP`) |
| **Rute yang dipasang** | `192.168.18.0/24` → gateway `192.0.2.1` via `100.96.0.4` |
| **Protokol yang lewat** | ✅ TCP · ❌ **ICMP tidak diteruskan** |
| **Lokasi connector** | ⚠️ **belum teridentifikasi** — lihat catatan di bawah |

> ✅ **Ini pilihan yang bagus.** Karena akses admin lewat Zero Trust, **tidak ada
> alasan** membuka port apa pun dari internet ke LAN. Kalau audit ONT menemukan
> port-forward, hampir pasti itu sisa konfigurasi lama yang bisa dihapus.

> ⚠️ **Connector-nya ada di mana belum diketahui.** Sudah dipastikan **bukan di
> `proxmox`** — `cloudflared`, `warp-svc`, `tailscaled`, dan `zerotier-one`
> semuanya `inactive`, tidak ada prosesnya, dan tidak ada paketnya. Kandidat yang
> tersisa: kontainer Docker di `T4-Storage` (node itu menjalankan Docker), atau
> `HPC-GPU`, atau perangkat lain.
>
> **Kenapa ini perlu dipastikan:** connector adalah pintu masuk ke seluruh LAN.
> Kalau host tempatnya berjalan mati, akses admin jarak jauh ikut hilang — dan
> kalau host itu jatuh ke tangan lain, seluruh jaringan ikut. Cek di dashboard
> Cloudflare Zero Trust → **Networks → Tunnels**, lalu catat host dan rutenya
> di sini.

> **Catatan koreksi:** peta 2026-08-28 menyebut Tailscale (`100.96.0.4` dikira
> Tailscale). Alamat `100.64.0.0/10` memang dipakai Tailscale **maupun**
> Cloudflare WARP. Yang terpasang di laptop admin adalah **Cloudflare WARP**.
> `HPC-GPU` tercatat punya interface `tailscale0` pada koleksi 2026-08-28 —
> perlu dipastikan apakah masih dipakai atau sisa yang bisa dibersihkan.

---

## 6. Host Lain yang Terdeteksi

| IP | Port | Dugaan | Status |
|---|---|---|---|
| `192.168.18.166` | 445 | Host SMB — Windows atau NAS | Di luar cakupan pendataan server Linux |
| `192.168.0.100`, `.101` | 80 | Appliance / printer | Segmen klien |
| `192.168.0.109`, `.129` | 445 | Workstation Windows | Segmen klien |
| `192.168.0.53` | — | Laptop admin (mesin tempat scan dijalankan) | — |

---

## 7. Host yang Sebelumnya Terdeteksi, Kini Tidak Merespons

| IP | Sebelumnya | Status 2026-09-02 | Tindak lanjut |
|---|---|---|---|
| **`192.168.18.194`** | `pipeline` — **Slurm controller** (`slurmctld`) cluster `bioinfo` | 🔴 **tidak merespons** di port 22/80/443 dari dalam maupun luar LAN | **Prioritas tinggi.** `slurm.conf` di `HPC-GPU` masih menetapkan `SlurmctldHost=pipeline(192.168.18.194)`. Selama host ini mati, penjadwalan Slurm tidak berfungsi — yang konsisten dengan temuan bahwa `HPC-GPU` dipakai interaktif, bukan lewat `sbatch` |
| **`192.168.18.113`** | Storage — export `/media/t4/96-Storage` | 🔴 **tidak merespons ping maupun TCP** | ✅ **Sudah terjelaskan** — ini IP lama `T4-Storage`. Bukan host hilang, tapi host yang pindah alamat ke `.193`. Bersihkan referensi lama (lihat §8) |

---

## 8. Referensi Usang yang Harus Diperbaiki

Perpindahan IP `T4-Storage` dari `.113` ke `.193` **tidak pernah dicatat**, dan
memutus beberapa hal sekaligus tanpa menimbulkan error yang terlihat:

| Lokasi | Referensi usang | Akibat | Perbaikan |
|---|---|---|---|
| `/etc/fstab` di `HPC-GPU` | `192.168.18.113:/media/t4/96-Storage` | Mount `/mnt/t4-storage` **failed** | Ganti ke `192.168.18.193` |
| `/etc/prometheus/prometheus.yml` di `T4-Storage` | 4 job menunjuk `192.168.18.113` | **Seluruh monitoring mati** — tidak ada alarm sama sekali | Ganti ke `192.168.18.193`, lalu `systemctl reload prometheus` |
| `slurm.conf` di `HPC-GPU` | `SlurmctldHost=pipeline(192.168.18.194)` | Penjadwalan Slurm tidak jalan | Pastikan nasib host `.194` dulu (§7) |

> 🔴 **Inilah pola kegagalan paling berbahaya di infrastruktur ini:** perubahan
> alamat yang tidak dicatat, memutus beberapa integrasi sekaligus, **tanpa satu
> pun alarm berbunyi** — karena yang mati justru sistem alarmnya. Disk
> `/dev/sdj` di `T4-Storage` sudah berstatus **SMART FAILED** dan tidak ada yang
> tahu sampai pendataan ini.

---

## 9. Cara Mengulang Discovery

### 9.1 Dari laptop admin (lewat Cloudflare Zero Trust)

`ping` **tidak akan bekerja** — WARP tidak meneruskan ICMP. Pakai probe TCP:

```bash
# Host hidup di LAN server (probe TCP, bukan ping)
for n in $(seq 1 254); do
  ip=192.168.18.$n
  for p in 22 80 443 623 9090; do
    timeout 1 bash -c "echo > /dev/tcp/$ip/$p" 2>/dev/null && { echo "$ip:$p"; }
  done
done

# Selalu jalankan kontrol ke IP yang pasti kosong, untuk memastikan
# hasil "open" bukan artefak proxy WARP
timeout 2 bash -c "echo > /dev/tcp/192.168.18.77/22" && echo "CURIGA: false positive"
```

### 9.2 Identifikasi peran host (jauh lebih menentukan daripada nomor port)

```bash
# Sertifikat TLS — paling ampuh membedakan BMC dari server biasa
echo | openssl s_client -connect <ip>:443 2>/dev/null |
  openssl x509 -noout -subject -issuer -dates

# Judul halaman & header
curl -sk -D - https://<ip>/ | grep -Ei '^Server:|^Location:|<title>'

# Versi & kunci SSH
ssh-keyscan -T 8 -t rsa,ed25519 <ip>

# Vendor dari OUI MAC (jalankan dari host di segmen yang sama)
ip neigh
```

### 9.3 Dari dalam LAN server (vantage point terbaik)

```bash
ssh -i ~/.ssh/id_proxmox root@192.168.18.190

ip neigh                      # tabel ARP — MAC seluruh host aktif
getent hosts <ip>             # reverse DNS
showmount -e 192.168.18.193   # export NFS T4-Storage
```

### 9.4 Segmen `192.168.30.0/24`

Hanya bisa dipindai **dari** `T4-Storage` atau `HPC-GPU` — bukan dari laptop
admin, dan **bukan** dari `proxmox` (yang tidak punya kaki di sana; `ip route get
192.168.30.2` keluar lewat gateway `.18.1` dan tidak sampai).

---

## 10. Tindak Lanjut

1. 🔴 **Rotasi kredensial BMC `192.168.18.200`** — bocor plaintext lewat Prometheus.
2. 🔴 **Perbaiki target Prometheus `.113 → .193`** agar monitoring hidup lagi.
3. 🔴 **Tangani `/dev/sdj` di `T4-Storage`** yang SMART FAILED.
4. 🟠 **Pastikan nasib `192.168.18.194` (`pipeline`/Slurm controller)** — mati permanen atau sementara?
5. 🟠 **Data switch Zyxel** — model, jumlah port SFP+ kosong, tipe port, dan status
   jumbo frame. Tiga hal pertama **memblokir rencana ingress** di §2.2. Sekalian
   matikan Telnet dan dokumentasikan pemetaan VLAN-nya.
6. 🟠 **Pasang NIC SFP+ 10 GbE di `PROXMOX-2U`** (`192.168.30.4`) agar bisa berperan
   sebagai ingress data — slot PCIe sudah dipastikan tersedia, lihat §2.2.
7. 🟠 **Pisahkan ketiga BMC ke VLAN manajemen** terpisah.
8. 🟡 **Verifikasi MTU 9000** di sisi `T4-Storage` dan di switch: `ping -M do -s 8972 -c4 192.168.30.3`.
9. 🟡 **Dapatkan kredensial SSH `T4-Storage`** agar bisa didata penuh.
10. 🟡 **Perbaiki `/etc/fstab` di `HPC-GPU`** (`.113 → .193`).

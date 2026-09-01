# Zyxel Switch — Switch Inti (`192.168.18.250`)

> **Tipe Unit:** Switch manageable — 1 unit
> **Status:** 🟢 Production
> **Terakhir Diperbarui:** 2026-09-02
> **PIC:** *(isi)*
> **Sumber Data:** ⚠️ **fingerprint jarak jauh tanpa login** — `nmap -sV`, probe SNMP,
> banner Telnet, tabel ARP, dan halaman web configurator. Dijalankan dari
> `proxmox` (`192.168.18.190`) pada 2026-09-02.
> **Dokumen Terkait:** [network-map](../network-map.md) · [ont-huawei](ont-huawei.md) · [README §2](../../README.md#2-arsitektur-umum)

> 🔴 **INI PERANGKAT PALING KRITIS DI SELURUH INFRASTRUKTUR.**
> **Semua** lalu lintas melewatinya: internet dari ONT, LAN server 1 GbE,
> jalur data SFP+ 10 GbE, dan **ketiga BMC**. Switch ini mati = seluruh
> infrastruktur terputus total — bukan cuma melambat, tapi hilang sama sekali.
> Tidak ada jalur redundan sama sekali.

---

## 1. Identitas

| Field | Nilai |
|---|---|
| **Peran** | Switch inti — satu-satunya perangkat penghubung seluruh infrastruktur |
| **IP Manajemen** | `192.168.18.250` |
| **MAC** | **`1C:74:0D:FF:DA:64`** |
| **Vendor** | **Zyxel Communications** *(OUI `1C:74:0D` + footer web configurator)* |
| **Model** | ⚠️ *(isi — tidak diumumkan sebelum login; baca dari label fisik)* |
| **Firmware** | ⚠️ *(isi)* |
| **Serial Number** | ⚠️ *(isi — dari label fisik)* |
| **Asset Tag** | *(isi)* |
| **Jumlah Port RJ45** | ⚠️ *(isi)* |
| **Jumlah Port SFP+** | ⚠️ *(isi — minimal 2 terpakai, butuh 1 lagi untuk rencana ingress)* |
| **Lokasi Rak / RU** | *(isi)* |
| **Sumber Daya / PDU** | *(isi — ⚠️ cek apakah tersambung UPS)* |
| **Tanggal Pembelian / Garansi** | *(isi)* |

---

## 2. Antarmuka Manajemen

| Layanan | Port | Status | Keamanan |
|---|---|---|---|
| **Telnet** | `23/tcp` | 🟢 terbuka | 🔴 **plaintext** — username & password terkirim tanpa enkripsi |
| **HTTP** | `80/tcp` | 🟢 terbuka | 🔴 **plaintext** — web configurator, charset `gb2312` |
| **HTTPS** | `443/tcp` | 🔴 **tidak tersedia** | — |
| **SSH** | `22/tcp` | 🔴 **tidak tersedia** | — |
| **SNMP** | `161/udp` | 🟢 terbuka | 🔴 **merespons tanpa autentikasi kuat** |

Bukti Telnet meminta kredensial dalam plaintext:

```
$ telnet 192.168.18.250
Connected to 192.168.18.250.
Username(1-32 chars):
Password(1-32 chars):
```

Bukti web configurator:

```
$ curl -sD - http://192.168.18.250/
HTTP/1.0 302 Redirect
Server: WebServer
Location: http://192.168.18.250/index.asp
...
<title>Web Configurator</title>
... ZyXEL Communications Corp.
```

Bukti SNMP merespons:

```
$ nmap -sU -p161 --script snmp-info -Pn 192.168.18.250
161/udp open  snmp
| snmp-info:
|   enterprise: 943271984
|_  snmpEngineBoots: 0
MAC Address: 1C:74:0D:FF:DA:64 (Zyxel Communications)
```

> 🔴 **Tidak ada satu pun jalur manajemen terenkripsi.** Siapa pun yang bisa
> menyadap LAN — termasuk dari perangkat yang terhubung ke Wi-Fi ONT — dapat
> menangkap kredensial admin switch. Dan pemegang kredensial switch memegang
> **seluruh jaringan**: ia bisa membuat mirror port, memindahkan VLAN, atau
> memutus segalanya.

---

## 3. Topologi Port

Yang **sudah pasti** tersambung (disimpulkan dari alamat MAC & jalur trafik yang
terverifikasi), tapi **nomor port fisiknya belum diketahui**:

| Perangkat | Tipe Port | Kecepatan | Segmen | Port # |
|---|---|---|---|---|
| **ONT Huawei** (`192.168.18.1`) | RJ45 | 1 GbE | uplink internet | *(isi)* |
| `T4-Storage` `eno1` (`192.168.18.193`) | RJ45 | 1 Gb/s | LAN server | *(isi)* |
| `T4-Storage` `eno2` | RJ45 | ⚠️ **100 Mb/s** | *(isi)* | *(isi)* |
| `PROXMOX-2U` `nic0` (`192.168.18.190`) | RJ45 | 1 Gb/s | LAN server | *(isi)* |
| `HPC-GPU` `enp34s0f0` (`192.168.18.178`) | RJ45 | 1 Gb/s | LAN server | *(isi)* |
| BMC `T4-Storage` (`192.168.18.200`) | RJ45 | 1 GbE | LAN server ⚠️ | *(isi)* |
| BMC `PROXMOX-2U` (`192.168.18.13`) | RJ45 | 1 GbE | LAN server ⚠️ | *(isi)* |
| BMC `HPC-GPU` (`192.168.18.119`) | RJ45 | 1 GbE | LAN server ⚠️ | *(isi)* |
| **`T4-Storage` `enp65s0f0`** (`192.168.30.2`) | **SFP+** | **10 Gb/s** | jalur data | *(isi)* |
| **`HPC-GPU` `enp1s0f0`** (`192.168.30.3`) | **SFP+** | **10 Gb/s** | jalur data | *(isi)* |
| `T4-Storage` `enp65s0f1` | SFP+ | ⚪ down | — | *(tidak terpasang)* |
| `HPC-GPU` `enp1s0f1` | SFP+ | ⚪ down | — | *(tidak terpasang)* |

> **SFP+ hanya dipakai dua node** — `T4-Storage` dan `HPC-GPU`. Seluruh perangkat
> lain, termasuk uplink internet dan seluruh BMC, memakai RJ45 1 GbE.

---

## 4. Yang Belum Diketahui — Memblokir Pekerjaan Lain

Semua butuh login ke switch. **Empat yang pertama memblokir rencana ingress**
di [README §2.2](../../README.md#22-arsitektur-target--proxmox-sebagai-ingress-data).

| # | Pertanyaan | Kenapa penting | Prioritas |
|---|---|---|---|
| 1 | **Berapa port SFP+ yang masih kosong?** | Butuh **1 port** untuk menyambungkan `PROXMOX-2U` ke jalur data 10 GbE | 🔴 Memblokir |
| 2 | **Tipe port SFP+ — DAC / SR fiber / RJ45?** | Menentukan transceiver & kabel yang harus dibeli | 🔴 Memblokir |
| 3 | **Apakah jumbo frame (MTU 9000) aktif?** | `HPC-GPU` sudah MTU 9000. Kalau switch tidak meneruskan jumbo frame, throughput anjlok **tanpa pesan error** | 🔴 Memblokir |
| 4 | **Apakah `192.168.30.0/24` benar-benar VLAN terpisah**, atau cuma beda subnet di broadcast domain yang sama? | Kalau cuma beda subnet, tidak ada isolasi sungguhan antara jalur data dan LAN | 🔴 Memblokir |
| 5 | Model & versi firmware | Menentukan fitur yang tersedia (SSH? HTTPS? 802.1X?) dan apakah ada CVE | 🟠 Tinggi |
| 6 | Peta port ↔ perangkat | Tanpa ini, mencabut kabel = tebak-tebakan | 🟠 Tinggi |
| 7 | Apakah SNMP community masih `public`? | Kalau ya, seluruh topologi & statistik terbaca tanpa autentikasi | 🟠 Tinggi |
| 8 | Apakah ada VLAN manajemen untuk BMC? | Sekarang ketiga BMC satu segmen dengan LAN data | 🟠 Tinggi |
| 9 | Konfigurasi STP / loop protection | Melindungi dari loop tak sengaja saat pasang kabel | 🟡 Sedang |
| 10 | Apakah konfigurasi pernah di-backup? | Switch mati = konfigurasi hilang, jaringan dibangun ulang dari nol | 🟠 Tinggi |

### 4.1 Cara mengambilnya

```bash
# Login web (plaintext — lakukan dari mesin admin, bukan jaringan publik)
http://192.168.18.250/index.asp

# Yang perlu dicatat dari web configurator:
#   System Info      -> model, firmware, serial, uptime
#   Port Status      -> daftar port, tipe (RJ45/SFP), speed, link state
#   VLAN             -> daftar VLAN, port mana di VLAN mana, tagged/untagged
#   Jumbo Frame/MTU  -> aktif atau tidak, nilainya berapa
#   SNMP             -> community string yang aktif
#   Management       -> apakah SSH/HTTPS bisa diaktifkan

# BACKUP KONFIGURASI — lakukan sebelum mengubah apa pun
#   Management -> Maintenance -> Configuration -> Backup
#   Simpan hasilnya di luar repo ini (berisi kredensial)
```

---

## 5. Known Issues & Risiko

| ID | Temuan | Dampak | Prioritas |
|---|---|---|---|
| `KI-SW01` | **SPOF absolut** — seluruh infrastruktur (internet, LAN, jalur data, BMC) lewat satu switch tanpa redundansi | Switch mati = semuanya mati serentak. Tidak ada jalur alternatif | 🔴 Kritis |
| `KI-SW02` | **Manajemen hanya Telnet + HTTP**, keduanya plaintext, tanpa HTTPS/SSH | Kredensial admin switch bisa disadap dari LAN. Pemegangnya menguasai seluruh jaringan | 🔴 Kritis |
| `KI-SW03` | **Ketiga BMC berada di segmen yang sama dengan LAN data** | BMC = kendali setara akses fisik, terjangkau dari setiap host dan setiap perangkat Wi-Fi ONT | 🔴 Kritis |
| `KI-SW04` | **SNMP `161/udp` terbuka** dan merespons | Topologi & statistik jaringan terbaca tanpa autentikasi kuat | 🟠 Tinggi |
| `KI-SW05` | **Konfigurasi belum pernah di-backup** *(perlu konfirmasi)* | Switch rusak = seluruh konfigurasi VLAN hilang, jaringan dibangun ulang dari nol | 🟠 Tinggi |
| `KI-SW06` | **Status jumbo frame tidak diketahui** padahal `HPC-GPU` memakai MTU 9000 | Kalau tidak diteruskan, throughput NFS anjlok diam-diam tanpa error | 🟠 Tinggi |
| `KI-SW07` | **Model, firmware, dan peta port tidak terdokumentasi** | Tidak bisa cek CVE, tidak bisa rencanakan kapasitas, cabut kabel jadi tebak-tebakan | 🟠 Tinggi |
| `KI-SW08` | **`T4-Storage eno2` nego di 100 Mb/s** pada port gigabit | Indikasi kabel rusak atau port switch bermasalah | 🟡 Sedang |
| `KI-SW09` | **Tidak diketahui apakah switch tersambung UPS** | Listrik padam sekejap = seluruh jaringan putus meski server tetap hidup | 🟠 Tinggi |

---

## 6. Rekomendasi

**Segera, tanpa mengubah topologi:**
1. **Backup konfigurasi switch** dan simpan di luar repo ini.
2. **Catat model, firmware, dan peta port** — dasar semua pekerjaan lain.
3. **Aktifkan HTTPS dan/atau SSH** bila firmware mendukung, lalu **matikan Telnet**.
   Kalau firmware tidak mendukung, batasi akses manajemen ke satu IP admin saja.
4. **Ganti SNMP community** dari `public`, atau matikan SNMP kalau tidak dipakai.
5. **Pastikan switch tersambung UPS** — percuma server punya UPS kalau switch-nya mati.

**Perbaikan struktural:**
6. **Pisahkan BMC ke VLAN manajemen sendiri** (mis. VLAN 30) yang hanya bisa
   dijangkau dari host admin. Ini perbaikan keamanan dengan dampak terbesar
   per usaha di seluruh infrastruktur — satu perubahan, tiga BMC langsung aman.
7. **Pastikan `192.168.30.0/24` benar-benar VLAN terisolasi**, bukan sekadar
   subnet berbeda.
8. **Sediakan 1 port SFP+ untuk `PROXMOX-2U`** sesuai rencana ingress.

**Jangka panjang:**
9. **Switch cadangan.** Selama hanya ada satu switch, SPOF ini tidak bisa
   dihilangkan — hanya bisa dipersingkat waktu pemulihannya. Unit cadangan
   dengan konfigurasi yang sudah di-restore memangkas downtime dari berjam-jam
   menjadi menit.

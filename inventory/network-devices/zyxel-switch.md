# Zyxel MGS3520-28FX — Switch Inti (`192.168.18.250`)

> **Tipe Unit:** Switch manageable L2, 28 port — 1 unit
> **Status:** 🟢 Production
> **Terakhir Diperbarui:** 2026-09-02
> **PIC:** *(isi)*
> **Sumber Data:** ✅ **CLI switch (Telnet, perintah `show` saja — tidak ada yang
> mengubah konfigurasi)**, dijalankan dari `proxmox` (`192.168.18.190`) 2026-09-02.
> **Dokumen Terkait:** [network-map](../network-map.md) · [ont-huawei](ont-huawei.md) · [README §2](../../README.md#2-arsitektur-umum)

> 🔴 **INI PERANGKAT PALING KRITIS DI SELURUH INFRASTRUKTUR.**
> **Semua** lalu lintas melewatinya: internet dari ONT, LAN server, jalur data
> SFP+ 10 GbE, dan **ketiga BMC**. Switch ini mati = seluruh infrastruktur
> terputus total. Tidak ada jalur redundan sama sekali.

---

## 1. Identitas

| Field | Nilai |
|---|---|
| **Model** | ✅ **ZyXEL MGS3520-28FX** |
| **Product Name** | `ZyXEL MGS3520-28FX Switch Product` |
| **Serial Number** | ✅ **`S175852000302`** |
| **MAC** | `1C:74:0D:FF:DA:64` |
| **IP Manajemen** | `192.168.18.250` (VLAN 1) |
| **Hardware Version** | `V1.2` |
| **Firmware aktif** | **`V1.06(ABGV.0)b1`** — ⚠️ *compiled **2019-08-07***, ± 7 tahun |
| **Firmware cadangan** | `V1.04(ABGV.0)` |
| **Bootrom** | `1.6` |
| **Prosesor** | ARM Cortex-A9 1 GHz, SDRAM 512 MB |
| **Jumlah interface** | **28** |
| **Modul daya** | `AC` — ⚠️ **tunggal**, tidak ada PSU redundan |
| **Suhu switch** | 27,9 °C 🟢 |
| **Uptime saat pendataan** | **40 hari 12 jam** (naik ± 2026-07-24) |
| **SNMP OID** | `1.3.6.1.4.1.890.1.5.8.83` |
| **sysLocation** | ⚠️ `sample sysLocation factory default` — **belum pernah diisi** |
| **Kontak admin** | ⚠️ `ZyXEL (http://www.zyxel.com)` — masih default pabrik |
| **Lokasi Rak / RU** | *(isi — survei fisik)* |
| **Sumber Daya / PDU** | *(isi — ⚠️ **wajib**: cek apakah tersambung UPS)* |
| **Tanggal Pembelian / Garansi** | *(isi)* |

---

## 2. Antarmuka Manajemen & Kredensial

| Layanan | Port | Status | Keamanan |
|---|---|---|---|
| **Telnet** | `23/tcp` | 🟢 aktif | 🔴 **plaintext** |
| **HTTP** | `80/tcp` | 🟢 aktif | 🔴 **plaintext** — POST polos ke `/goform/SetLogin`, tanpa hashing, tanpa token CSRF, tanpa captcha |
| **HTTPS** | `443/tcp` | 🔴 tidak tersedia | — |
| **SSH** | `22/tcp` | 🔴 tidak tersedia | — |
| **SNMP** | `161/udp` | 🟡 daemon mendengarkan | ✅ **tidak ada community yang dikonfigurasi** (`show snmp community` kosong, encryption OFF) |

> 🔴 **Kredensial admin masih default pabrik.**
> Terkonfirmasi berhasil login dengan pasangan user/password bawaan yang
> terdokumentasi publik. Digabung dengan manajemen yang **seluruhnya plaintext**
> (Telnet + HTTP, tanpa SSH/HTTPS), ini berarti:
> siapa pun yang bisa menjangkau LAN dapat mengambil alih switch — dan pemegang
> switch memegang **seluruh jaringan**: bisa membuat mirror port untuk menyadap
> semua trafik, memindahkan VLAN, atau memutus segalanya.
>
> **Ganti password sekarang.** Simpan yang baru di password manager, entri
> `Switch / zyxel-192.168.18.250` — **jangan tulis di dokumen ini**.

> ✅ **Kabar baik soal SNMP:** tabel community **kosong**, jadi meski port
> `161/udp` merespons probe, tidak ada data yang bisa ditarik tanpa autentikasi.
> Ini lebih baik daripada dugaan awal.

---

## 3. Peta Port — Terverifikasi dari MAC Address Table

**28 port: `e0/0/1`–`e0/0/24` (1 GbE) + `e0/0/25`–`e0/0/28` (10 GbE).**

| Port | Tipe | Link | Speed | PVID | VLAN | Terhubung ke |
|---|---|---|---|---|---|---|
| **`e0/0/1`** | RJ45 | 🟢 up | 1 Gb/s | 1 | 1 | **ONT Huawei** `78:5c:5e:c5:9a:72` **+** perangkat lain `50:e9:71:03:26:8a` ⚠️ |
| **`e0/0/2`** | RJ45 | 🟢 up | 1 Gb/s | 1 | 1 | **`HPC-GPU`** host `9c:6b:00:72:1f:2c` **+ BMC** `9c:6b:00:72:1d:8e` |
| **`e0/0/3`** | RJ45 | 🟢 up | 1 Gb/s | 1 | 1 | **`PROXMOX-2U`** host `7c:c2:55:c0:b7:ea` **+ BMC** `7c:c2:55:c0:b5:da` |
| **`e0/0/4`** | RJ45 | 🟢 up | 1 Gb/s | 1 | 1 | **`T4-Storage`** `eno1` `3c:ec:ef:9f:7f:b0` **+ BMC** `3c:ec:ef:9f:7d:95` |
| `e0/0/5`–`e0/0/24` | RJ45 | ⚪ down | — | 1 | 1 | **20 port kosong** |
| **`e0/0/25`** | **SFP+** | ⚪ down | 10 Gb/s | 1 | 1 | 🟢 **KOSONG — untuk `PROXMOX-2U`** |
| **`e0/0/26`** | **SFP+** | 🟢 up | **10 Gb/s** | **30** | 1,30 | **`T4-Storage`** `enp65s0f0` `94:57:a5:64:0d:48` → `192.168.30.2` |
| **`e0/0/27`** | **SFP+** | ⚪ down | 10 Gb/s | 1 | 1 | 🟢 **KOSONG — cadangan** |
| **`e0/0/28`** | **SFP+** | 🟢 up | **10 Gb/s** | **30** | 1,30 | **`HPC-GPU`** `enp1s0f0` `c4:34:6b:fd:bc:58` → `192.168.30.3` |

> ✅ **Dua port SFP+ kosong (`e0/0/25` dan `e0/0/27`).** Ini menjawab pertanyaan
> yang selama ini memblokir rencana ingress: **`PROXMOX-2U` bisa disambungkan ke
> jalur data 10 GbE**, dan masih tersisa satu port cadangan.

> ⚠️ **`T4-Storage eno2` tidak ada di tabel MAC switch ini** — jadi port yang
> nego di 100 Mb/s itu tersambung ke perangkat lain (kemungkinan ke port LAN ONT),
> bukan ke switch. Perlu ditelusuri fisik.

> ⚠️ **Ada perangkat tak dikenal di `e0/0/1`** (`50:e9:71:03:26:8a`), berbagi port
> dengan ONT. Kemungkinan perangkat lain di sisi LAN ONT. **Perlu diidentifikasi** —
> apa pun itu, ia berada di segmen yang sama dengan seluruh server dan BMC.

### 3.1 🔴 Temuan penting: BMC berbagi port dengan host (NC-SI)

Tabel MAC membuktikan **setiap BMC memakai port fisik yang sama dengan host-nya**:

```
port 0/0/3  →  7c:c2:55:c0:b7:ea  (proxmox host, nic0)
            →  7c:c2:55:c0:b5:da  (proxmox BMC 192.168.18.13)   ← satu kabel
```

MAC BMC itu **cocok persis** dengan keluaran `ipmitool lan print 1` di proxmox.
Pola yang sama terlihat di port `0/0/2` (`HPC-GPU`) dan `0/0/4` (`T4-Storage`).

> **Konsekuensinya besar untuk rencana keamanan:**
> **BMC TIDAK bisa dipisahkan ke VLAN lain dengan memindahkan kabel** — tidak ada
> kabel BMC terpisah untuk dipindahkan. Pemisahan harus dilakukan dengan:
>
> 1. **Set VLAN ID 802.1q di dalam konfigurasi tiap BMC** (mis. VLAN 30 khusus IPMI).
>    Di proxmox, `ipmitool lan print 1` sekarang menunjukkan `802.1q VLAN ID: Disabled`.
> 2. **Ubah port switch jadi trunk** — untagged untuk VLAN host, **tagged** untuk VLAN BMC.
>
> ⚠️ **Berisiko dikerjakan dari jarak jauh.** Salah langkah = BMC tidak
> terjangkau, dan justru BMC itulah jalan pemulihan saat server bermasalah.
> **Kerjakan saat bisa mengakses konsol fisik.**

---

## 4. VLAN

```
VLAN 1  (default)     : e0/0/1 - e0/0/28   (SELURUH port, untagged)
VLAN 30 "SERVERS"     : e0/0/26, e0/0/28   (untagged, PVID 30)
Total: 2 VLAN
```

| VLAN | Nama | Anggota | Untagged | Fungsi |
|---|---|---|---|---|
| **1** | *(default)* | `e0/0/1`–`e0/0/28` | semua | LAN server `192.168.18.0/24` + **seluruh BMC** |
| **30** | **`SERVERS`** | `e0/0/26`, `e0/0/28` | keduanya | Jalur data 10 GbE `192.168.30.0/24` |

> ✅ **Jalur data 10 GbE memang sudah dipisah** ke VLAN 30 — lebih baik dari dugaan awal.

> ⚠️ **Tapi pemisahannya belum bersih.** `e0/0/26` dan `e0/0/28` **masih menjadi
> anggota untagged VLAN 1 juga** (`UtVlan 1,30`), padahal PVID-nya 30. Artinya
> VLAN 30 belum benar-benar terisolasi dari VLAN 1 di kedua port itu.
> **Perbaikan:** keluarkan `e0/0/26` dan `e0/0/28` dari VLAN 1 sehingga keduanya
> murni anggota VLAN 30.

> 🔴 **Selebihnya tidak ada segmentasi sama sekali.** Server, ketiga BMC, uplink
> internet, dan perangkat tak dikenal di `e0/0/1` semuanya berada di **VLAN 1 yang
> sama** — satu broadcast domain, tanpa pembatas apa pun.

---

## 5. Jumbo Frame — ✅ Aktif

```
show mtu interface
port     mtu size
e0/0/1   10248 bytes
...
e0/0/28  10248 bytes      (seluruh 28 port sama)
```

> ✅ **MTU 10248 byte di seluruh port** — jauh di atas 9000. Jumbo frame
> **diteruskan dengan benar**, jadi `HPC-GPU` (MTU 9000) dan `T4-Storage` aman,
> dan `PROXMOX-2U` bisa langsung memakai MTU 9000 saat disambungkan nanti.
> Ini menghapus salah satu blocker rencana ingress.

---

## 6. Known Issues & Risiko

| ID | Temuan | Dampak | Prioritas |
|---|---|---|---|
| `KI-SW01` | **Password admin masih default pabrik** | Siapa pun di LAN bisa mengambil alih switch, lalu menyadap seluruh trafik lewat port mirroring | 🔴 **Kritis** |
| `KI-SW02` | **SPOF absolut** — seluruh infrastruktur lewat satu switch, **modul daya tunggal (AC)** | Switch atau PSU-nya mati = internet, LAN, jalur data, dan akses BMC hilang serentak | 🔴 **Kritis** |
| `KI-SW03` | **Manajemen seluruhnya plaintext** — Telnet + HTTP, tanpa SSH/HTTPS | Kredensial baru pun akan tetap bisa disadap dari LAN | 🔴 **Kritis** |
| `KI-SW04` | **Ketiga BMC di VLAN 1 bersama server**, dan **berbagi port dengan host** (§3.1) | BMC = kendali setara akses fisik, terjangkau dari seluruh LAN. Tidak bisa dipisah dengan pindah kabel | 🔴 **Kritis** |
| `KI-SW05` | **Firmware `V1.06(ABGV.0)b1` compiled 2019-08-07** (± 7 tahun) | Tertinggal perbaikan keamanan; perlu dicek CVE untuk MGS3520 | 🟠 Tinggi |
| `KI-SW06` | **VLAN 30 belum bersih** — `e0/0/26` & `e0/0/28` masih untagged di VLAN 1 | Isolasi jalur data tidak sepenuhnya berlaku | 🟠 Tinggi |
| `KI-SW07` | **Perangkat tak dikenal `50:e9:71:03:26:8a`** di `e0/0/1` | Ada host tak teridentifikasi satu segmen dengan seluruh server dan BMC | 🟠 Tinggi |
| `KI-SW08` | **Konfigurasi belum pernah di-backup** *(perlu konfirmasi)* | Switch rusak = seluruh konfigurasi hilang, jaringan dibangun ulang dari nol | 🟠 Tinggi |
| `KI-SW09` | **Tidak diketahui apakah switch tersambung UPS** | Listrik berkedip = seluruh jaringan putus meski server tetap hidup | 🟠 Tinggi |
| `KI-SW10` | **`sysLocation` & kontak masih default pabrik** | Menyulitkan identifikasi saat ada banyak perangkat | 🟢 Rendah |
| `KI-SW11` | **`T4-Storage eno2` (100 Mb/s) tidak tersambung ke switch ini** | Ada jalur jaringan yang tidak terdokumentasi | 🟡 Sedang |

---

## 7. Rekomendasi Berurutan

**Hari ini — tanpa mengubah topologi:**

1. **Ganti password admin** (`KI-SW01`). Ini yang paling murah dan paling besar dampaknya.
2. **Backup konfigurasi**, simpan di luar repo ini (isinya kredensial).
3. **Aktifkan SSH/HTTPS bila firmware mendukung, lalu matikan Telnet** (`KI-SW03`).
   Kalau tidak didukung, batasi akses manajemen hanya dari IP host admin.
4. **Isi `sysLocation` dan kontak admin** — memudahkan saat troubleshooting.
5. **Pastikan switch tersambung UPS** (`KI-SW09`). Percuma server punya UPS kalau
   switch-nya mati saat listrik berkedip.

**Terjadwal — saat bisa akses konsol fisik:**

6. **Bersihkan VLAN 30** — keluarkan `e0/0/26` & `e0/0/28` dari VLAN 1 (`KI-SW06`).
7. **Pisahkan BMC ke VLAN IPMI sendiri** (`KI-SW04`) — ingat, ini **butuh set VLAN
   802.1q di dalam tiap BMC + ubah port jadi trunk**, bukan sekadar pindah kabel.
   Lihat §3.1. Kerjakan dengan konsol fisik tersedia.
8. **Identifikasi `50:e9:71:03:26:8a`** di `e0/0/1` (`KI-SW07`).
9. **Telusuri `T4-Storage eno2`** tersambung ke mana (`KI-SW11`).

**Untuk rencana ingress:**

10. **Sambungkan `PROXMOX-2U` ke `e0/0/25`** dengan transceiver SFP+ yang cocok,
    masukkan port itu ke **VLAN 30**, beri IP `192.168.30.4/24` dan MTU 9000.
    Jumbo frame sudah aktif (§5), jadi tidak ada penyesuaian switch lain yang perlu.

**Jangka panjang:**

11. **Switch cadangan.** Selama hanya ada satu unit, SPOF ini tidak bisa
    dihilangkan — hanya bisa dipersingkat waktu pemulihannya. Unit cadangan dengan
    konfigurasi yang sudah di-restore memangkas downtime dari berjam-jam jadi menit.

---

## 8. Cara Mengulang Pendataan

```bash
# Dari host di LAN server (mis. proxmox). Hanya perintah show — read-only.
telnet 192.168.18.250
# login, lalu:
show version                 # model, firmware, serial, hardware
show system                  # nama, uptime, suhu, lokasi
show interface brief         # status seluruh port, speed, PVID, VLAN
show vlan                    # daftar VLAN & anggotanya
show mac-address-table       # peta MAC -> port  (paling berguna)
show mtu interface           # status jumbo frame per port
show snmp community          # community SNMP yang aktif
```

> Pager-nya memotong keluaran panjang — tekan **spasi** untuk halaman berikutnya,
> **Ctrl-C** untuk berhenti.

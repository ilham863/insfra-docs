# ONT Huawei — Gateway Internet (`192.168.18.1`)

> **Tipe Unit:** Optical Network Terminal (perangkat ISP) — 1 unit
> **Status:** 🟢 Production
> **Terakhir Diperbarui:** 2026-09-02
> **PIC:** *(isi — kemungkinan besar dikelola ISP, bukan tim internal)*
> **Sumber Data:** ⚠️ **fingerprint jarak jauh tanpa login** — `nmap -sV`, OUI MAC,
> dan halaman web. Dijalankan dari `proxmox` (`192.168.18.190`) pada 2026-09-02.
> **Dokumen Terkait:** [zyxel-switch](zyxel-switch.md) · [network-map](../network-map.md)

> 🔴 **Perangkat ini adalah satu-satunya batas antara internet dan seluruh
> infrastruktur** — termasuk **ketiga BMC**, yang memberi kendali setara akses
> fisik ke server. Perangkat ini dipasok ISP dan konfigurasinya kemungkinan
> **tidak sepenuhnya di bawah kendali tim internal**. Itu kombinasi yang perlu
> disikapi serius.

---

## 1. Identitas

| Field | Nilai |
|---|---|
| **Peran** | ONT / gateway internet, merangkap **router, DHCP, dan DNS** untuk `192.168.18.0/24` |
| **IP** | `192.168.18.1` |
| **MAC** | **`78:5C:5E:C5:9A:72`** |
| **Vendor (OUI)** | **Huawei Technologies** |
| **Model** | ✅ **Huawei HG8245** *(dari halaman login: string `HG8245` + seluruh logo bernama `hwlogo_*`)* — konfirmasi varian persisnya dari label fisik |
| **Firmware** | ⚠️ *(isi)* — aset web bertanggal `2023-09-11` |
| **ISP / Provider** | *(isi)* |
| **Nomor Layanan / Akun** | *(isi)* |
| **Kecepatan Langganan** | *(isi)* |
| **Kontak Support ISP** | *(isi)* |
| **Kredensial Admin** | *(simpan di password manager, entri `ONT / 192.168.18.1` — **jangan tulis di sini**)* |

> **Model terkonfirmasi Huawei HG8245.** Halaman login memuat string `HG8245`
> dan seluruh berkas logonya bernama `hwlogo_*` (Huawei), konsisten dengan OUI
> MAC `78:5C:5E` = Huawei. String `ZTE` yang juga muncul berasal dari template
> multi-vendor bawaan firmware, bukan penanda perangkatnya.
>
> Login memakai `crypto-js` + `safelogin.js`, jadi password di-hash di sisi
> browser sebelum dikirim — sedikit lebih baik daripada switch Zyxel yang
> mengirimnya polos.

---

## 2. Port & Layanan

Hasil `nmap -sV -Pn 192.168.18.1` dari dalam LAN:

| Port | Status | Layanan | Catatan |
|---|---|---|---|
| `22/tcp` | **filtered** | ssh | Ada tapi difilter — bisa jadi akses teknisi ISP |
| `53/tcp` | **open** | domain | ⚠️ **DNS resolver** — dipakai `proxmox` (`resolv.conf`: `nameserver 192.168.18.1`) |
| `80/tcp` | **open** | ssl/http | Halaman admin |
| `443/tcp` | closed | — | |

---

## 3. Peran dalam Topologi

```
        INTERNET (fiber ISP)
               │
               ▼
    ┌─────────────────────────┐
    │  ONT HUAWEI             │  192.168.18.1
    │  78:5C:5E:C5:9A:72      │  gateway + DHCP + DNS
    └───────────┬─────────────┘
                │  LAN / RJ45
                ▼
    ┌─────────────────────────┐
    │  ZYXEL SWITCH           │  192.168.18.250
    │  1C:74:0D:FF:DA:64      │
    └───────────┬─────────────┘
                │
     ┌──────────┼──────────┬─────────────┐
     ▼          ▼          ▼             ▼
 T4-Storage  PROXMOX-2U  HPC-GPU    3× BMC (.200/.13/.119)
```

> **Semua server dan seluruh BMC berada satu hop di belakang ONT**, dalam satu
> broadcast domain `192.168.18.0/24` yang sama, tanpa firewall internal di antara
> mereka.

**Terverifikasi dari tabel MAC switch:** ONT tersambung ke port **`e0/0/1`**
(VLAN 1). Di port yang sama juga terlihat MAC **`50:e9:71:03:26:8a`** — perangkat
lain yang **belum teridentifikasi**, kemungkinan tersambung ke salah satu port LAN
ONT. Apa pun itu, ia berada di segmen yang sama dengan seluruh server dan BMC,
jadi **wajib diidentifikasi** (`KI-ONT09`).

> Diduga `T4-Storage eno2` — port gigabit yang nego di 100 Mb/s dan **tidak ada di
> tabel MAC switch Zyxel** — juga tersambung ke port LAN ONT, bukan ke switch.
> Perlu ditelusuri fisik.

---

## 4. Known Issues & Risiko

| ID | Temuan | Dampak | Prioritas |
|---|---|---|---|
| `KI-ONT01` | **Seluruh BMC berada di segmen yang sama** dengan jaringan yang di-NAT ONT | Kalau ada port forward, UPnP, atau DMZ yang salah konfigurasi di ONT, BMC bisa terekspos ke internet. BMC terekspos = server dikuasai sepenuhnya | 🔴 Kritis |
| `KI-ONT02` | **Perangkat dikelola ISP**, konfigurasi tidak sepenuhnya di bawah kendali tim | Teknisi ISP bisa mengubah/reset konfigurasi tanpa pemberitahuan; akun admin ISP sering punya hak penuh | 🟠 Tinggi |
| `KI-ONT03` | **Status UPnP tidak diketahui** | UPnP aktif memungkinkan perangkat di LAN membuka port ke internet **sendiri, tanpa persetujuan** | 🔴 Kritis *(perlu konfirmasi)* |
| `KI-ONT04` | **Daftar port forwarding tidak diketahui** | Tidak ada yang tahu layanan apa saja yang terekspos ke internet | 🔴 Kritis *(perlu konfirmasi)* |
| `KI-ONT05` | **Menjadi satu-satunya DNS** (`resolv.conf` proxmox) | ONT reboot/rusak = resolusi nama seluruh server ikut mati | 🟠 Tinggi |
| `KI-ONT06` | **Tidak ada firewall internal** antara LAN klien, server, dan BMC | Satu perangkat Wi-Fi yang terinfeksi punya jalur langsung ke seluruh BMC | 🔴 Kritis |
| `KI-ONT07` | **Password admin ONT kemungkinan masih default pabrik** *(perlu konfirmasi)* | Model Huawei/ZTE punya kredensial default yang terdokumentasi publik | 🟠 Tinggi |
| `KI-ONT08` | **Firmware & detail langganan tidak terdokumentasi** (model sudah terkonfirmasi HG8245) | Tidak bisa cek CVE, tidak bisa eskalasi ke ISP dengan cepat saat gangguan | 🟡 Sedang |
| `KI-ONT09` | **Perangkat tak dikenal `50:e9:71:03:26:8a`** berbagi port `e0/0/1` dengan ONT | Ada host tak teridentifikasi di segmen yang sama dengan seluruh server dan BMC | 🟠 Tinggi |

---

## 5. Yang Wajib Diperiksa — Segera

Login ke `http://192.168.18.1`, lalu catat dan amankan:

| # | Periksa | Yang diharapkan | Kalau tidak sesuai |
|---|---|---|---|
| 1 | **Port Forwarding / Virtual Server** | **Kosong** — tidak ada satu pun | Hapus semua yang tidak lo kenali. Pastikan **tidak ada** yang mengarah ke `.200`, `.13`, `.119`, atau port `623` |
| 2 | **UPnP** | **Nonaktif** | Matikan. UPnP membiarkan perangkat membuka port sendiri ke internet |
| 3 | **DMZ Host** | **Nonaktif** | Matikan. DMZ mengekspos seluruh port satu host ke internet |
| 4 | **Remote Management / TR-069** | Terbatas ke ISP saja | Batasi. Jangan biarkan admin WAN terbuka |
| 5 | **Password admin** | Sudah diganti dari default | Ganti sekarang, simpan di password manager |
| 6 | **Wi-Fi** | Terpisah dari segmen server | Kalau Wi-Fi satu segmen dengan server — ini yang paling gawat. Pisahkan atau matikan |
| 7 | **Firmware** | Versi terbaru dari ISP | Minta ISP update |
| 8 | **Log koneksi masuk** | Tidak ada percobaan dari WAN | Kalau ada, selidiki |

```bash
# Verifikasi dari luar: apakah ada port yang terbuka ke internet?
# Jalankan dari jaringan LUAR (mis. tethering HP, bukan dari LAN kantor).
# Cari tahu IP publik dulu:
curl -s https://ifconfig.me

# Lalu pindai port yang paling berbahaya kalau sampai terekspos:
nmap -Pn -p 22,80,443,623,5900,8006,9090,2049 <ip-publik>
```

> 🔴 **Kalau port `623` (IPMI) atau `5900` (KVM) terlihat terbuka dari internet,
> perlakukan sebagai insiden keamanan** — asumsikan BMC sudah bisa diakses pihak
> luar, dan rotasi seluruh kredensial BMC segera.

---

## 6. Rekomendasi

1. **Audit port forwarding, UPnP, dan DMZ hari ini** (§5). Ini pemeriksaan paling
   murah dengan risiko terbesar bila diabaikan.
2. **Verifikasi dari luar** dengan `nmap` dari jaringan lain — jangan hanya
   percaya pada tampilan konfigurasi.
3. **Pisahkan BMC ke VLAN manajemen di switch Zyxel** ([zyxel-switch.md §7](zyxel-switch.md#7-rekomendasi-berurutan)).
   Selama BMC satu segmen dengan jaringan yang di-NAT ONT, satu kesalahan
   konfigurasi di perangkat ISP bisa membuka jalan ke seluruh server.
4. **Pertimbangkan router/firewall sendiri di antara ONT dan Zyxel.** Menjadikan
   ONT sebagai bridge saja, lalu meletakkan router yang lo kendalikan penuh di
   belakangnya, memberi kontrol firewall yang sekarang tidak ada — dan melepas
   ketergantungan pada perangkat yang dikelola pihak lain.
5. **Sediakan DNS internal** agar resolusi nama tidak bergantung pada ONT
   (`KI-ONT05`). Bisa dijalankan sebagai LXC kecil di `PROXMOX-2U`.

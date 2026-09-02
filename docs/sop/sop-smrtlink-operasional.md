# SOP — Operasional SMRT Link (VM 101 `smrtlink`)

> **Berlaku untuk:** SMRT Link **v26.2.0.292923** di VM 101 (`PROXMOX-2U`)
> **Terakhir Diperbarui:** 2026-09-02
> **PIC:** *(isi)*
> **Rujukan Vendor:** *SMRT Link software installation guide (v26.2)*, PN 103-891-700 Ver. 01
> **Dokumen Terkait:** [vm-101-smrtlink](../../inventory/proxmox-nodes/vm-101-smrtlink.md) · [proxmox](../../inventory/proxmox-nodes/proxmox.md) · [network-map](../../inventory/network-map.md)

> **Cakupan:** cara mengoperasikan SMRT Link sehari-hari, pekerjaan yang masih
> tertunda, prosedur menyambungkan instrumen Vega, dan penanganan masalah.
> **Bukan** panduan instalasi — instalasi sudah selesai, riwayatnya di
> [`vm-101-smrtlink.md` §5.6](../../inventory/proxmox-nodes/vm-101-smrtlink.md).

---

## 1. Akses

### 1.1 Masuk ke sistem

```bash
ssh vega@192.168.18.60        # dari laptop admin atau HPC-GPU
sudo -iu smrtanalysis         # WAJIB pakai -i
```

> 🔴 **`-i` bukan opsional.** Ia memberi *login shell*, sehingga `ulimit -n 8192`
> ikut berlaku — batas yang disyaratkan dokumen PacBio (hlm. 7). Tanpa `-i`,
> batasnya kembali ke 1024 bawaan Ubuntu dan SMRT Link bisa bermasalah saat
> beban tinggi.

Sejak 2026-09-02, `~/.profile` milik `smrtanalysis` sudah memuat:

```bash
export SMRT_ROOT=/opt/pacbio/smrtlink
export PATH="$SMRT_ROOT/admin/bin:$SMRT_ROOT/smrtcmds/bin:$PATH"
```

Jadi perintah bisa diketik pendek — `services-status`, `pbservice`, bukan path penuh.

### 1.2 Akses UI

| Dari | URL |
|---|---|
| LAN (laptop, HPC-GPU) | **`https://192.168.18.60:8243/sl/home`** |
| Segmen instrumen Vega | **`https://192.168.50.1:8243/sl/home`** |

> ⚠️ **Wajib `https://`.** Port 8243 hanya melayani TLS. Kalau diakses lewat
> `http://`, NGINX membalas **`400 Bad Request — The plain HTTP request was sent
> to HTTPS port`**. Browser modern menyembunyikan skema di address bar, jadi
> ketik `https://` secara eksplisit.

> **Browser wajib Google Chrome** (dokumen hlm. 5). Akan muncul peringatan
> sertifikat karena memakai self-signed bawaan — klik **Advanced → Proceed**.

### 1.3 Akses darurat tanpa jaringan

Bila jaringan VM bermasalah, VM tetap bisa dikelola dari `PROXMOX-2U` lewat
QEMU guest agent (komunikasi lewat virtio serial, bukan jaringan):

```bash
ssh root@192.168.18.190
qm guest exec 101 --timeout 60 -- /bin/bash -c "ip -br addr; nft list ruleset"
```

Atau konsol grafis: `https://192.168.18.190:8006` → VM 101 → Console.

---

## 2. Operasional Harian

### 2.1 Cek kesehatan

```bash
services-status        # ringkas   -> "SMRT Link status:  ok"
pbservice status --host localhost --port 9091
ss -tln | grep 8243    # harus "LISTEN 0.0.0.0:8243"
```

Arti keluaran `pbservice status`:

| Baris | Yang dibaca |
|---|---|
| `Services have been up for ...` | Uptime layanan. Mengecil mendadak = pernah restart sendiri |
| `Cromwell is available with N currently running workflows` | Mesin analisis siap. `0` normal, bukan masalah |
| `Pbservice ... IS compatible with Server ...` | Versi client & server cocok |

### 2.2 Hidup, mati, restart

```bash
services-start        # butuh ± 2 menit
services-stop
restart-services      # restart penuh
restart-gui           # restart UI saja, jauh lebih cepat
```

> ⚠️ **Sebelum `services-stop`, pastikan tidak ada job analisis berjalan**
> (dokumen hlm. 10). Cek `pbservice status` pada baris `currently running workflows`.

Karena `services-start` lama, jalankan terlepas dari sesi SSH agar tidak mati
saat koneksi putus:

```bash
setsid nohup services-start > /tmp/start.log 2>&1 < /dev/null &
tail -f /tmp/start.log
```

### 2.3 Uji fungsional menyeluruh

```bash
run-sat-services
```

Site Acceptance Test menjalankan job HiFi Mapping sungguhan (± 3 menit) dan
berakhir dengan **`Job successful`**. Ini membuktikan seluruh rantai bekerja —
layanan, Cromwell, database, dan penulisan ke disk data — bukan sekadar
layanannya hidup. Jalankan setelah setiap upgrade atau perubahan besar.

### 2.4 Log

```bash
ls $SMRT_ROOT/userdata/log/
tail -f $SMRT_ROOT/userdata/log/smrtlink-analysisservices-gui/*.log
tail -50 $SMRT_ROOT/userdata/log/smrtlink-analysisservices-gui/keycloak.stdout
ls $SMRT_ROOT/userdata/log/cromwell/
```

---

## 3. Pekerjaan yang Masih Tertunda

Diurutkan dari yang paling menentukan. Status per 2026-09-02.

### 3.1 🔴 Ganti password bawaan — **paling mendesak**

Dokumen hlm. 11: password `admin` dan `pbinstrument` **bernilai sama di semua
instalasi SMRT Link di dunia**. `pbinstrument` adalah akun yang dipakai instrumen
Vega untuk bicara ke SMRT Link.

```bash
sudo -iu smrtanalysis
set-keycloak-creds --user admin --password 'PASSWORD-BARU' --adminpassword 'admin'
$SMRT_ROOT/smrtcmds/developer/bin/pbservice-instrument \
    set-smrtlink-password --user admin --ask-pass

# verifikasi kedua akun
pbservice status --host localhost --user admin --ask-pass
pbservice status --host localhost --user pbinstrument --ask-pass
```

Keduanya harus keluar dengan exit status `0`. Simpan password baru di password
manager, entri `SMRT Link / admin` dan `SMRT Link / pbinstrument` —
**jangan tulis di repo ini**.

### 3.2 🔴 Jadwalkan backup database

Dokumen hlm. 28: **SMRT Link tidak melakukan backup berkala.** Backup hanya
dilakukan sekali, saat instalasi. Tanpa jadwal, seluruh record — user, Data Set,
analisis, barcode, referensi — hilang bila terjadi masalah filesystem.
Berkas sekuens (BAM) tidak terdampak, tetapi seluruh metadata SMRT Link hilang.

```bash
generate-cron-backup        # hasilkan perintah cron, lalu pasang
crontab -l                  # verifikasi
```

> **Ulangi `generate-cron-backup` setiap kali selesai upgrade.**

### 3.3 🟠 Autostart saat boot

Saat ini layanan **tidak** menyala otomatis setelah VM reboot.

```bash
cat $SMRT_ROOT/admin/template/smrtlink.service.tmpl
# sesuaikan sesuai komentar di dalamnya, pasang sebagai unit systemd, lalu:
sudo systemctl enable smrtlink
```

> ⚠️ Ingat ketergantungan di [`KI-V01`](../../inventory/proxmox-nodes/vm-101-smrtlink.md#10-ketergantungan--risiko):
> disk `/data/smrtlink` berada di pool ber-LUKS yang **tidak auto-unlock**.
> Autostart SMRT Link tidak ada gunanya bila VM-nya sendiri belum bisa start.

### 3.4 🟠 Tentukan sikap soal usage tracking

Saat ini `install-metrics` dan `job-metrics` bernilai `true` — ter-set tanpa
keputusan sadar pada 2026-09-02 (lihat [§12.3 vm-101](../../inventory/proxmox-nodes/vm-101-smrtlink.md)).

```bash
# lihat & ubah — SELALU sertakan argumen, lihat peringatan di §5.4
accept-user-agreement --install-metrics false --job-metrics false
```

Dokumen menganjurkan menerimanya karena mempermudah troubleshooting oleh PacBio.
Membiarkan atau mematikan sama-sama sah — yang penting keputusannya sadar.

### 3.5 🟡 Tambah user & peran

Sekarang hanya ada akun `admin` bawaan. Dokumen hlm. 14–18 menjelaskan tiga peran:

| Peran | Akses |
|---|---|
| **Admin** | Semua modul + kelola user + daftarkan instrumen |
| **Lab Tech** | Semua modul, tanpa fungsi administratif |
| **Bioinformatician** | Hanya Instruments, Data Management, SMRT Analysis |

Bisa lewat LDAP (hlm. 12) atau user lokal di Keycloak (hlm. 16). Untuk user lokal,
konsol Keycloak perlu dinyalakan sementara:

```bash
restart-gui --enable-keycloak-console     # buka https://192.168.18.60:9443/admin
# ... tambahkan user ...
restart-gui --disable-keycloak-console    # matikan lagi setelah selesai
```

> **Matikan kembali setelah selesai.** Dokumen hlm. 12 menganjurkan konsol ini
> nonaktif saat tidak dipakai.

### 3.6 🟡 Sertifikat TLS dari CA

Saat ini memakai self-signed bawaan, sehingga setiap user harus menerima
peringatan browser. Bila sudah punya sertifikat dari CA (hlm. 19):

```bash
services-stop
cp <sertifikat> $SMRT_ROOT/userdata/config/security/smrtlink-site.crt
cp <kunci>      $SMRT_ROOT/userdata/config/security/smrtlink-site.key
services-start
```

---

## 4. Menyambungkan Instrumen PacBio Vega

### 4.1 Persiapan fisik

1. Colok kabel LAN Vega ke **`nic1`** di `PROXMOX-2U` (port Broadcom kedua),
   lewat media converter + kabel FO bila jaraknya jauh.
2. Media converter bersifat **Layer 1 — transparan**; tidak mengubah IP, routing,
   maupun NAT. Aktifkan **LFP / FEF** pada kedua unit agar putusnya fiber ikut
   menurunkan link di sisi tembaga.
3. Verifikasi link dari `PROXMOX-2U`:

```bash
cat /sys/class/net/nic1/carrier      # 1 = kabel tersambung
cat /sys/class/net/nic1/speed        # harapkan 1000
ip -s link show nic1                 # kolom errors & dropped harus 0
```

### 4.2 Setelan jaringan di instrumen

| Field | Nilai |
|---|---|
| IP Address | `192.168.50.10` |
| Subnet Mask | `255.255.255.0` |
| Gateway | **`192.168.50.1`** |
| DNS | `192.168.18.1` |
| **Alamat SMRT Link** | **`192.168.50.1:8243`** |

> 🔴 **Pakai IP `192.168.50.1`, bukan hostname.** Vega berada di segmen
> `192.168.50.0/24` dan DNS-nya mengarah ke ONT yang tidak mengenal nama
> `smrtlink`. Mengisi hostname akan membuat instrumen gagal menemukan server.

### 4.3 Uji sebelum instrumen datang

Colok laptop ke `nic1`, set manual `192.168.50.99/24` gateway `192.168.50.1`:

```bash
ping -c2 192.168.50.1      # sampai ke VM
ping -c2 1.1.1.1           # NAT keluar jalan
ping -c2 google.com        # DNS jalan
ping -c2 192.168.18.13     # HARUS GAGAL - ujian isolasi ke BMC
```

Verifikasi objektif dari sisi VM — angka, bukan tebakan:

```bash
sudo nft list ruleset | grep -E 'counter|comment'
```

> Pakai `.99`, jangan `.10` — alamat itu dicadangkan untuk instrumen.

### 4.4 Pendaftaran di SMRT Link

Setelah instrumen online, daftarkan lewat UI: **Instruments → Add Instrument**.
Dibutuhkan kredensial akun `pbinstrument` — **pastikan sudah diganti** (§3.1).

Port yang dipakai (dokumen hlm. 26):

| Arah | Port |
|---|---|
| Vega → SMRT Link | `8243/tcp` |
| SMRT Link → Vega | `9243/tcp` |
| Vega → NTP eksternal | `123/udp` |
| Vega → DNS | `53/udp,tcp` |
| Vega → PacBio SecureLink | `22`, `80`, `443` |

---

## 5. Penanganan Masalah

### 5.1 `SMRT Link status: Not Running` padahal layanan jalan

**Penyebab paling sering: salah akun.** Perintah dijalankan sebagai `vega`
atau user lain, bukan `smrtanalysis`.

| Akun | Hasil |
|---|---|
| `smrtanalysis` | ✅ `ok` |
| `vega` | 🔴 **`Not Running`** — palsu, akibat `Permission denied` |
| `root` | ✅ `ok`, tapi jangan dibiasakan |

Skrip status mencoba membaca berkas internal milik `smrtanalysis`; bila ditolak,
ia menyimpulkan "tidak jalan". **Selalu `sudo -iu smrtanalysis` lebih dulu.**

### 5.2 `400 Bad Request` saat membuka UI

Diakses lewat `http://`. Port 8243 hanya melayani TLS — ketik `https://`.

### 5.3 `$SMRT_ROOT: command not found`

`$SMRT_ROOT` hanyalah notasi di dokumen PacBio, bukan variabel bawaan sistem.
Di VM ini sudah didefinisikan di `~/.profile` milik `smrtanalysis`, tetapi
**hanya berlaku pada login shell** (`sudo -iu`, bukan `sudo -u`).

### 5.4 ⚠️ Jangan jalankan `accept-user-agreement` tanpa argumen

Perintah ini terlihat seperti pembacaan status, padahal **menulis**. Dokumen
hlm. 29: bila dijalankan tanpa argumen dan setelannya belum pernah diisi, ia
otomatis mengeset `install-metrics` dan `job-metrics` menjadi `true` **dan
langsung memberi tahu PacBio**. Selalu sertakan kedua argumen secara eksplisit.

### 5.5 Kirim log ke PacBio Technical Support

```bash
tsreport-install --bundle --upload     # bila ada koneksi ke PacBio Event Server
tsreport-install --bundle              # offline; hasil .tgz lalu email ke support@pacb.com
# berkas: $SMRT_ROOT/userdata/tsreport/data/ts-install.tgz
```

> Dokumen hlm. 28: bundle hanya memuat log **± 24 jam terakhir**. Jalankan dalam
> sehari sejak masalah muncul.

---

## 6. Backup & Pemulihan

### 6.1 Tiga lapis yang berbeda

| Lapis | Melindungi | Status |
|---|---|---|
| **Database SMRT Link** (`generate-cron-backup`) | Record: user, Data Set, analisis, barcode | 🔴 **belum dijadwalkan** |
| **Snapshot VM** (`qm snapshot`) | Kondisi VM pada satu titik waktu | ✅ ada `pre-smrtlink-install` |
| **Backup VM** (`vzdump` → `pve-backup`) | Seluruh VM, dapat dipulihkan ke bare metal | 🔴 **belum dijadwalkan** |

### 6.2 Snapshot sebelum perubahan besar

```bash
# di PROXMOX-2U
qm snapshot 101 pre-<nama-perubahan> --description "alasan"
qm listsnapshot 101
qm rollback 101 <nama-snapshot>      # kembalikan bila perlu
```

Guest agent melakukan `fs-freeze`/`thaw` sehingga snapshot konsisten.

### 6.3 Backup VM

```bash
# di PROXMOX-2U
vzdump 101 --storage pve-backup --mode snapshot --compress zstd
# jadwal: Datacenter -> Backup -> Add (storage=pve-backup, mode=snapshot)
```

Target `pve-backup` berada di `zfs-storage` (raidz2, tahan 2 disk mati), retensi
7 harian / 4 mingguan / 3 bulanan.

---

## 7. Upgrade SMRT Link

Ringkasan dokumen hlm. 10. Jalur upgrade ke v26.2 didukung dari v13.1, v25.x, dan v26.x.

```bash
# 1. PASTIKAN tidak ada job analisis berjalan
pbservice status --host localhost --port 9091

# 2. snapshot dulu (di PROXMOX-2U)
qm snapshot 101 pre-upgrade-<versi>

# 3. hentikan layanan
sudo -iu smrtanalysis
services-stop

# 4. upgrade
./smrtlink_<versi>.run --rootdir $SMRT_ROOT --upgrade

# 5. nyalakan & uji
services-start
run-sat-services

# 6. WAJIB: buat ulang jadwal backup database
generate-cron-backup
```

---

## 8. Batasan yang Berlaku Saat Ini

| Batasan | Sebab | Rujukan |
|---|---|---|
| **Variant Calling tidak didukung** | JMS `NONE` — `slurmctld` (`192.168.18.194`) mati | [vm-101 §7](../../inventory/proxmox-nodes/vm-101-smrtlink.md) |
| Target Enrichment hanya tanpa variant calling | idem | hlm. 6 |
| Iso-Seq maksimal 20 juta read | Batas single node | hlm. 6 |
| HiFi Mapping maksimal 150 Gb | Batas single node | hlm. 6 |
| Job berjalan **lokal di VM**, bukan di A100 | Tidak ada JMS | — |
| **VM tidak start otomatis setelah proxmox reboot** | `/data/smrtlink` di pool LUKS `noauto` | `KI-V01` |
| Kapasitas data ± 1 tahun | 7,8 TiB vs ±6 TB/tahun + analisis | `KI-V11` |

> Konfigurasi JMS dapat diubah **tanpa install ulang** begitu SLURM hidup:
> `smrt_reconfig`. Itu akan membuka Variant Calling dan pemakaian A100.

---

## 9. Ringkasan Perintah

```bash
# masuk
ssh vega@192.168.18.60 && sudo -iu smrtanalysis

# kesehatan
services-status
pbservice status --host localhost --port 9091
ss -tln | grep 8243

# kendali
services-start / services-stop / restart-services / restart-gui

# uji
run-sat-services

# log
tail -f $SMRT_ROOT/userdata/log/smrtlink-analysisservices-gui/*.log

# tertunda
set-keycloak-creds --user admin --password 'BARU' --adminpassword 'admin'
generate-cron-backup
accept-user-agreement --install-metrics false --job-metrics false

# dukungan
tsreport-install --bundle
```

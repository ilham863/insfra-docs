# Changelog

Semua perubahan penting pada **dokumentasi infrastruktur** ini dicatat di file ini.

Format mengikuti [Keep a Changelog 1.1.0](https://keepachangelog.com/id/1.1.0/),
dan penomoran versi mengikuti [Semantic Versioning 2.0.0](https://semver.org/lang/id/).

> **Cakupan file ini:** perubahan pada *dokumen* (struktur repo, template, SOP, isi inventory).
> Perubahan **fisik server** (ganti RAM, tambah disk, upgrade OS) dicatat di
> [`track-record/server-changelog.md`](track-record/server-changelog.md).
> Kegiatan **maintenance terjadwal** dicatat di
> [`track-record/maintenance-log.md`](track-record/maintenance-log.md).

---

## Aturan Penomoran Versi Dokumentasi

| Segmen | Naik ketika... | Contoh |
|---|---|---|
| **MAJOR** (`X.0.0`) | Struktur direktori repo berubah total; template lama tidak kompatibel; konvensi penamaan diganti | `1.4.2` → `2.0.0` |
| **MINOR** (`x.Y.0`) | Menambah node baru, menambah dokumen/SOP baru, menambah section besar pada template | `1.4.2` → `1.5.0` |
| **PATCH** (`x.y.Z`) | Koreksi typo, update nilai spesifikasi, perbaikan tautan, penyesuaian tabel | `1.4.2` → `1.4.3` |

## Kategori Perubahan yang Dipakai

| Kategori | Arti |
|---|---|
| `Added` | Dokumen, node, section, atau fitur dokumentasi baru |
| `Changed` | Perubahan pada dokumen/prosedur yang sudah ada |
| `Deprecated` | Bagian yang akan dihapus di versi berikutnya |
| `Removed` | Dokumen/section yang sudah dihapus |
| `Fixed` | Perbaikan informasi yang salah |
| `Security` | Perubahan terkait keamanan (rotasi kredensial, pengetatan `.gitignore`, hardening SOP) |

---

## [Unreleased]

Bagian ini menampung perubahan yang sudah di-merge ke `main` tapi belum di-*tag* rilis.
Saat rilis, pindahkan isinya ke section versi baru di bawah dan kosongkan bagian ini.

### Added
- `inventory/proxmox-nodes/vm-101-smrtlink.md` **ditulis ulang dengan keadaan nyata**
  setelah OS terinstall dan jaringan dikonfigurasi. Kini memuat: nama interface
  sebenarnya (`enp6s18`/`enp6s19`), hostname `smrtlink`, mount `/data/smrtlink`
  berbasis UUID, aturan `nftables` lengkap **beserta counter yang membuktikan
  NAT dan isolasi bekerja**, daftar paket/akun/direktori yang dipasang, tabel
  kesesuaian dengan syarat resmi SMRT Link v26.2, tabel port dari dokumen vendor,
  runbook instalasi, dan 11 temuan risiko.
- **VM 101 disiapkan penuh untuk SMRT Link v26.2** (rujukan: *SMRT Link software
  installation guide v26.2*, PN 103-891-700):
  - Ubuntu 24.04.4 LTS, hostname **`smrtlink`** + `/etc/hosts` konsisten — penting
    karena SMRT Link **tidak tahan perubahan hostname**.
  - Akun layanan **`smrtanalysis`** (dokumen melarang install sebagai `root`).
  - `ulimit nofile` **1024 → 8192** lewat `limits.d` (disyaratkan dokumen).
  - Direktori `jobs_root` (HDD 7,8 T), `db_datadir` & `tmp_dir` (SSD lokal,
    dokumen melarang NFS untuk keduanya). `$SMRT_ROOT` **sengaja belum dibuat**.
  - Paket: `qemu-guest-agent`, `openssh-server`, `nftables` — semuanya `enabled`.
- **Jaringan instrumen Vega selesai & terverifikasi**: `192.168.18.60/24` (LAN) +
  `192.168.50.1/24` (gateway Vega), `ip_forward=1`, masquerade, dan isolasi
  `drop` ke `192.168.18.0/24`, `192.168.30.0/24`, `192.168.0.0/22`. Counter
  membuktikan: DNS 43 paket, internet 313 paket, masquerade 225 paket lewat.
- Disk 7,81 TiB dipindahkan dari automount GNOME (`/media/vega/Storage-Vega`,
  tidak permanen) ke **`/data/smrtlink`** dengan entri `fstab` berbasis UUID + `nofail`.
- **Storage PVE baru di `PROXMOX-2U`** — menutup temuan lama bahwa `zfs-storage`
  (140 TB) tidak terdaftar di Proxmox:
  - **`vm-hdd`** — `zfspool` di `zfs-storage/vm-disks`, quota **10 TiB**,
    `sparse`, `blocksize 64k` (memangkas padding raidz2 dibanding default 16k).
  - **`pve-backup`** — `dir` di `zfs-storage/backup`, quota **20 TiB**, content
    `backup`, retensi 7 harian / 4 mingguan / 3 bulanan. **Ini target `vzdump`
    pertama yang pernah ada di node ini.**
- **Bridge `vmbr1`** di `nic1` (port Broadcom kedua yang selama ini menganggur),
  **sengaja tanpa IP di host** — segmen khusus instrumen PacBio Vega, dengan
  VM 101 sebagai gateway/NAT. Backup config lama di `/etc/network/interfaces.bak-2026-09-02`.
- **VM 101 `ubuntu24-desktop`** — 32 vCPU, 64 GiB RAM (ballooning off), UEFI/q35,
  SSD 1000 GiB + EFI di `nvme-scratch`, HDD 7,81 TiB di `vm-hdd`, dua NIC
  (`vmbr0` untuk LAN/HPC, `vmbr1` untuk Vega).
- `inventory/network-devices/zyxel-switch.md` — **didata penuh lewat CLI switch**
  (Telnet, perintah `show` saja). Model **ZyXEL MGS3520-28FX**, serial
  `S175852000302`, firmware `V1.06(ABGV.0)b1` **compiled 2019-08-07**, 28 port,
  uptime 40 hari, suhu 27,9 °C, modul daya **AC tunggal**. Memuat peta port ↔
  perangkat yang diverifikasi dari **MAC address table**, konfigurasi VLAN, dan
  status jumbo frame.
- **Tiga blocker rencana ingress terjawab dan semuanya hijau:**
  **(1)** `e0/0/25` & `e0/0/27` **kosong** — cukup untuk `PROXMOX-2U` plus satu cadangan;
  **(2)** jumbo frame **aktif, MTU 10248 di seluruh port**;
  **(3)** **VLAN 30 `SERVERS` sudah ada** (`e0/0/26`, `e0/0/28`), port proxmox tinggal dimasukkan.
- **Temuan arsitektural — BMC berbagi port fisik dengan host (NC-SI shared LAN).**
  Tabel MAC membuktikan `e0/0/3` membawa MAC host proxmox **dan** MAC BMC-nya
  sekaligus; pola sama di `e0/0/2` (`HPC-GPU`) dan `e0/0/4` (`T4-Storage`).
  **Konsekuensinya: BMC tidak bisa dipisahkan ke VLAN lain dengan memindahkan
  kabel** — harus set VLAN 802.1q di dalam tiap BMC **dan** ubah port switch jadi
  trunk. Rekomendasi di README §2.6 sudah dikoreksi mengikuti temuan ini.
- `inventory/network-devices/` — **kategori baru: perangkat jaringan**, karena switch
  dan ONT terbukti sama kritisnya dengan server:
  - `zyxel-switch.md` — **switch inti `192.168.18.250`** (MAC `1C:74:0D:FF:DA:64`).
    **Seluruh** trafik lewat sini: internet dari ONT, LAN server 1 GbE, jalur data
    SFP+ 10 GbE, dan ketiga BMC. Memuat peta port, 10 pertanyaan yang belum terjawab
    (4 di antaranya memblokir rencana ingress), dan 9 temuan Known Issues.
  - `ont-huawei.md` — **ONT `192.168.18.1`** (MAC `78:5C:5E:C5:9A:72`, OUI Huawei),
    gateway + DHCP + DNS, dikelola ISP. Memuat checklist audit port-forward/UPnP/DMZ
    dan cara verifikasi dari luar dengan `nmap`.
- `README.md` §2.6 — **rancangan jaringan yang aman**: pemisahan VLAN 10/20/30/40
  (mgmt / data / IPMI / klien) beserta matriks izin antar-VLAN, dan tabel lapisan
  pertahanan yang belum ada.
- `README.md` §2.7 — **ringkasan 10 kekurangan** infrastruktur, diurutkan dari yang
  paling menentukan.
- `inventory/network-map.md` §5A — **jalur akses admin lewat Cloudflare Zero Trust**
  (WARP, `100.96.0.4` → rute `192.168.18.0/24`). Dipastikan **connector-nya bukan di
  `proxmox`** (`cloudflared`/`warp-svc`/`tailscaled`/`zerotier` semuanya inactive) —
  lokasinya masih perlu dikonfirmasi dari dashboard Cloudflare.
- `inventory/proxmox-nodes/proxmox.md` §2.1–§2.5 — **data BMC in-band** (`ipmitool`
  lewat `/dev/ipmi0`, tanpa kredensial lewat jaringan): **serial board asli
  `ZM253S601908`** (DMI hanya `0123456789`), tanggal produksi board 2025-03-29,
  konfirmasi **2 PSU terpasang**, sensor suhu (CPU 54 °C, kedua Tesla T4 47–48 °C),
  status fan, dan System Event Log.
- **Temuan pada `PROXMOX-2U`** — SEL mencatat `Unrecoverable IDE device failure`
  **berulang** (10 dari 15 entri terakhir), terakhir tepat pada boot 2026-09-02
  02:08:14. Belum berdampak (pool ONLINE, SMART semua PASSED) tapi perlu ditelusuri.
  Juga: hanya **2 dari 7 slot fan** yang memberi pembacaan.
- `README.md` §2 — **arsitektur ditulis ulang total**, dipisah menjadi
  **§2.1 keadaan sekarang** dan **§2.2 arsitektur target: `PROXMOX-2U` sebagai
  *ingress data***. Dilengkapi diagram ASCII + Mermaid, kontrak alur data 7 tahap
  (§2.3), pembagian peran node (§2.4), dan daftar pekerjaan menuju target (§2.5).
  Diagram lama yang memakai node karangan (`login-01`, `hpc-node-01..NN`,
  `storage-node-01`) **dihapus** dan diganti dengan tiga server yang sungguh ada.
- `inventory/network-map.md` §2.2 — **rencana teknis menyambungkan `PROXMOX-2U`
  ke jalur data 10 GbE** (`192.168.30.4`, MTU 9000): tabel kelayakan, langkah
  penerapan, dan uji jumbo frame. Kelayakan slot **sudah diverifikasi** —
  `dmidecode -t slot` menunjukkan 5 slot PCIe kosong di proxmox
  (`CPU SLOT1/3/5` x16, `CPU SLOT2/4` x8).
- `inventory/storage-nodes/t4-storage.md` — **pendataan `T4-Storage`**, server ketiga
  yang sebelumnya sama sekali belum terdata. Supermicro H12SSL-i, 128 thread,
  128 GB RAM, Ubuntu 22.04.5, **41 disk fisik / ± 424,6 TB raw** (array mdadm
  `md126` ± 80 TB & `md127` ± 96 TB, plus ZFS `bio-pool` 21,7 TB), BMC di
  `192.168.18.200`. Merangkap sebagai **server monitoring** (Prometheus 2.52.0 +
  Grafana 12.1.1). Mencakup 20 temuan Known Issues terprioritas.
  ⚠️ Dikumpulkan **jarak jauh tanpa SSH** — lewat `node_exporter`, `smartctl_exporter`,
  `showmount`, fingerprint TLS, dan tabel ARP; §10 mendaftar apa yang masih kosong.
- **Temuan kritis pada `T4-Storage`** — `/dev/sdj` (Seagate BarraCuda `ST8000DM004`,
  serial `ZR15WNCX`) berstatus **SMART FAILED**: 258.448 reallocated sector
  (ambang 10), 3.608 pending, 3.608 offline-uncorrectable. Node juga memakai
  **14 disk SMR desktop di array paritas**.
- Dokumentasi **switch Zyxel `192.168.18.250`** di `inventory/network-map.md` §5.1 —
  pembawa jalur SFP+ 10 GbE antara `T4-Storage` dan `HPC-GPU`, beserta topologinya.
- `inventory/hpc-nodes/hpc-gpu.md` §2.1–§2.5 — **data dari BMC** (in-band `ipmitool`,
  tanpa mengirim kredensial IPMI lewat jaringan): identitas chassis dari FRU,
  daftar akun BMC, status chassis & daya, sensor suhu/fan, dan System Event Log.
  Menemukan **serial board asli `BR80H7011500014`** yang di DMI masih kosong.
- **Temuan kritis pada `HPC-GPU`** (§13 no. 1–3): 1.045 event Correctable ECC dari
  satu sensor memori antara 2026-06-27 dan 2026-07-09 dengan laju meningkat;
  SEL BMC penuh & overflow sejak 2026-07-09 sehingga event hardware berhenti
  tercatat ± 7 minggu; dan tidak ada pemantauan ECC di sisi OS (EDAC `ce_count=0`,
  `rasdaemon`/`mcelog` inactive) sehingga tidak ada mekanisme peringatan sama sekali.
  Langkah perbaikan terlampir di §2.5.
- `inventory/hpc-nodes/hpc-gpu.md` — **pendataan node komputasi**.
  ASRockRack ROME2D32GM-2T, 2× AMD EPYC 7763 (128C/256T), RAM 1 TB DDR4 ECC
  (16 channel terisi penuh), 2× NVIDIA A100-SXM4-40GB + 1× RTX 5060 Ti,
  scratch RAID0 4× NVMe 3.5 TB, Ubuntu 24.04.4 LTS. Terdaftar di Slurm cluster
  `bioinfo` sebagai `compute001`. Mencakup 25 temuan Known Issues terprioritas.
  Data dikumpulkan otomatis via SSH pada 2026-08-28.
- `scripts/collect-hpc.sh` — kolektor inventaris node HPC (Ubuntu bare-metal),
  seluruhnya read-only: GPU (`nvidia-smi`), Slurm, mdadm/NVMe + wear indicator,
  mount NFS, stack software, agen monitoring, dan hardening dasar.
- `README.md` §4.1 — daftar node yang teridentifikasi dari konfigurasi node lain
  tapi belum didata: `pipeline` (`192.168.18.194`, Slurm controller),
  `192.168.30.2` dan `192.168.18.113` (storage NFS).
- `inventory/proxmox-nodes/proxmox.md` — **pendataan node asli pertama**.
  Host Supermicro H12SSL-I / AMD EPYC 7B13 (64C/128T), RAM 256 GB DDR4-3200 ECC,
  Proxmox VE 9.2.10 di Debian 13. Mencakup 13 disk fisik lengkap dengan serial &
  status SMART, 4 ZFS pool (`zfs-storage` raidz2 11×14 TB di atas LUKS,
  `backup-pool`, `nvme-scratch`, `rpool`), konfigurasi jaringan, IPMI,
  2 VM (`dev-pipeline`, `dev-bioinfo`), dan 18 temuan Known Issues terprioritas.
  Data dikumpulkan otomatis via SSH pada 2026-08-28.
- `docs/penginputan-node.md` — panduan penginputan node: alur 6 langkah dari
  pengumpulan data sampai Pull Request, peta output kolektor ke bagian dokumen,
  daftar field yang wajib disurvei fisik, dan cara menyusun Known Issues.
- `scripts/collect-proxmox.sh` — kolektor inventaris Proxmox, seluruhnya read-only,
  bisa dijalankan via SSH (`<host> [user] [key]`) atau langsung di host (`--local`).
- `inventory/_templates/README.md` — penjelasan bahwa isi folder template adalah
  contoh, bukan server nyata, beserta cara menyalinnya.

### Changed
- **Template contoh dipisahkan dari data asli.** Tiga dokumen contoh dipindah
  (isi tidak diubah sama sekali):
  - `inventory/hpc-nodes/hpc-node-01.md` → `inventory/_templates/hpc-node.template.md`
  - `inventory/storage-nodes/storage-node-01.md` → `inventory/_templates/storage-node.template.md`
  - `inventory/proxmox-nodes/proxmox-node-01.md` → `inventory/_templates/proxmox-node.template.md`
- `README.md` §4 — tabel Index Node kini hanya memuat node yang benar-benar ada
  (`proxmox`), dengan catatan bahwa arsitektur di §2–§3 masih berupa desain target.
- `README.md` §5 — struktur repository diperbarui: `inventory/_templates/`,
  `scripts/`, `docs/penginputan-node.md`.
- `README.md` §7.1 — tabel prefix gambar ditambah baris `docs/` dan `inventory/_templates/`.
- `README.md` §8 — prosedur menambah node mengarah ke kolektor dan folder template.
- Konvensi penamaan file node: memakai **hostname asli** (`proxmox.md`),
  bukan nomor urut (`proxmox-node-01.md`).

### Deprecated
- *(belum ada)*

### Removed
- *(belum ada)*

### Fixed
- **Koreksi: Ubuntu 24.04 ternyata DIDUKUNG SMRT Link v26.2.** Kekhawatiran yang
  dicatat sebelumnya (`KI-V07`) tidak terbukti — dokumen resmi halaman 5
  mencantumkan Rocky 9/10 dan **Ubuntu 22.04 & 24.04**. Tidak perlu install ulang.
- **Koreksi aturan firewall segmen Vega.** Versi awal memblokir seluruh
  `192.168.18.0/24` sementara DNS instrumen justru diarahkan ke `192.168.18.1` —
  akibatnya `ping` ke IP jalan tapi semua nama domain mati. Ditambahkan izin
  sesempit mungkin (satu alamat, port 53 saja) **di atas** aturan blok; seluruh
  BMC tetap tertutup dari segmen instrumen.
- Aturan DNAT `8443 -> 192.168.50.10:443` **dihapus** — dipasang spekulatif
  sebelum dokumen vendor tersedia, dan ternyata tidak dipakai SMRT Link.
- `inventory/proxmox-nodes/proxmox.md` — diselaraskan dengan keadaan setelah
  perubahan: §3.3 (`nic1` kini slave `vmbr1`, baris `vmbr1` ditambahkan), §7.3
  (storage `vm-hdd` & `pve-backup`, plus catatan bahwa `vega-storage` kini jadi
  sisa yang bisa dihapus), §8.1 (VM 300 diganti VM 101), §8.3 (alokasi jadi
  80 vCPU dari 128), dan §12 (temuan #9 **selesai**, temuan #1 sebagian tertangani).
  Blok header yang sebelumnya tersela catatan VM 300 juga dirapikan.
- `inventory/network-map.md` §3 — **koreksi enam kesimpulan discovery 2026-08-28
  yang terbukti keliru**: `192.168.18.200` bukan "server web/aplikasi" melainkan
  **BMC Supermicro milik `T4-Storage`**; `192.168.18.250` bukan "appliance/printer"
  melainkan **switch Zyxel** pembawa jalur SFP+; `192.168.18.193:9090` bukan
  Cockpit melainkan **Prometheus**; `192.168.18.113` bukan host hilang melainkan
  **IP lama `T4-Storage`**; dan perubahan host key di `.200` bukan tanda mesin
  di-install ulang, melainkan karena SSH itu milik BMC, bukan OS.
- `inventory/hpc-nodes/hpc-gpu.md` §7.2 — **penyebab mount `/mnt/t4-storage` gagal
  ditemukan**: `/etc/fstab` menunjuk `192.168.18.113` sedangkan export
  `/media/t4/96-Storage` kini dilayani dari `192.168.18.193`. Perintah perbaikan disertakan.
- `inventory/hpc-nodes/hpc-gpu.md` §14 — dua dari tiga "node terkait yang belum didata"
  ternyata **satu host yang sama** (`T4-Storage`), bukan host terpisah.
- `inventory/proxmox-nodes/proxmox.md` — ditandai bahwa **VM 300 `vega` sudah dihapus**
  (`qmdestroy:300` pada 2026-09-02 02:29:45), sehingga seluruh bagian bertanda 🆕
  tentang VM tersebut kini usang. Angka `nvme-scratch` dikoreksi 12.9 G → **6.17 G**.
- `README.md` §4 — index node dilengkapi **kolom IPMI/BMC** dan ketiga server yang
  benar-benar menyala, ditambah diagram topologi ringkas.

### Security
- 🔴 **`T4-Storage` — kredensial IPMI BMC (`192.168.18.200`) bocor dalam bentuk
  plaintext** di konfigurasi `ipmi_exporter`, terbaca lewat Prometheus `:9090`
  yang **terbuka tanpa autentikasi** dari seluruh LAN server.
  **Kredensialnya sengaja tidak ditulis di repo ini.** Wajib dirotasi, lalu
  dipindah ke file kredensial `ipmi_exporter` ber-permission `0600` — bukan
  parameter URL. Lihat `t4-storage.md` `KI-T02`.
- 🔴 **Monitoring seluruh fleet tidak berfungsi** — keempat job Prometheus masih
  menunjuk IP lama `192.168.18.113` dan berstatus `down`, sehingga tidak ada alarm
  yang berbunyi. Inilah sebabnya disk `/dev/sdj` yang SMART FAILED tidak ketahuan.
- 🔴 **Password admin switch Zyxel masih default pabrik** — terkonfirmasi bisa
  login. Pemegang switch dapat menyadap seluruh trafik lewat port mirroring,
  memindahkan VLAN, atau memutus seluruh jaringan. **Wajib diganti.**
- 🔴 **Switch Zyxel tidak punya satu pun jalur manajemen terenkripsi** — hanya
  Telnet (`23`) dan HTTP (`80`), keduanya plaintext; tanpa SSH, tanpa HTTPS.
  Login web bahkan POST polos ke `/goform/SetLogin` tanpa hashing maupun token
  CSRF, jadi mengganti password saja tidak cukup — kredensial barunya tetap bisa
  disadap dari LAN.
- 🟠 **Firmware switch `V1.06(ABGV.0)b1` compiled 2019-08-07** (± 7 tahun) —
  perlu dicek CVE untuk MGS3520.
- ✅ **SNMP switch ternyata aman** — port `161/udp` merespons probe, tapi
  `show snmp community` **kosong**, jadi tidak ada data yang bisa ditarik tanpa
  autentikasi. Lebih baik daripada dugaan awal.
- 🟠 **Perangkat tak dikenal `50:e9:71:03:26:8a`** berbagi port `e0/0/1` dengan ONT —
  ada host tak teridentifikasi di segmen yang sama dengan seluruh server dan BMC.
- 🔴 **Seluruh infrastruktur bergantung pada satu switch tanpa redundansi** —
  internet, LAN server, jalur data 10 GbE, dan ketiga BMC semuanya lewat
  `192.168.18.250`. Switch mati = semuanya mati serentak.
- 🔴 **Ketiga BMC (`.13`, `.119`, `.200`) satu segmen dengan LAN data**, satu hop di
  belakang ONT yang dikelola ISP. Belum diverifikasi apakah ONT punya port-forward,
  UPnP, atau DMZ yang bisa mengekspos port `623`/`5900` ke internet — checklist
  auditnya di `ont-huawei.md` §5.
- Terdokumentasi dari pendataan `proxmox` (belum ditindaklanjuti, lihat §12 dokumen node):
  firewall Proxmox belum aktif, IPMI satu segmen dengan jaringan data via DHCP,
  SNMP BMC masih community `public`, `PermitRootLogin yes`, hanya ada `root@pam`
  tanpa 2FA, dan **VM belum punya backup sama sekali**.
- `scripts/collect-proxmox.sh` sengaja tidak pernah mencetak password, private key,
  passphrase LUKS, maupun isi berkas kredensial.

---

## [1.0.0] — 2026-08-28

Rilis awal dokumentasi infrastruktur bioinformatics bare-metal.

### Added
- `README.md` — overview infrastruktur, diagram arsitektur (ASCII + Mermaid),
  tabel mapping path storage (`/scratch`, `/mnt/storage`, `/home`, `/opt`),
  index node, tata cara update repo, dan panduan pemanggilan gambar.
- `.gitignore` — rule khusus sysadmin & bioinformatics: memblokir data sekuens
  (`*.fastq`, `*.bam`, `*.sam`, `*.vcf`, `*.cram`), container image (`*.sif`),
  kredensial (`*.key`, `*.pem`, `.env`), dan log (`*.log`, `slurm-*.out`).
- `CHANGELOG.md` — dokumen ini, format Keep a Changelog.
- `inventory/hpc-nodes/hpc-node-01.md` — template detail node compute bare-metal:
  identitas aset, posisi rak/RU, IPMI/iDRAC, CPU socket/core/thread, layout RAM,
  GPU + VRAM, NVMe scratch lokal, partisi Slurm, daftar Conda env & Singularity image.
- `inventory/storage-nodes/storage-node-01.md` — template node storage bare-metal:
  topologi ZFS/RAID, tabel disk per-slot, kapasitas raw vs usable, status SMART,
  mount point, export NFS/SMB, kebijakan snapshot & scrub.
- `inventory/proxmox-nodes/proxmox-node-01.md` — template host Proxmox VE bare-metal:
  network bridge & VLAN, ZFS datastore lokal, tabel VM/LXC aktif beserta IP
  dan alokasi resource, kebijakan backup.
- `track-record/maintenance-log.md` — form laporan maintenance dengan checklist
  pre/post, estimasi downtime, rollback plan, dan PIC.
- `track-record/server-changelog.md` — log perubahan infrastruktur permanen
  (hardware, OS, kernel, firewall/network).
- `docs/sop/sop-bioinformatics-execution.md` — SOP eksekusi bioinformatics:
  pre-flight check (ruang storage ≥ 3× input, pemisahan scratch, pencegahan OOM),
  standar eksekusi (larangan run di SSH root, wajib Slurm/tmux, isolasi
  Conda/Singularity), batas resource (CPU 80–90%, monitoring I/O), dan housekeeping.
- `assets/images/README.md` — standar penamaan file gambar dan cara memanggilnya
  di Markdown dari berbagai kedalaman direktori.
- Struktur direktori `assets/images/{racks,diagrams,screenshots}/` dengan `.gitkeep`.

### Security
- `.gitignore` memblokir seluruh pola kredensial umum (`id_rsa*`, `*.pem`, `*.p12`,
  `.env`, `ipmi-*.conf`) sejak commit pertama.
- Ditetapkan aturan: kredensial IPMI/iDRAC **tidak pernah** ditulis di repo,
  hanya direferensikan ke password manager.

---

<!--
=============================================================================
 TEMPLATE ENTRI BARU — copy blok di bawah ini saat membuat rilis versi baru.
 Letakkan versi terbaru di ATAS (urutan menurun).
=============================================================================

## [X.Y.Z] — YYYY-MM-DD

Ringkasan 1–2 kalimat tentang fokus rilis ini.

### Added
- ...

### Changed
- ...

### Deprecated
- ...

### Removed
- ...

### Fixed
- ...

### Security
- ...

=============================================================================
 CONTOH ENTRI TERISI (untuk referensi gaya penulisan):

## [1.1.0] — 2026-09-15

Penambahan node compute ketiga dan pengetatan SOP housekeeping.

### Added
- `inventory/hpc-nodes/hpc-node-03.md` — node compute baru, 2x AMD EPYC 9554,
  RAM 1 TB, tanpa GPU, NVMe scratch 15 TB, masuk partisi `bigmem`.
- `assets/images/racks/hpc-node-03-rack.png` — foto posisi RU 20-21 Rak B02.
- Section "Prosedur Purge Otomatis /scratch" pada SOP eksekusi.

### Changed
- `README.md` — tabel index node diperbarui dengan `hpc-node-03`.
- `docs/sop/sop-bioinformatics-execution.md` — batas CPU diturunkan dari 90%
  menjadi 85% pada node dengan NFS client aktif, karena `nfsd` kelaparan CPU
  saat semua core dipakai job.

### Fixed
- `inventory/proxmox-nodes/proxmox-node-01.md` — koreksi IP VM `db-postgres`
  dari `10.10.20.45` menjadi `10.10.20.46`.

### Security
- Rotasi seluruh password IPMI setelah pergantian PIC sysadmin;
  dokumen hanya menyimpan referensi ke entri Vaultwarden.
=============================================================================
-->

[Unreleased]: https://github.com/<org-anda>/server-infrastructure/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/<org-anda>/server-infrastructure/releases/tag/v1.0.0

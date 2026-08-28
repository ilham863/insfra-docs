# Peta Jaringan & Hasil Discovery On-Premise

> **Terakhir Diperbarui:** 2026-08-28
> **Metode:** scan aktif dari laptop admin (`192.168.0.121`) — ping/TCP probe ke
> port 22, 80, 443, 445, 2049, 5000, 8006, 9090 di `192.168.0.0/24` dan
> `192.168.18.0/24`, lalu identifikasi versi SSH.
> **Cakupan:** server Linux/Unix. Perangkat Windows, jaringan, dan daya **tidak** didata.

> ⚠️ **Dokumen ini adalah hasil pemindaian, bukan sumber kebenaran.**
> Peran yang ditandai *(dugaan)* disimpulkan dari port yang terbuka, belum
> dikonfirmasi dari dalam mesin. Konfirmasi lewat pendataan per-node
> ([`docs/penginputan-node.md`](../docs/penginputan-node.md)).

---

## 1. Segmen Jaringan

| Segmen | Fungsi | Keterangan |
|---|---|---|
| `192.168.0.0/24` | **LAN klien / kantor** | Laptop admin (`.121`), printer, workstation Windows. **Tidak ada server Linux.** |
| `192.168.18.0/24` | **LAN server + IPMI** | Semua server dan seluruh BMC ada di sini — ⚠️ tidak dipisah VLAN |
| `192.168.30.0/24` | **Jalur data storage** | 10 GbE, MTU 9000. **Tidak terjangkau dari LAN klien** — hanya dari host yang punya kaki di sana |
| `100.64.0.0/10` | **Tailscale** | Laptop admin `100.96.0.4`; `HPC-GPU` juga tersambung |

> ⚠️ **IPMI/BMC satu segmen dengan jaringan data** (`192.168.18.0/24`).
> [README §2](../README.md#2-arsitektur-umum) mendesain IPMI di VLAN 30 terpisah.
> Keadaan sekarang belum sesuai desain itu.

---

## 2. Server Linux — Sudah Didata

| IP | Hostname | Peran | Dokumentasi |
|---|---|---|---|
| `192.168.18.178` | `HPC-GPU` | Compute node, 2× A100, Slurm `compute001` | [hpc-nodes/hpc-gpu.md](hpc-nodes/hpc-gpu.md) |
| `192.168.18.190` | `proxmox` | Hypervisor PVE 9.2 + arsip ZFS 140 TB | [proxmox-nodes/proxmox.md](proxmox-nodes/proxmox.md) |

Jalur data kedua node di `192.168.30.0/24`:

| Node | IP data | Link |
|---|---|---|
| `HPC-GPU` | `192.168.30.3` | 10 GbE, MTU 9000 |
| `proxmox` | *(tidak punya kaki di segmen ini)* | — |

---

## 3. Server Linux — Belum Didata

Prioritas pendataan berikutnya.

| IP | SSH | Port lain | Peran (dugaan) | Status akses |
|---|---|---|---|---|
| **`192.168.18.193`** | `OpenSSH_8.9p1 Ubuntu-3ubuntu0.16` → **Ubuntu 22.04** | **2049 (NFS)**, 445 (SMB), 9090 (Cockpit) | **Server storage** — melayani NFS & SMB | 🔑 butuh kredensial |
| **`192.168.18.194`** | *(tidak terbaca)* | — | **`pipeline`** — Slurm controller (`slurmctld`) cluster `bioinfo` | 🔴 port 22 timeout saat dicoba |
| **`192.168.18.200`** | `OpenSSH_9.8` | 443, 80 | Server web/aplikasi | 🔑 butuh kredensial · ⚠️ host key berubah |

### 3.1 Catatan per host

**`192.168.18.193` — kandidat kuat storage utama**

Kombinasi NFS (2049) + SMB (445) + Cockpit (9090) menunjukkan ini server storage.
**Dugaan yang perlu diverifikasi:** host ini kemungkinan **sama** dengan
`192.168.30.2` yang di-mount `HPC-GPU` sebagai `/bio-pool` (20 TB) — yaitu satu
mesin dengan dua NIC (`.18.193` untuk manajemen, `.30.2` untuk data 10 GbE),
pola yang sama persis dengan `HPC-GPU`. Cara memastikan: cek `ip -br address`
dari dalam mesin.

**`192.168.18.194` — `pipeline`, Slurm controller**

Diketahui dari `slurm.conf` di `HPC-GPU`:
`SlurmctldHost=pipeline(192.168.18.194)`. Port 22 terdeteksi terbuka saat
pemindaian, tapi koneksi berikutnya **timeout**. Dugaan: fail2ban / rate-limit
terpicu oleh pemindaian. Perlu dicek dari konsol atau setelah jeda.

Node ini **kritis** — kalau `slurmctld` mati, seluruh penjadwalan cluster berhenti.

**`192.168.18.200` — host key berubah**

Kunci host yang tersimpan di `known_hosts` admin **tidak cocok** dengan yang
sekarang:

| | Kunci |
|---|---|
| Tersimpan | `ssh-ed25519 AAAAC3...IL6WvL9ZFJmYT6L3` · `ssh-rsa AAAAB3...AAABgQC0nyHr5W02` · `ecdsa-sha2-nistp256` |
| Sekarang | `ssh-rsa AAAAB3...AAABAQClRpnhY0Mg` (hanya RSA yang ditawarkan) |

Kemungkinan: mesin di-install ulang, atau IP tersebut kini dipakai perangkat lain.
**Harus dipastikan sebelum menerima kunci baru** — jangan langsung `accept-new`.

---

## 4. BMC / IPMI

Bukan server terpisah — modul manajemen dari server di §2.

| IP | Milik | Tipe | Web UI | Catatan |
|---|---|---|---|---|
| `192.168.18.13` | `proxmox` | Supermicro BMC | 80, 443 | ⚠️ DHCP, SNMP `public` |
| `192.168.18.119` | `HPC-GPU` | ASRock Rack BMC (AMI) | 443 | ⚠️ SNMP `AMI`, tanpa lockout brute-force |

---

## 5. Host Lain yang Terdeteksi

Di luar cakupan pendataan (bukan server Linux), dicatat untuk kelengkapan peta.

| IP | Port | Dugaan |
|---|---|---|
| `192.168.18.1` | 80 | Gateway / router segmen server |
| `192.168.18.166` | 445 | Host SMB — kemungkinan Windows atau NAS |
| `192.168.18.250` | 80 | Appliance / printer |
| `192.168.0.1` | 22 (`OpenSSH_6.6.0`), 80, 443 | Gateway / router segmen klien — ⚠️ OpenSSH sangat tua |
| `192.168.0.100`, `.101` | 80 | Appliance / printer |
| `192.168.0.109`, `.129` | 445 | Workstation Windows |
| `192.168.0.121` | 445 | Laptop admin (mesin tempat scan dijalankan) |

---

## 6. Referensi Silang yang Belum Cocok

Path yang disebut konfigurasi node tapi belum ketemu host-nya:

| Referensi | Disebut di | Status |
|---|---|---|
| `192.168.18.113:/media/t4/96-Storage` | `/etc/fstab` di `HPC-GPU` | 🔴 host **tidak merespons** sama sekali saat pemindaian; mount unit `failed` |
| `192.168.30.2:/media/t4/NVME-3.6TB` | `/etc/fstab` di `HPC-GPU` | 🔴 mount unit `failed` — segmen tidak terjangkau dari LAN klien |
| `192.168.30.2:/bio-pool` | mount aktif di `HPC-GPU` | 🟢 aktif — diduga = `192.168.18.193` |

---

## 7. Cara Mengulang Discovery

```bash
# Host dengan SSH terbuka
for n in $(seq 1 254); do
  ip=192.168.18.$n
  timeout 1 bash -c "echo > /dev/tcp/$ip/22" 2>/dev/null && echo "$ip"
done

# Identifikasi versi SSH (menandai distro)
ssh -vv -o BatchMode=yes -o PreferredAuthentications=none nobody@<ip> exit 2>&1 |
  grep 'remote software version'
```

Segmen `192.168.30.0/24` hanya bisa dipindai **dari** host yang punya kaki di sana
(`HPC-GPU`), bukan dari laptop admin.

---

## 8. Tindak Lanjut

1. Dapatkan kredensial untuk `192.168.18.193`, `.194`, `.200`, lalu data dengan
   `scripts/collect-hpc.sh` (server umum) atau kolektor storage bila sudah ada.
2. Pastikan penyebab `192.168.18.194` timeout — node ini menjalankan `slurmctld`.
3. Verifikasi perubahan host key `192.168.18.200` sebelum menerima kunci baru.
4. Telusuri nasib `192.168.18.113` — masih ada atau sudah dimatikan? Kalau sudah,
   bersihkan entri `/etc/fstab` di `HPC-GPU` yang menyebabkan mount unit `failed`.
5. Pindai `192.168.30.0/24` dari `HPC-GPU` untuk melengkapi peta jalur data.

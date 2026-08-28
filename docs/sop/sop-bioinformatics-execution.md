# SOP — Eksekusi Workload Bioinformatics

| Field | Isi |
|---|---|
| **Nomor Dokumen** | `SOP-BIO-EXEC-001` |
| **Versi** | `1.0.0` |
| **Tanggal Berlaku** | `2026-08-28` |
| **Tinjauan Berikutnya** | `2027-02-28` (6 bulan) |
| **Pemilik Dokumen** | Sysadmin HPC |
| **Berlaku Untuk** | Seluruh pengguna cluster bioinformatics |
| **Status** | 🟢 Aktif |

> **SOP ini bersifat WAJIB.** Pelanggaran dapat menyebabkan job dihentikan paksa
> tanpa peringatan, dan pelanggaran berulang dapat berakibat penangguhan akses.
> Alasannya sederhana: cluster ini dipakai bersama, dan satu job yang tidak
> disiplin dapat menjatuhkan node yang sedang menjalankan pekerjaan orang lain
> selama berhari-hari.

---

## Daftar Isi

1. [Ruang Lingkup & Definisi](#1-ruang-lingkup--definisi)
2. [Pre-Flight Check](#2-pre-flight-check)
3. [Standar Eksekusi (Running Standards)](#3-standar-eksekusi-running-standards)
4. [Batas Resource](#4-batas-resource)
5. [Housekeeping](#5-housekeeping)
6. [Checklist Ringkas](#6-checklist-ringkas)
7. [Pelanggaran & Sanksi](#7-pelanggaran--sanksi)
8. [Eskalasi & Kontak](#8-eskalasi--kontak)
9. [Lampiran](#9-lampiran)

---

## 1. Ruang Lingkup & Definisi

### 1.1 Ruang Lingkup

SOP ini mengatur cara menjalankan seluruh analisis bioinformatics di cluster:
alignment, variant calling, assembly, RNA-Seq, metagenomics, single-cell,
dan basecalling.

### 1.2 Istilah

| Istilah | Arti |
|---|---|
| **Login node** | `login-01` — tempat submit job, **bukan** tempat menjalankan analisis |
| **Compute node** | `hpc-node-01`, `hpc-node-02`, ... — tempat job berjalan, hanya via Slurm |
| **Scratch** | `/scratch` — NVMe lokal, sangat cepat, **tidak dibackup**, auto-purge 14 hari |
| **Main storage** | `/mnt/storage` — NFS dari `storage-node-01`, persisten, ada snapshot |
| **Stage-in** | Menyalin data input dari `/mnt/storage` ke `/scratch` sebelum proses |
| **Stage-out** | Menyalin hasil final dari `/scratch` ke `/mnt/storage` setelah proses |
| **OOM Killer** | Mekanisme kernel yang membunuh proses saat RAM habis |
| **I/O bottleneck** | Kondisi saat CPU menganggur menunggu disk/jaringan |

### 1.3 Prinsip Dasar

1. **Compute cepat, storage lambat.** Jangan pernah memaksa storage arsip
   melayani beban acak berkecepatan tinggi.
2. **Setiap job punya batas.** Job tanpa batas eksplisit adalah job yang akan
   menjatuhkan node.
3. **Reproduktibilitas bukan opsional.** Versi tool dikunci, environment diisolasi.
4. **Bersihkan setelah selesai.** Storage bersama hanya berfungsi jika semua
   orang membereskan miliknya.

---

## 2. Pre-Flight Check

> **Wajib dilakukan sebelum submit job.** Lima menit di sini menghemat
> berjam-jam job gagal dan storage penuh.

### 2.1 Cek Ruang Storage — Aturan Minimal 3× Input

Pipeline bioinformatics menghasilkan file intermediate yang jauh lebih besar
dari inputnya. Sebagai contoh nyata untuk sampel WGS 30× manusia:

| Tahap | File | Ukuran Tipikal | Rasio terhadap Input |
|---|---|---|---|
| Input | `sample_R1.fastq.gz` + `sample_R2.fastq.gz` | 60 GB | 1.0× |
| Dekompresi (jika perlu) | `.fastq` | 200 GB | 3.3× |
| Alignment | `sample.sam` | **380 GB** | **6.3×** |
| Konversi | `sample.bam` | 95 GB | 1.6× |
| Sort | `sample.sorted.bam` (+ file sementara sort) | 95 GB + 100 GB temp | 3.2× |
| Mark duplicates | `sample.markdup.bam` | 98 GB | 1.6× |
| BQSR | `sample.recal.bam` | 98 GB | 1.6× |
| Variant | `sample.g.vcf.gz` | 8 GB | 0.13× |
| **Puncak pemakaian bersamaan** | | **± 480 GB** | **± 8×** |

**Aturan yang berlaku di cluster ini:**

> **Sediakan ruang bebas di `/scratch` minimal 3× ukuran total input
> untuk pipeline sederhana, dan 8× untuk pipeline WGS penuh.**
> Jika ragu, hitung dengan rumus di bawah dan lebihkan.

**Rumus perencanaan:**

```
Ruang dibutuhkan = (Ukuran input × Faktor pipeline) + Buffer 20%

Faktor pipeline:
  - QC / trimming saja              : 3×
  - Alignment → BAM (dengan cleanup): 5×
  - WGS lengkap (align→variant)     : 8×
  - Assembly de-novo                : 10–15×
  - RNA-Seq (STAR + quantifikasi)   : 6×
  - Metagenomics (Kraken2)          : 4×
```

**Perintah cek (jalankan semuanya sebelum submit):**

```bash
# 1. Ruang bebas di scratch
df -h /scratch

# 2. Kuota pribadi di scratch
xfs_quota -c "quota -h $USER" /scratch

# 3. Ukuran total input
du -sh /mnt/storage/raw/proyek-A/
du -ch /mnt/storage/raw/proyek-A/*.fastq.gz | tail -1

# 4. Ruang di storage tujuan
df -h /mnt/storage

# 5. Kesehatan pool storage (jika penuh > 80%, hubungi sysadmin sebelum submit)
ssh storage-node-01 'zpool list tank'
```

**Script pre-flight otomatis** (tersedia di `/opt/scripts/preflight-check.sh`,
teks lengkap ada di [Lampiran A](#lampiran-a--script-pre-flight-check)):

```bash
/opt/scripts/preflight-check.sh /mnt/storage/raw/proyek-A 8
# argumen 1: direktori input
# argumen 2: faktor pipeline (default 3)
```

**Ambang keputusan:**

| Kondisi `/scratch` | Tindakan |
|---|---|
| Bebas ≥ kebutuhan × 1.2 | ✅ Lanjut submit |
| Bebas antara kebutuhan × 1.0–1.2 | ⚠️ Lanjut, tapi pantau ketat; kurangi jumlah job paralel |
| Bebas < kebutuhan | ❌ **Jangan submit.** Bersihkan scratch dulu atau tunggu job lain selesai |
| `/scratch` terpakai > 88% | ❌ **Jangan submit apa pun.** Hubungi sysadmin |
| `/mnt/storage` terpakai > 80% | ❌ Hubungi sysadmin sebelum menulis hasil |

### 2.2 Pemisahan NVMe Scratch vs Main Storage

Ini adalah aturan tunggal yang paling sering dilanggar dan paling merusak.

**Yang harus di `/scratch` (NVMe lokal):**
- Semua file intermediate (`.sam`, BAM belum di-sort, file temp sorter)
- `TMPDIR` untuk seluruh tool
- File yang dibaca/ditulis berulang kali
- Index sementara
- Direktori kerja Nextflow/Snakemake (`work/`, `.nextflow/`)

**Yang harus di `/mnt/storage` (NFS):**
- Data mentah asli (`raw/`) — **read-only**
- Hasil final yang sudah dikompres (`.cram`, `.vcf.gz`)
- Laporan QC (MultiQC HTML)
- Genom referensi dan index yang dipakai bersama (`reference/`, read-only)
- Script pipeline dan file konfigurasi

**Yang TIDAK BOLEH di mana pun:**
- File `.sam` yang disimpan permanen
- Data apa pun di `/tmp` (itu tmpfs/RAM — akan memicu OOM)
- File besar di `/home` (quota kecil, dan NFS `/home` dipakai semua orang)

**Pola kerja yang benar:**

```bash
# ---------- STAGE-IN ----------
WORKDIR="/scratch/$USER/$SLURM_JOB_ID"
mkdir -p "$WORKDIR/tmp"
export TMPDIR="$WORKDIR/tmp"

# Salin input ke scratch (bukan symlink — symlink tetap membaca lewat NFS)
cp /mnt/storage/raw/proyek-A/sample_R1.fastq.gz "$WORKDIR/"
cp /mnt/storage/raw/proyek-A/sample_R2.fastq.gz "$WORKDIR/"

# Referensi BOLEH di-symlink karena dibaca sekali dan di-cache ARC storage
ln -s /mnt/storage/reference/GRCh38/GRCh38.fa "$WORKDIR/ref.fa"

cd "$WORKDIR"

# ---------- PROSES (semua di scratch) ----------
# ... jalankan pipeline ...

# ---------- STAGE-OUT ----------
OUT="/mnt/storage/projects/proyek-A/$SLURM_JOB_ID"
mkdir -p "$OUT"
cp sample.cram sample.cram.crai sample.vcf.gz sample.vcf.gz.tbi "$OUT/"
cp -r qc_reports "$OUT/"

# ---------- CLEANUP ----------
cd /
rm -rf "$WORKDIR"
```

**Cara memverifikasi bahwa Anda benar-benar menulis ke scratch:**

```bash
# Pastikan direktori kerja ada di /dev/md1, bukan NFS
df -h .
findmnt -T "$PWD"

# Jika keluarannya menampilkan 10.10.20.50:/tank/... berarti Anda di NFS — SALAH
```

**Kenapa ini penting:**

Menjalankan `bwa mem | samtools sort` langsung ke NFS menghasilkan jutaan
operasi tulis kecil melalui jaringan. Efeknya bukan hanya job Anda yang lambat —
seluruh cluster ikut melambat karena `nfsd` di `storage-node-01` kehabisan thread.
Satu job yang salah tempat pernah membuat throughput cluster turun 70% selama 9 jam.

### 2.3 Pencegahan OOM Killer

OOM Killer membunuh proses saat RAM node habis. Masalahnya, kernel tidak selalu
membunuh proses yang bersalah — ia bisa membunuh `slurmd`, `nfsd`, atau bahkan
membuat node tidak responsif sepenuhnya.

**Langkah pencegahan wajib:**

**a. Ketahui kebutuhan RAM tool yang Anda pakai**

| Tool | Kebutuhan RAM Tipikal | Catatan |
|---|---|---|
| `fastqc` | 1–4 GB | Per thread |
| `fastp` | 4–8 GB | — |
| `bwa mem` | Ukuran index + 2 GB (± 8 GB untuk GRCh38) | Naik sedikit per thread |
| `bwa-mem2` | **± 40 GB** untuk GRCh38 | Jauh lebih besar dari `bwa` |
| `samtools sort` | `-m` × jumlah thread | **Ini sumber OOM paling umum** |
| `STAR` genomeGenerate | 32–64 GB (GRCh38), > 200 GB untuk genom besar | — |
| `STAR` align | ± 32 GB (GRCh38) | Per instance |
| `GATK HaplotypeCaller` | 8–16 GB heap Java | Set `-Xmx` eksplisit |
| `SPAdes` | 250–800 GB | Sesuaikan `-m` |
| `Trinity` | ± 1 GB per 1 juta read | Bisa > 500 GB |
| `Kraken2` | Ukuran database (8–600 GB) | Database dimuat penuh ke RAM |
| `MetaPhlAn` | 16–32 GB | — |

**b. Selalu deklarasikan `--mem` di Slurm**

```bash
#SBATCH --mem=200G          # eksplisit, bukan --mem=0
```

> **Jangan pernah pakai `--mem=0`** (yang berarti "ambil seluruh RAM node").
> Itu menghapus perlindungan cgroup dan membuka jalan bagi OOM di level node.

Dengan `--mem` yang benar, cgroup Slurm akan membunuh **hanya job Anda** saat
melewati batas — node tetap sehat dan job orang lain tidak terganggu.

**c. Hitung `samtools sort` dengan benar**

Ini kesalahan klasik:
```bash
# SALAH — 32 thread × 8 GB = 256 GB, padahal --mem=64G
samtools sort -@ 32 -m 8G -o out.bam in.bam
```

Yang benar:
```bash
# Sisakan ± 20% untuk overhead
# Alokasi 64 GB → pakai maksimal 50 GB untuk sort
# 16 thread × 3G = 48 GB  ✅
samtools sort -@ 16 -m 3G -T "$TMPDIR/sort" -o out.bam in.bam
```

Rumus:
```
-m per thread  ≤  (--mem × 0.8) / jumlah thread
```

**d. Set heap Java secara eksplisit**

```bash
# SALAH — JVM akan mengira punya seluruh RAM node
gatk HaplotypeCaller ...

# BENAR
gatk --java-options "-Xmx12g -Xms12g -XX:ParallelGCThreads=4" HaplotypeCaller ...
```

**e. Jangan gunakan `/tmp`**

`/tmp` di semua compute node adalah **tmpfs (RAM)**. Menulis 50 GB ke `/tmp`
sama dengan mengonsumsi 50 GB RAM.

```bash
# WAJIB di setiap job
export TMPDIR="/scratch/$USER/$SLURM_JOB_ID/tmp"
mkdir -p "$TMPDIR"

# Beberapa tool punya variabel sendiri
export TMP="$TMPDIR"
export TEMP="$TMPDIR"
export JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=$TMPDIR"
```

**f. Uji dengan subset dulu**

Sebelum menjalankan 200 sampel, jalankan 1 sampel dan ukur pemakaian riil:

```bash
# Setelah job selesai
sacct -j <JOBID> --format=JobID,JobName,MaxRSS,MaxVMSize,Elapsed,State

# Contoh keluaran:
# JobID        JobName    MaxRSS  MaxVMSize    Elapsed      State
# 12345        wgs_test   187.4G    201.2G   06:12:44  COMPLETED
```

Gunakan `MaxRSS` nyata untuk menentukan `--mem` pada batch berikutnya
(tambahkan margin 20–30%).

**g. Pantau saat job berjalan**

```bash
# Dari login node
squeue -j <JOBID> -o "%.10i %.20j %.8T %.10M %.6D %R"

# Masuk ke node tempat job berjalan (hanya untuk memantau, bukan menjalankan apa pun)
srun --jobid=<JOBID> --pty bash
htop -u $USER
free -h

# Cek apakah pernah ada OOM di node
dmesg -T | grep -i -E 'oom|killed process' | tail -20
```

**h. Tanda-tanda job dibunuh OOM**

```
$ sacct -j 12345 --format=JobID,State,ExitCode,DerivedExitCode
JobID     State        ExitCode  DerivedExitCode
12345     OUT_OF_MEMORY  0:125     0:125

# atau di file slurm-12345.out:
slurmstepd: error: Detected 1 oom-kill event(s) in StepId=12345.batch.
Some of your processes may have been killed by the cgroup out-of-memory handler.
```

Jika ini terjadi: naikkan `--mem`, kurangi thread, atau kecilkan `-m` pada sort.
**Jangan** langsung menaikkan `--mem` ke nilai maksimum node — itu membuat job
Anda mengantre sangat lama dan memblokir pengguna lain.

### 2.4 Checklist Pre-Flight

- [ ] Ruang `/scratch` bebas ≥ (input × faktor pipeline × 1.2)
- [ ] Kuota `/scratch` pribadi mencukupi
- [ ] Ruang `/mnt/storage` tujuan mencukupi dan pool < 80%
- [ ] Input diverifikasi utuh (`md5sum` cocok dengan manifest)
- [ ] Referensi genom yang benar dipilih (GRCh38 vs GRCh37 — jangan tertukar)
- [ ] `TMPDIR` diarahkan ke scratch
- [ ] `--mem` dihitung dari `MaxRSS` uji coba, bukan tebakan
- [ ] Jumlah thread ≤ batas SOP (lihat bagian 4)
- [ ] Environment (Conda/Singularity) sudah ditentukan dan versinya dikunci
- [ ] Script sudah diuji dengan 1 sampel kecil
- [ ] Rencana cleanup sudah ada di dalam script

---

## 3. Standar Eksekusi (Running Standards)

### 3.1 DILARANG: Menjalankan Analisis di Sesi SSH Interaktif

**Aturan mutlak:**

> ❌ **Dilarang menjalankan proses komputasi apa pun langsung di sesi SSH,
> baik di login node maupun compute node, dan terutama sebagai `root`.**

**Yang dilarang:**

```bash
# ❌ SALAH — di login node
ssh login-01
bwa mem ref.fa r1.fq r2.fq > out.sam

# ❌ SALAH — SSH langsung ke compute node lalu jalankan proses
ssh hpc-node-01
STAR --runThreadN 64 ...

# ❌ SANGAT SALAH — sebagai root
sudo bwa mem ...
su - root
gatk HaplotypeCaller ...

# ❌ SALAH — nohup untuk mengakali aturan
nohup bwa mem ... &
```

**Kenapa dilarang:**

| Masalah | Akibat |
|---|---|
| Job mati saat koneksi SSH putus | Kerja berjam-jam hilang |
| Tidak ada batasan cgroup | Proses bisa memakan seluruh RAM/CPU node dan menjatuhkannya |
| Scheduler tidak tahu resource terpakai | Slurm menjadwalkan job lain ke node yang sebenarnya penuh → OOM berantai |
| Tidak ada akuntansi | Pemakaian resource tidak tercatat, tidak bisa dianalisis |
| Sebagai root | File hasil dimiliki root, user lain tidak bisa mengaksesnya; kesalahan perintah bisa merusak sistem |
| Login node kelebihan beban | Semua pengguna lain tidak bisa login atau submit job |

**Yang diizinkan di login node** (ringan, di bawah 5 menit, di bawah 2 core, di bawah 4 GB):
- Edit script (`vim`, `nano`)
- `ls`, `du`, `df`, `grep`, `head`, `tail`, `wc`
- `sbatch`, `squeue`, `sacct`, `scancel`
- Transfer file kecil (`scp`, `rsync` di bawah 5 GB)
- `md5sum` file kecil
- Menjalankan `--help` atau `--version` suatu tool

**Penegakan:** login node memiliki batas cgroup per user (4 core, 16 GB RAM)
dan proses yang berjalan lebih dari 30 menit dengan CPU > 150% akan otomatis dihentikan
serta dilaporkan ke sysadmin.

### 3.2 WAJIB: Gunakan Slurm

Semua analisis dijalankan melalui Slurm. Ada dua cara:

**a. Batch job — cara utama, gunakan ini untuk 95% pekerjaan**

```bash
sbatch pipeline.sh
```

**b. Interactive job — untuk debugging saja, maksimal 4 jam**

```bash
# Minta alokasi resource interaktif
salloc --partition=short --cpus-per-task=8 --mem=32G --time=02:00:00

# Setelah dapat alokasi, Anda berada di dalam job yang terkendali cgroup
srun --pty bash

# Sekarang boleh menjalankan perintah — resource sudah dibatasi Slurm
conda activate bio-align
bwa mem -t 8 ...

# Keluar saat selesai — JANGAN biarkan alokasi menganggur
exit
```

> ⚠️ **Jangan biarkan sesi interaktif menganggur.** Resource tetap terpakai
> dan pengguna lain mengantre. Sesi interaktif yang idle > 30 menit akan dihentikan.

### 3.3 Alternatif: Tmux / Screen (hanya untuk kasus tertentu)

Tmux/Screen dipakai untuk **menjaga sesi tetap hidup**, bukan untuk mengganti Slurm.

**Pola yang benar — tmux di login node, komputasi tetap di Slurm:**

```bash
# 1. Buat sesi tmux di login node
tmux new -s proyek-a

# 2. Di dalam tmux, jalankan orkestrator (Snakemake/Nextflow) yang
#    MENGIRIM job ke Slurm — bukan menjalankan komputasi sendiri
conda activate wf-tools
snakemake --profile slurm --jobs 50

# 3. Lepaskan sesi:  Ctrl-b lalu d
# 4. Koneksi boleh putus; orkestrator tetap jalan

# 5. Kembali nanti
tmux attach -t proyek-a

# Perintah tmux lain
tmux ls                      # daftar sesi
tmux kill-session -t proyek-a
```

**Screen (alternatif):**
```bash
screen -S proyek-a
# Lepaskan: Ctrl-a lalu d
screen -ls
screen -r proyek-a
screen -X -S proyek-a quit
```

> **Tmux/Screen bukan izin untuk menjalankan `bwa` langsung di dalamnya.**
> Yang boleh berjalan di tmux adalah proses ringan yang mengoordinasi job Slurm.

### 3.4 WAJIB: Isolasi Environment

Setiap job harus menyatakan environment-nya secara eksplisit. Tidak boleh
bergantung pada tool yang "kebetulan ada di PATH".

**a. Conda — untuk tool yang tersedia di Bioconda**

```bash
# Selalu source dulu, jangan andalkan .bashrc
source /opt/conda/etc/profile.d/conda.sh
conda activate bio-align

# Verifikasi versi dan catat ke log — WAJIB untuk reproduktibilitas
echo "Environment: $CONDA_DEFAULT_ENV"
bwa 2>&1 | grep Version
samtools --version | head -1
conda list --export > "$WORKDIR/logs/conda-env-manifest.txt"
```

**Aturan Conda:**
- Gunakan env bersama di `/opt/conda/envs/` bila tersedia
- Jangan `conda install` ke env bersama — buat env baru bila butuh tool lain
- Env personal disimpan di `/home/$USER/.conda/envs/`
- Selalu ekspor `environment.yml` dan simpan bersama hasil analisis
- Kunci versi secara eksplisit: `samtools=1.20`, bukan `samtools`

**b. Singularity/Apptainer — untuk tool kompleks atau yang butuh reproduktibilitas ketat**

```bash
# Bind path yang dibutuhkan secara eksplisit
apptainer exec \
  --cleanenv \
  --bind "/scratch:/scratch" \
  --bind "/mnt/storage:/mnt/storage" \
  --env TMPDIR="$TMPDIR" \
  /opt/containers/gatk_4.5.0.0.sif \
  gatk --java-options "-Xmx12g" HaplotypeCaller \
       -R ref.fa -I input.bam -O output.g.vcf.gz -ERC GVCF

# Dengan GPU
apptainer exec --nv \
  --bind "/scratch:/scratch" \
  /opt/containers/parabricks_4.3.0.sif \
  pbrun fq2bam --ref ref.fa --in-fq r1.fq.gz r2.fq.gz --out-bam out.bam

# Catat versi image ke log
apptainer inspect /opt/containers/gatk_4.5.0.0.sif >> "$WORKDIR/logs/container-manifest.txt"
sha256sum /opt/containers/gatk_4.5.0.0.sif >> "$WORKDIR/logs/container-manifest.txt"
```

**Aturan Container:**
- Set `APPTAINER_CACHEDIR="/scratch/$USER/.apptainer/cache"` — jangan di `/home`
- Nama file `.sif` **wajib** memuat versi; dilarang menggunakan tag `latest`
- Gunakan `--cleanenv` agar variabel lingkungan host tidak bocor ke dalam container
- Image baru diminta ke sysadmin untuk ditempatkan di `/opt/containers`,
  jangan menyimpan `.sif` pribadi di `/home` (ukurannya besar)

**c. Yang dilarang**
- Menginstal tool ke `/usr/local` atau `/opt` secara langsung
- `pip install --user` untuk tool bioinformatics (gunakan Conda)
- Menggunakan tool dari `$PATH` tanpa mengaktifkan environment
- Mengubah env bersama tanpa koordinasi dengan Bioinformatician Lead

### 3.5 Template Job Slurm Standar

Teks lengkap ada di [Lampiran B](#lampiran-b--template-sbatch-lengkap).
Setiap job wajib memuat elemen berikut:

```bash
#!/bin/bash
#SBATCH --job-name=wgs-sample01
#SBATCH --partition=bigmem
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=200G
#SBATCH --time=24:00:00
#SBATCH --output=/mnt/storage/projects/proyek-A/logs/%x-%j.out
#SBATCH --error=/mnt/storage/projects/proyek-A/logs/%x-%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=nama@institusi.ac.id

set -euo pipefail        # WAJIB: hentikan script saat ada error
```

> `set -euo pipefail` adalah wajib. Tanpa itu, script akan lanjut berjalan
> setelah sebuah tahap gagal dan menghasilkan output yang tampak benar
> tetapi sebenarnya rusak — kesalahan yang jauh lebih mahal daripada job gagal.

---

## 4. Batas Resource

### 4.1 Proteksi CPU — Maksimal 80–90%

> **Jangan pernah mengalokasikan 100% core sebuah node ke satu job.**
> Sistem operasi, `slurmd`, `nfsd` client, dan daemon monitoring membutuhkan CPU.
> Jika semuanya kelaparan, node akan tampak "hidup" tetapi tidak merespons,
> dan Slurm akan menandainya `DOWN` — membunuh job Anda sendiri.

**Batas resmi per node:**

| Node | Total Physical Core | Batas SOP (85%) | Maks Core per Job | Core Dicadangkan OS |
|---|---|---|---|---|
| `hpc-node-01` | 128 | **108** | 108 | 2 (CPU 0 & 64) |
| `hpc-node-02` | 64 | **54** | 54 | 2 |
| `hpc-node-03` | 128 | **108** | 108 | 2 |

**Aturan praktis:**

```
--cpus-per-task  ≤  (Total physical core × 0.85)
```

**Penting: gunakan physical core, bukan thread.**
`hpc-node-01` melaporkan 256 logical thread, tetapi hanya punya 128 physical core.
Untuk beban bioinformatics yang umumnya *memory-bandwidth bound*, hyperthreading
memberikan sedikit atau bahkan tidak ada peningkatan — dan sering justru
memperlambat. Rencanakan berdasarkan 128, bukan 256.

**Konsistensi thread flag — sumber kesalahan yang sangat umum:**

Nilai `--cpus-per-task` harus **cocok** dengan flag thread di tool.
Ketidakcocokan menyebabkan salah satu dari dua hal buruk:
oversubscription (node melambat drastis) atau underutilization (core menganggur).

```bash
#SBATCH --cpus-per-task=32

THREADS=${SLURM_CPUS_PER_TASK:-1}     # selalu ambil dari Slurm, jangan hardcode

bwa mem -t "$THREADS" ...
bwa-mem2 mem -t "$THREADS" ...
bowtie2 -p "$THREADS" ...
hisat2 -p "$THREADS" ...
STAR --runThreadN "$THREADS" ...
samtools view -@ "$THREADS" ...
samtools sort -@ "$THREADS" -m 3G ...
samtools index -@ "$THREADS" ...
sambamba markdup -t "$THREADS" ...
fastp --thread 16 ...                  # fastp maksimal efektif di 16
fastqc --threads "$THREADS" ...
salmon quant -p "$THREADS" ...
kraken2 --threads "$THREADS" ...
spades.py -t "$THREADS" -m 200 ...     # -m dalam GB, samakan dengan --mem
gatk --java-options "-Xmx12g" ... --native-pair-hmm-threads "$THREADS"
bcftools --threads "$THREADS" ...
minimap2 -t "$THREADS" ...
```

**Batasi library threading yang sering "membocorkan" thread:**

```bash
# Banyak library numerik diam-diam membuat thread sebanyak core node,
# terlepas dari alokasi Slurm. Ini penyebab oversubscription tersembunyi.
export OMP_NUM_THREADS="$THREADS"
export OPENBLAS_NUM_THREADS="$THREADS"
export MKL_NUM_THREADS="$THREADS"
export NUMEXPR_NUM_THREADS="$THREADS"
export VECLIB_MAXIMUM_THREADS="$THREADS"
export JULIA_NUM_THREADS="$THREADS"
```

**Verifikasi pemakaian CPU riil:**

```bash
# Selama job berjalan
sstat -j <JOBID>.batch --format=JobID,AveCPU,MaxRSS,AveCPUFreq

# Setelah selesai — perhatikan efisiensi
seff <JOBID>

# Contoh keluaran seff:
# Job Wall-clock time: 06:12:44
# CPU Efficiency: 23.11% of 8-06:47:28 core-walltime
#   ^^^ efisiensi 23% berarti Anda meminta 32 core tapi hanya memakai ± 7
#       → job berikutnya minta lebih sedikit core, atau ada I/O bottleneck
```

**Target efisiensi:**

| CPU Efficiency | Penilaian | Tindakan |
|---|---|---|
| > 80% | ✅ Sangat baik | Pertahankan |
| 60–80% | ✅ Baik | Wajar untuk pipeline multi-tahap |
| 30–60% | ⚠️ Kurang efisien | Cek I/O bottleneck; kurangi thread |
| < 30% | ❌ Buruk | **Wajib diperbaiki** sebelum menjalankan batch besar |

### 4.2 Batas Memori

```
--mem  ≤  (RAM node − 32 GB untuk OS)
```

| Node | RAM Fisik | Slurm `RealMemory` | Maks `--mem` per Job |
|---|---|---|---|
| `hpc-node-01` | 1.024 GB | 992.000 MB | **960 GB** |
| `hpc-node-02` | 512 GB | 480.000 MB | 460 GB |

- Jangan gunakan `--mem=0`
- Gunakan `--mem-per-cpu` hanya jika Anda paham implikasinya; `--mem` lebih aman
- Untuk job array, `--mem` berlaku per task

### 4.3 Pemantauan I/O Bottleneck

Job bioinformatics sering *tampak* lambat karena kurang CPU, padahal sebenarnya
menunggu disk atau jaringan. Menambah thread pada job yang I/O-bound justru
memperburuk keadaan.

**Cara mengenali I/O bottleneck:**

```bash
# 1. Lihat kolom %iowait — jika > 20%, sistem menunggu I/O
vmstat 5 10
#   procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
#    r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
#    2 14      0  12345    678  90123    0    0  8192  4096 1200 3400 15  8 32 45  0
#      ^^ b=14 proses ter-block                                          ^^ wa=45% — BOTTLENECK

# 2. Detail per device
iostat -xmz 5
#   %util mendekati 100 dan await tinggi = device jenuh

# 3. Proses mana yang paling banyak I/O
sudo iotop -oPa

# 4. Khusus NFS — ini yang paling sering jadi biang keladi
nfsiostat 5
mountstats --nfs /mnt/storage

# 5. Ringkas semuanya
dstat -cdngy 5
```

**Ambang & tindakan:**

| Indikator | Nilai | Artinya | Tindakan |
|---|---|---|---|
| `%iowait` | > 20% | Sistem menunggu I/O | Pindahkan pekerjaan ke `/scratch` |
| `%iowait` | > 40% | Bottleneck parah | Hentikan, perbaiki alur data |
| `await` (iostat) | > 20 ms pada NVMe | Device jenuh | Kurangi job paralel di node |
| NFS `avg RTT` | > 20 ms | Storage/jaringan jenuh | Pindah ke scratch; laporkan bila menetap |
| `seff` CPU eff. | < 30% + iowait tinggi | Klasik I/O-bound | Ubah pipeline agar pakai pipe & scratch |
| Load average | ≫ jumlah core | Terlalu banyak proses ter-block | Kurangi thread |

**Teknik mengurangi I/O:**

**a. Gunakan pipe, jangan tulis file antara**

```bash
# ❌ BURUK — menulis SAM 380 GB ke disk lalu membacanya lagi
bwa mem -t 32 ref.fa r1.fq.gz r2.fq.gz > sample.sam
samtools view -@ 8 -bS sample.sam > sample.bam
samtools sort -@ 16 -m 3G sample.bam -o sample.sorted.bam
rm sample.sam sample.bam

# ✅ BAIK — file .sam tidak pernah menyentuh disk
bwa mem -t 24 ref.fa r1.fq.gz r2.fq.gz \
  | samtools sort -@ 8 -m 3G -T "$TMPDIR/sort" -o sample.sorted.bam -
samtools index -@ 8 sample.sorted.bam
```

Penghematan pada contoh nyata: 380 GB tulis + 380 GB baca dihapus sepenuhnya,
waktu total turun dari 9 jam menjadi 5 jam 20 menit.

**b. Kompres di tempat, jangan pernah simpan tidak terkompres**

```bash
# Tulis langsung ke CRAM (lebih kecil ± 40% dari BAM)
bwa mem -t 24 ref.fa r1.fq.gz r2.fq.gz \
  | samtools sort -@ 8 -m 3G -T "$TMPDIR/sort" -O bam - \
  | samtools view -@ 8 -C -T ref.fa -o sample.cram -
```

**c. Baca referensi sekali, gunakan berkali-kali**

Untuk job array yang memproses banyak sampel dengan referensi sama,
salin referensi ke scratch sekali di awal (job dependency), bukan di setiap task.

**d. Batasi jumlah job paralel per node**

Sepuluh job yang masing-masing membaca NVMe secara acak akan lebih lambat
daripada tiga job yang berjalan berurutan. Gunakan `--exclusive` untuk job
yang sangat I/O-intensif, atau batasi dengan `%` pada job array:

```bash
#SBATCH --array=1-100%8      # maksimal 8 task berjalan bersamaan
```

### 4.4 Batas GPU

```bash
#SBATCH --gres=gpu:a100:1     # minta jumlah GPU yang benar-benar dipakai
```

- Jangan minta 4 GPU jika tool hanya bisa memakai 1
- Verifikasi GPU benar-benar terpakai: `nvidia-smi` selama job berjalan
- GPU yang dialokasikan tapi menganggur adalah pemborosan paling mahal di cluster

### 4.5 Ringkasan Batas

| Resource | Batas | Penegakan |
|---|---|---|
| CPU per job | ≤ 85% physical core node | Slurm partition config |
| RAM per job | ≤ RAM node − 32 GB | Slurm `RealMemory` + cgroup |
| Walltime | Sesuai partition (4 jam – 30 hari) | Slurm |
| Job bersamaan per user | 20 (QoS `normal`) | Slurm QoS |
| Kuota `/scratch` | 3 TB soft / 3.3 TB hard | XFS quota |
| Kuota `/home` | 50 GB per user | ZFS quota |
| Proses di login node | 4 core, 16 GB, 30 menit | cgroup + reaper otomatis |

---

## 5. Housekeeping

Storage bersama hanya berfungsi jika setiap orang membereskan miliknya.
Bagian ini wajib dijalankan **di dalam script job**, bukan diingat-ingat kemudian.

### 5.1 Hapus File Temporary — Terutama `.sam`

**Aturan:**

> **File `.sam` tidak boleh ada lebih lama dari yang diperlukan.**
> Idealnya tidak pernah dibuat sama sekali (gunakan pipe).
> Jika terpaksa dibuat, hapus segera setelah dikonversi ke BAM/CRAM.

```bash
# Jika terpaksa membuat .sam, hapus segera dan verifikasi konversi dulu
if samtools quickcheck sample.bam; then
    rm -f sample.sam
else
    echo "ERROR: konversi BAM gagal, .sam dipertahankan untuk investigasi" >&2
    exit 1
fi
```

**File yang wajib dibersihkan:**

| Pola | Keterangan |
|---|---|
| `*.sam` | Selalu hapus setelah konversi |
| `*.unsorted.bam` | Hapus setelah sort |
| `*.tmp`, `*.temp` | File sementara tool |
| `samtools.*.tmp.*.bam` | Potongan sementara dari `samtools sort` |
| `*_STARtmp/` | Direktori sementara STAR |
| `*.dedup.metrics` *(jika tidak dibutuhkan)* | Metrik Picard |
| `work/` (Nextflow) | Setelah pipeline sukses dan hasil di-publish |
| `.snakemake/` | Setelah pipeline sukses |
| `*.fastq` (hasil dekompresi) | Selalu hapus; simpan yang `.gz` saja |
| `$TMPDIR/*` | Seluruh isi direktori temp |

**Pola cleanup dengan trap (dijamin jalan walau job gagal):**

```bash
WORKDIR="/scratch/$USER/$SLURM_JOB_ID"
mkdir -p "$WORKDIR/tmp"

cleanup() {
    local rc=$?
    echo "[$(date '+%F %T')] Cleanup dimulai (exit code: $rc)"
    # Selalu hapus file temp, apa pun hasilnya
    rm -f  "$WORKDIR"/*.sam "$WORKDIR"/*.unsorted.bam
    rm -rf "$WORKDIR/tmp" "$WORKDIR"/*_STARtmp
    if [ $rc -eq 0 ]; then
        # Hanya hapus seluruh workdir jika job SUKSES
        cd /
        rm -rf "$WORKDIR"
        echo "[$(date '+%F %T')] Workdir dihapus: $WORKDIR"
    else
        echo "[$(date '+%F %T')] Job GAGAL — workdir dipertahankan untuk debugging: $WORKDIR"
        echo "[$(date '+%F %T')] Hapus manual setelah selesai investigasi!"
    fi
}
trap cleanup EXIT
```

> Perhatikan: pada job gagal, workdir **sengaja dipertahankan** untuk debugging —
> tetapi menjadi tanggung jawab Anda untuk menghapusnya setelah selesai.
> Auto-purge 14 hari adalah jaring pengaman, bukan pengganti disiplin.

### 5.2 Kompresi Otomatis — BAM dan CRAM

**Hierarki format (dari terbesar ke terkecil):**

| Format | Ukuran Relatif | Kapan Dipakai |
|---|---|---|
| `.sam` | 100% | **Tidak pernah disimpan** |
| `.bam` | ± 25% | Kerja antara, hasil sementara |
| `.cram` (referensi) | ± 15% | **Format arsip wajib untuk hasil final** |
| `.cram` (lossy quality) | ± 8% | Hanya dengan persetujuan Bioinformatician Lead |

**Konversi BAM → CRAM untuk arsip:**

```bash
# Konversi
samtools view -@ 8 -C -T /mnt/storage/reference/GRCh38/GRCh38.fa \
    -o sample.cram sample.bam
samtools index -@ 8 sample.cram

# WAJIB: verifikasi sebelum menghapus BAM
samtools quickcheck -v sample.cram || { echo "CRAM rusak!"; exit 1; }

# Bandingkan jumlah read — harus identik
n_bam=$(samtools view -@ 8 -c sample.bam)
n_cram=$(samtools view -@ 8 -c -T /mnt/storage/reference/GRCh38/GRCh38.fa sample.cram)
if [ "$n_bam" -eq "$n_cram" ]; then
    echo "Verifikasi OK: $n_bam read"
    rm -f sample.bam sample.bam.bai
else
    echo "ERROR: jumlah read tidak cocok ($n_bam vs $n_cram) — BAM dipertahankan" >&2
    exit 1
fi
```

> ⚠️ **CRAM bergantung pada file referensi.** Genom referensi yang dipakai untuk
> membuat CRAM **harus tetap tersedia** untuk membacanya kembali. Karena itu
> `/mnt/storage/reference/` bersifat permanen dan read-only, dan versi referensi
> **wajib** dicatat di file metadata bersama CRAM.

**Kompresi file lain:**

```bash
# VCF — selalu bgzip + index
bgzip -@ 8 sample.vcf
tabix -p vcf sample.vcf.gz

# FASTQ — selalu simpan sebagai .gz, jangan pernah simpan mentah
bgzip -@ 8 sample.fastq

# Laporan teks, log, tabel
gzip -9 pipeline.log
zstd -19 --rm large_table.tsv        # zstd lebih cepat & rasio bagus

# Kompresi paralel untuk file sangat besar
pigz -p 8 -9 besar.txt
```

**Script kompresi batch** (contoh untuk membersihkan proyek yang sudah selesai):

```bash
#!/bin/bash
# compress-project.sh — jalankan sebagai job Slurm, bukan di login node
set -euo pipefail
PROJECT="$1"
REF="/mnt/storage/reference/GRCh38/GRCh38.fa"

find "$PROJECT" -name "*.sam" -type f -print -delete

find "$PROJECT" -name "*.bam" -type f | while read -r bam; do
    cram="${bam%.bam}.cram"
    [ -f "$cram" ] && continue
    echo "Mengonversi: $bam"
    samtools view -@ 8 -C -T "$REF" -o "$cram" "$bam"
    samtools index -@ 8 "$cram"
    if samtools quickcheck -v "$cram"; then
        rm -f "$bam" "${bam}.bai"
        echo "  → selesai, BAM dihapus"
    else
        rm -f "$cram" "${cram}.crai"
        echo "  → GAGAL, CRAM dihapus, BAM dipertahankan" >&2
    fi
done

find "$PROJECT" -name "*.vcf" -type f -exec bgzip -@ 8 {} \;
find "$PROJECT" -name "*.vcf.gz" -type f -exec tabix -f -p vcf {} \;
```

### 5.3 Kunci Permission File Final

Setelah hasil akhir disalin ke `/mnt/storage/projects/`, file harus dikunci
agar tidak terhapus atau tertimpa secara tidak sengaja.

```bash
OUT="/mnt/storage/projects/proyek-A/sample01"

# 1. Kepemilikan grup yang benar
chgrp -R bioinfo-users "$OUT"

# 2. File hasil: hanya baca (444) — pemilik pun tidak bisa menimpa tanpa sengaja
chmod 444 "$OUT"/*.cram "$OUT"/*.crai
chmod 444 "$OUT"/*.vcf.gz "$OUT"/*.vcf.gz.tbi
chmod 444 "$OUT"/*.md5

# 3. Direktori: baca + telusuri, setgid agar file baru mewarisi grup
chmod 2550 "$OUT"

# 4. Laporan QC boleh dibaca lebih luas
chmod 444 "$OUT"/qc_reports/*.html

# 5. Verifikasi
ls -la "$OUT"
```

**Tabel permission standar:**

| Jenis | Mode | Arti |
|---|---|---|
| Hasil final (`.cram`, `.vcf.gz`) | `444` (`r--r--r--`) | Baca saja untuk semua — tidak bisa ditimpa |
| Direktori proyek final | `2550` (`dr-xr-s---`) | Baca + telusuri, setgid |
| Direktori proyek aktif | `2770` (`drwxrws---`) | Kerja bersama dalam grup |
| Data mentah (`raw/`) | `444` + export NFS `ro` | Dua lapis proteksi |
| Script pipeline | `550` (`r-xr-x---`) | Bisa dijalankan, tidak bisa diubah |
| Log | `440` (`r--r-----`) | Baca saja untuk grup |

**Proteksi tambahan untuk data yang sangat kritis** (opsional, butuh root):

```bash
# Immutable — bahkan root tidak bisa menghapus tanpa membuka flag dulu
sudo chattr +i "$OUT"/sample01.cram

# Cek
lsattr "$OUT"/sample01.cram
# ----i---------e------- sample01.cram

# Buka kembali bila perlu
sudo chattr -i "$OUT"/sample01.cram
```

> Catatan: `chattr` bekerja pada XFS/ext4 lokal. Untuk file di ZFS via NFS,
> gunakan snapshot ZFS dan permission read-only sebagai mekanisme utama.

**Checksum wajib untuk hasil final:**

```bash
cd "$OUT"
md5sum *.cram *.vcf.gz > checksums.md5
chmod 444 checksums.md5

# Verifikasi kapan pun
md5sum -c checksums.md5
```

### 5.4 Logging

Setiap job wajib meninggalkan jejak yang cukup untuk mereproduksi analisis
enam bulan kemudian, tanpa bertanya kepada siapa pun.

**Struktur log wajib:**

```
/mnt/storage/projects/proyek-A/
├── logs/
│   ├── wgs-sample01-12345.out          # stdout Slurm
│   ├── wgs-sample01-12345.err          # stderr Slurm
│   ├── wgs-sample01-12345.env          # environment & versi tool
│   ├── wgs-sample01-12345.resources    # pemakaian resource (seff/sacct)
│   └── wgs-sample01-12345.provenance   # parameter, referensi, checksum input
└── sample01/
    ├── sample01.cram
    ├── ...
    └── checksums.md5
```

**Blok logging standar (sisipkan di setiap script job):**

```bash
LOGDIR="/mnt/storage/projects/proyek-A/logs"
mkdir -p "$LOGDIR"
PROV="$LOGDIR/${SLURM_JOB_NAME}-${SLURM_JOB_ID}.provenance"

{
  echo "======================================================================"
  echo " PROVENANCE RECORD"
  echo "======================================================================"
  echo "Job Name        : ${SLURM_JOB_NAME}"
  echo "Job ID          : ${SLURM_JOB_ID}"
  echo "Array Task ID   : ${SLURM_ARRAY_TASK_ID:-n/a}"
  echo "Submit User     : ${SLURM_JOB_USER}"
  echo "Node            : $(hostname -f)"
  echo "Partition       : ${SLURM_JOB_PARTITION}"
  echo "CPUs Allocated  : ${SLURM_CPUS_PER_TASK}"
  echo "Memory Requested: ${SLURM_MEM_PER_NODE:-${SLURM_MEM_PER_CPU:-n/a}}"
  echo "Start Time      : $(date '+%F %T %Z')"
  echo "Working Dir     : ${WORKDIR}"
  echo "TMPDIR          : ${TMPDIR}"
  echo "----------------------------------------------------------------------"
  echo "ENVIRONMENT"
  echo "Conda Env       : ${CONDA_DEFAULT_ENV:-none}"
  echo "Container       : ${CONTAINER_IMAGE:-none}"
  echo "----------------------------------------------------------------------"
  echo "TOOL VERSIONS"
  bwa 2>&1 | grep -i version || true
  samtools --version | head -1
  gatk --version 2>&1 | head -2 || true
  echo "----------------------------------------------------------------------"
  echo "INPUT"
  echo "R1              : ${R1}"
  echo "R1 md5          : $(md5sum "${R1}" | cut -d' ' -f1)"
  echo "R2              : ${R2}"
  echo "R2 md5          : $(md5sum "${R2}" | cut -d' ' -f1)"
  echo "Reference       : ${REF}"
  echo "Reference md5   : $(md5sum "${REF}" | cut -d' ' -f1)"
  echo "----------------------------------------------------------------------"
  echo "GIT REVISION (pipeline)"
  git -C "$(dirname "$0")" rev-parse HEAD 2>/dev/null || echo "not a git repo"
  echo "======================================================================"
} > "$PROV"

# Salin manifest environment
conda list --export > "$LOGDIR/${SLURM_JOB_NAME}-${SLURM_JOB_ID}.env" 2>/dev/null || true
```

**Catat pemakaian resource setelah job selesai:**

```bash
# Di akhir script (sebelum cleanup)
{
    echo "End Time : $(date '+%F %T %Z')"
    echo "--- sacct ---"
    sacct -j "$SLURM_JOB_ID" --format=JobID,JobName,Partition,AllocCPUS,ReqMem,MaxRSS,MaxDiskRead,MaxDiskWrite,Elapsed,State,ExitCode
} >> "$LOGDIR/${SLURM_JOB_NAME}-${SLURM_JOB_ID}.resources"
```

**Aturan retensi log:**

| Jenis Log | Lokasi | Retensi |
|---|---|---|
| stdout/stderr Slurm | `/mnt/storage/projects/*/logs/` | Selama proyek aktif + 2 tahun |
| Provenance | `/mnt/storage/projects/*/logs/` | **Permanen** (bagian dari hasil) |
| Manifest environment | `/mnt/storage/projects/*/logs/` | **Permanen** |
| Log sistem node | `/var/log/` + log server | 90 hari |
| Accounting Slurm | Database `slurmdbd` | Permanen |

> Log yang ditulis ke `/scratch` akan ikut terhapus saat purge.
> **Selalu arahkan `--output` dan `--error` Slurm ke `/mnt/storage`.**

### 5.5 Purge Otomatis `/scratch`

Sistem menghapus otomatis file di `/scratch` yang `atime`-nya lebih dari 14 hari.

| Field | Nilai |
|---|---|
| Jadwal | Setiap hari 03:00 |
| Mekanisme | `systemd timer` `scratch-purge.timer` |
| Kriteria | `atime` > 14 hari |
| Notifikasi | Email peringatan H-3 ke pemilik file |
| Pengecualian | Path yang terdaftar di `/scratch/.purge-exclude` (izin sysadmin) |

```bash
# Lihat kapan file Anda akan dihapus
find /scratch/$USER -type f -atime +11 -printf '%A+ %s %p\n' | sort | head -20

# Lihat total yang akan terhapus
find /scratch/$USER -type f -atime +14 -printf '%s\n' | awk '{s+=$1} END {print s/1024/1024/1024 " GB"}'

# Cek kuota
xfs_quota -c "quota -h $USER" /scratch
```

> **Purge bukan alasan untuk tidak membersihkan sendiri.** Jika semua orang
> mengandalkan purge, `/scratch` akan penuh jauh sebelum hari ke-14 dan
> job semua orang gagal.

---

## 6. Checklist Ringkas

Cetak dan tempel di meja Anda.

### Sebelum Submit

- [ ] `df -h /scratch` — ruang bebas ≥ input × faktor pipeline × 1.2
- [ ] `df -h /mnt/storage` — ruang tujuan cukup, pool < 80%
- [ ] `TMPDIR` diarahkan ke `/scratch/$USER/$SLURM_JOB_ID/tmp`
- [ ] `--mem` dihitung dari `MaxRSS` uji coba + margin 25%
- [ ] `--cpus-per-task` ≤ 85% physical core node
- [ ] Flag thread tool = `$SLURM_CPUS_PER_TASK`
- [ ] `OMP_NUM_THREADS` dan kawan-kawan di-set
- [ ] `samtools sort -m` × thread ≤ 80% dari `--mem`
- [ ] Java `-Xmx` di-set eksplisit
- [ ] Conda env / container ditentukan dengan versi terkunci
- [ ] `set -euo pipefail` ada di baris atas script
- [ ] `--output` dan `--error` mengarah ke `/mnt/storage`, bukan `/scratch`
- [ ] `trap cleanup EXIT` terpasang
- [ ] Script sudah diuji dengan 1 sampel kecil

### Selama Job Berjalan

- [ ] `squeue -u $USER` — job berjalan, bukan `PENDING` karena permintaan berlebihan
- [ ] `sstat -j <JOBID>.batch` — RAM di bawah batas
- [ ] `df -h /scratch` — belum mendekati penuh
- [ ] `vmstat 5` — `%iowait` < 20%

### Setelah Job Selesai

- [ ] `seff <JOBID>` — CPU efficiency ≥ 60%, memory efficiency ≥ 50%
- [ ] Semua `.sam` sudah terhapus
- [ ] BAM sudah dikonversi ke CRAM dan diverifikasi
- [ ] VCF sudah `bgzip` + `tabix`
- [ ] Hasil final disalin ke `/mnt/storage/projects/`
- [ ] `md5sum` hasil final dibuat
- [ ] Permission dikunci (`chmod 444` file, `2550` direktori)
- [ ] File provenance & manifest environment tersimpan
- [ ] Direktori kerja di `/scratch` sudah dihapus
- [ ] `df -h /scratch` — ruang sudah kembali

---

## 7. Pelanggaran & Sanksi

| Pelanggaran | Tingkat | Konsekuensi |
|---|---|---|
| Menjalankan komputasi di login node | Sedang | Proses dihentikan otomatis + peringatan email |
| Menjalankan komputasi via SSH langsung ke compute node | Berat | Proses dihentikan; peringatan tertulis |
| Menjalankan sebagai `root` | **Sangat berat** | Akses `sudo` dicabut; ditinjau oleh Lead |
| Menulis file besar ke `/mnt/storage` sebagai scratch | Berat | Job dihentikan; peringatan |
| Menulis ke `/tmp` hingga memicu OOM node | Berat | Job dihentikan; peringatan |
| `--mem=0` atau tanpa `--mem` | Sedang | Job ditolak oleh submit filter |
| Meninggalkan `.sam` di storage > 7 hari | Ringan | Email peringatan; file dihapus setelah 14 hari |
| Membiarkan sesi interaktif idle > 30 menit | Ringan | Sesi dihentikan otomatis |
| Mengubah env Conda bersama tanpa koordinasi | Sedang | Perubahan di-rollback; peringatan |
| Pelanggaran berulang (3× dalam 3 bulan) | — | Penangguhan akses 7 hari; diskusi dengan Lead |

Sanksi bukan tentang menghukum — tujuannya menjaga agar cluster tetap dapat
dipakai semua orang. Jika Anda tidak yakin apakah sesuatu diizinkan, tanya dulu.

---

## 8. Eskalasi & Kontak

| Situasi | Hubungi | Kanal |
|---|---|---|
| Job gagal, tidak tahu sebabnya | Bioinformatician Lead | `#hpc-help` |
| Butuh tool/versi baru di Conda/container | Bioinformatician Lead | Tiket |
| `/scratch` penuh, tidak bisa submit | Sysadmin | `#hpc-help` |
| Node `DOWN` atau `DRAIN` | Sysadmin | `#hpc-help` |
| `/mnt/storage` tidak bisa diakses / hang | **Sysadmin — segera** | Telepon |
| Butuh kuota lebih besar | Sysadmin + Lead | Tiket + justifikasi |
| Butuh partisi/QoS khusus | Sysadmin + Lead | Tiket |
| Data hilang / terhapus tidak sengaja | **Sysadmin — segera** (snapshot ada, tapi terbatas waktu) | Telepon |
| Dugaan pelanggaran SOP oleh pengguna lain | Sysadmin | Japri |

**Sebelum melapor, siapkan informasi ini:**
```bash
# Kumpulkan dalam satu blok, lampirkan saat melapor
echo "User    : $USER"
echo "Job ID  : <JOBID>"
echo "Node    : $(squeue -j <JOBID> -h -o %N)"
sacct -j <JOBID> --format=JobID,JobName,State,ExitCode,MaxRSS,Elapsed,NodeList
seff <JOBID>
tail -50 /mnt/storage/projects/<proyek>/logs/<job>-<JOBID>.err
```

---

## 9. Lampiran

### Lampiran A — Script Pre-Flight Check

Simpan sebagai `/opt/scripts/preflight-check.sh`.

```bash
#!/usr/bin/env bash
# =============================================================================
#  preflight-check.sh — Verifikasi kesiapan sebelum submit job bioinformatics
#  Pemakaian: preflight-check.sh <direktori-input> [faktor-pipeline]
#  Contoh   : preflight-check.sh /mnt/storage/raw/proyek-A 8
# =============================================================================
set -euo pipefail

INPUT_DIR="${1:?Pemakaian: $0 <direktori-input> [faktor-pipeline]}"
FACTOR="${2:-3}"
BUFFER_PCT=20

SCRATCH="/scratch/$USER"
STORAGE="/mnt/storage"

RED='\033[0;31m'; YEL='\033[0;33m'; GRN='\033[0;32m'; NC='\033[0m'
ok()   { echo -e "${GRN}[ OK ]${NC} $*"; }
warn() { echo -e "${YEL}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; ERRORS=$((ERRORS+1)); }
ERRORS=0

echo "======================================================================"
echo " PRE-FLIGHT CHECK"
echo " Input   : $INPUT_DIR"
echo " Faktor  : ${FACTOR}x  (+${BUFFER_PCT}% buffer)"
echo " Waktu   : $(date '+%F %T')"
echo "======================================================================"

# --- 1. Input ada dan bisa dibaca -------------------------------------------
if [ ! -d "$INPUT_DIR" ]; then
    fail "Direktori input tidak ditemukan: $INPUT_DIR"
    exit 1
fi
if [ ! -r "$INPUT_DIR" ]; then
    fail "Tidak punya izin baca pada: $INPUT_DIR"
    exit 1
fi
ok "Direktori input dapat diakses"

# --- 2. Hitung ukuran input --------------------------------------------------
INPUT_BYTES=$(du -sb "$INPUT_DIR" | cut -f1)
INPUT_GB=$(( INPUT_BYTES / 1024 / 1024 / 1024 ))
NEED_GB=$(( INPUT_GB * FACTOR * (100 + BUFFER_PCT) / 100 ))
ok "Ukuran input       : ${INPUT_GB} GB"
ok "Kebutuhan scratch  : ${NEED_GB} GB (${INPUT_GB} x ${FACTOR} + ${BUFFER_PCT}%)"

# --- 3. Ruang bebas scratch --------------------------------------------------
mkdir -p "$SCRATCH"
FREE_GB=$(df -BG --output=avail /scratch | tail -1 | tr -dc '0-9')
USED_PCT=$(df --output=pcent /scratch | tail -1 | tr -dc '0-9')

echo "----------------------------------------------------------------------"
echo " /scratch : ${FREE_GB} GB bebas, terpakai ${USED_PCT}%"

if [ "$USED_PCT" -ge 88 ]; then
    fail "/scratch terpakai ${USED_PCT}% — JANGAN submit. Hubungi sysadmin."
elif [ "$USED_PCT" -ge 75 ]; then
    warn "/scratch terpakai ${USED_PCT}% — hati-hati, kurangi job paralel"
else
    ok "/scratch pada level aman (${USED_PCT}%)"
fi

if [ "$FREE_GB" -lt "$NEED_GB" ]; then
    fail "Ruang tidak cukup: butuh ${NEED_GB} GB, tersedia ${FREE_GB} GB"
    echo "      Bersihkan scratch dulu:"
    echo "        du -sh /scratch/$USER/* | sort -h | tail -20"
    echo "        find /scratch/$USER -name '*.sam' -delete"
else
    ok "Ruang scratch mencukupi (${FREE_GB} GB >= ${NEED_GB} GB)"
fi

# --- 4. Kuota scratch --------------------------------------------------------
if command -v xfs_quota >/dev/null 2>&1; then
    echo "----------------------------------------------------------------------"
    echo " Kuota /scratch untuk $USER:"
    xfs_quota -c "quota -h $USER" /scratch 2>/dev/null | tail -3 || \
        warn "Tidak dapat membaca kuota"
fi

# --- 5. Storage tujuan -------------------------------------------------------
echo "----------------------------------------------------------------------"
if mountpoint -q "$STORAGE"; then
    ST_FREE_TB=$(df -BT --output=avail "$STORAGE" | tail -1 | tr -dc '0-9')
    ST_USED_PCT=$(df --output=pcent "$STORAGE" | tail -1 | tr -dc '0-9')
    echo " /mnt/storage : ${ST_FREE_TB} TB bebas, terpakai ${ST_USED_PCT}%"
    if [ "$ST_USED_PCT" -ge 80 ]; then
        fail "/mnt/storage terpakai ${ST_USED_PCT}% — hubungi sysadmin sebelum menulis"
    else
        ok "/mnt/storage pada level aman"
    fi
else
    fail "/mnt/storage tidak ter-mount!"
fi

# --- 6. Peringatan file yang tidak seharusnya ada ----------------------------
echo "----------------------------------------------------------------------"
SAM_COUNT=$(find "$SCRATCH" -name "*.sam" -type f 2>/dev/null | wc -l)
if [ "$SAM_COUNT" -gt 0 ]; then
    SAM_GB=$(find "$SCRATCH" -name "*.sam" -type f -printf '%s\n' 2>/dev/null \
             | awk '{s+=$1} END {printf "%.0f", s/1024/1024/1024}')
    warn "Ditemukan ${SAM_COUNT} file .sam di scratch Anda (${SAM_GB} GB) — hapus!"
    find "$SCRATCH" -name "*.sam" -type f -printf '       %p (%s bytes)\n' 2>/dev/null | head -10
else
    ok "Tidak ada file .sam tertinggal di scratch"
fi

OLD_COUNT=$(find "$SCRATCH" -type f -atime +11 2>/dev/null | wc -l)
if [ "$OLD_COUNT" -gt 0 ]; then
    warn "${OLD_COUNT} file akan dihapus purge dalam <= 3 hari"
fi

# --- 7. Slurm ----------------------------------------------------------------
echo "----------------------------------------------------------------------"
if command -v sinfo >/dev/null 2>&1; then
    echo " Ketersediaan node:"
    sinfo -o "%20P %5a %10l %6D %6t %N" | head -10
    PENDING=$(squeue -u "$USER" -h -t PENDING | wc -l)
    RUNNING=$(squeue -u "$USER" -h -t RUNNING | wc -l)
    echo " Job Anda: ${RUNNING} berjalan, ${PENDING} mengantre"
else
    warn "Perintah sinfo tidak tersedia"
fi

# --- Kesimpulan --------------------------------------------------------------
echo "======================================================================"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GRN} HASIL: SIAP SUBMIT${NC}"
    exit 0
else
    echo -e "${RED} HASIL: ${ERRORS} MASALAH DITEMUKAN — JANGAN SUBMIT${NC}"
    exit 1
fi
```

### Lampiran B — Template sbatch Lengkap

Simpan sebagai `/opt/scripts/templates/wgs-pipeline.sh`.

```bash
#!/bin/bash
# =============================================================================
#  Template Job Slurm — Pipeline WGS (align → sort → markdup → variant)
#  Sesuai SOP-BIO-EXEC-001
#  Pemakaian: sbatch wgs-pipeline.sh <sample_id>
# =============================================================================
#SBATCH --job-name=wgs
#SBATCH --partition=bigmem
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=200G
#SBATCH --time=24:00:00
#SBATCH --output=/mnt/storage/projects/proyek-A/logs/%x-%j.out
#SBATCH --error=/mnt/storage/projects/proyek-A/logs/%x-%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=nama@institusi.ac.id

set -euo pipefail

# =============================================================================
# 1. PARAMETER
# =============================================================================
SAMPLE="${1:?Pemakaian: sbatch $0 <sample_id>}"
PROJECT="proyek-A"

RAW_DIR="/mnt/storage/raw/${PROJECT}"
OUT_BASE="/mnt/storage/projects/${PROJECT}"
REF="/mnt/storage/reference/GRCh38/GRCh38.fa"
DBSNP="/mnt/storage/reference/GRCh38/dbsnp_155.vcf.gz"

R1="${RAW_DIR}/${SAMPLE}_R1.fastq.gz"
R2="${RAW_DIR}/${SAMPLE}_R2.fastq.gz"

THREADS="${SLURM_CPUS_PER_TASK:-1}"
SORT_THREADS=$(( THREADS / 2 ))
SORT_MEM_GB=3          # 16 thread x 3G = 48G, aman untuk --mem=200G

# =============================================================================
# 2. DIREKTORI KERJA DI SCRATCH (bukan NFS!)
# =============================================================================
WORKDIR="/scratch/${USER}/${SLURM_JOB_ID}"
export TMPDIR="${WORKDIR}/tmp"
export TMP="$TMPDIR"
export TEMP="$TMPDIR"
export JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=${TMPDIR}"
export APPTAINER_CACHEDIR="/scratch/${USER}/.apptainer/cache"

mkdir -p "${TMPDIR}" "${OUT_BASE}/logs"

LOGDIR="${OUT_BASE}/logs"
PROV="${LOGDIR}/${SLURM_JOB_NAME}-${SLURM_JOB_ID}.provenance"

# =============================================================================
# 3. BATASI THREAD LIBRARY (cegah oversubscription tersembunyi)
# =============================================================================
export OMP_NUM_THREADS="$THREADS"
export OPENBLAS_NUM_THREADS="$THREADS"
export MKL_NUM_THREADS="$THREADS"
export NUMEXPR_NUM_THREADS="$THREADS"

# =============================================================================
# 4. CLEANUP TRAP — dijamin jalan walau job gagal
# =============================================================================
cleanup() {
    local rc=$?
    echo "[$(date '+%F %T')] === CLEANUP (exit code: $rc) ==="
    rm -f  "${WORKDIR}"/*.sam "${WORKDIR}"/*.unsorted.bam 2>/dev/null || true
    rm -rf "${TMPDIR}" 2>/dev/null || true
    if [ $rc -eq 0 ]; then
        cd /
        rm -rf "${WORKDIR}"
        echo "[$(date '+%F %T')] Workdir dihapus: ${WORKDIR}"
    else
        echo "[$(date '+%F %T')] JOB GAGAL — workdir dipertahankan: ${WORKDIR}"
        echo "[$(date '+%F %T')] Hapus manual setelah investigasi selesai."
    fi
    {
        echo "End Time : $(date '+%F %T %Z')"
        echo "--- sacct ---"
        sacct -j "${SLURM_JOB_ID}" \
              --format=JobID,JobName,AllocCPUS,ReqMem,MaxRSS,MaxDiskRead,MaxDiskWrite,Elapsed,State,ExitCode
    } >> "${LOGDIR}/${SLURM_JOB_NAME}-${SLURM_JOB_ID}.resources" 2>/dev/null || true
}
trap cleanup EXIT

# =============================================================================
# 5. ENVIRONMENT
# =============================================================================
source /opt/conda/etc/profile.d/conda.sh
conda activate bio-align

# =============================================================================
# 6. PRE-FLIGHT CHECK
# =============================================================================
echo "[$(date '+%F %T')] === PRE-FLIGHT ==="
[ -f "$R1" ] || { echo "ERROR: R1 tidak ditemukan: $R1" >&2; exit 1; }
[ -f "$R2" ] || { echo "ERROR: R2 tidak ditemukan: $R2" >&2; exit 1; }
[ -f "$REF" ] || { echo "ERROR: referensi tidak ditemukan: $REF" >&2; exit 1; }

INPUT_GB=$(( ($(stat -c%s "$R1") + $(stat -c%s "$R2")) / 1024 / 1024 / 1024 ))
NEED_GB=$(( INPUT_GB * 8 ))
FREE_GB=$(df -BG --output=avail /scratch | tail -1 | tr -dc '0-9')
echo "Input: ${INPUT_GB} GB | Butuh: ${NEED_GB} GB | Bebas: ${FREE_GB} GB"
if [ "$FREE_GB" -lt "$NEED_GB" ]; then
    echo "ERROR: ruang /scratch tidak cukup" >&2
    exit 1
fi

# Pastikan benar-benar di scratch lokal, bukan NFS
if findmnt -T "$WORKDIR" -no SOURCE | grep -q ':'; then
    echo "ERROR: WORKDIR berada di NFS! Ini melanggar SOP." >&2
    exit 1
fi
echo "Pre-flight OK"

# =============================================================================
# 7. PROVENANCE
# =============================================================================
{
  echo "===================================================================="
  echo " PROVENANCE"
  echo "===================================================================="
  echo "Sample          : ${SAMPLE}"
  echo "Job ID          : ${SLURM_JOB_ID}"
  echo "Node            : $(hostname -f)"
  echo "Partition       : ${SLURM_JOB_PARTITION}"
  echo "CPUs            : ${THREADS}"
  echo "Memory          : ${SLURM_MEM_PER_NODE:-n/a} MB"
  echo "Start           : $(date '+%F %T %Z')"
  echo "Conda Env       : ${CONDA_DEFAULT_ENV}"
  echo "--------------------------------------------------------------------"
  bwa 2>&1 | grep -i version || true
  samtools --version | head -1
  echo "--------------------------------------------------------------------"
  echo "R1              : ${R1}"
  echo "R1 md5          : $(md5sum "$R1" | cut -d' ' -f1)"
  echo "R2              : ${R2}"
  echo "R2 md5          : $(md5sum "$R2" | cut -d' ' -f1)"
  echo "Reference       : ${REF}"
  echo "===================================================================="
} > "$PROV"
conda list --export > "${LOGDIR}/${SLURM_JOB_NAME}-${SLURM_JOB_ID}.env"

# =============================================================================
# 8. STAGE-IN
# =============================================================================
echo "[$(date '+%F %T')] === STAGE-IN ==="
cd "$WORKDIR"
cp "$R1" "$R2" .
ln -sf "$REF"     ref.fa
ln -sf "${REF}.fai" ref.fa.fai
for ext in amb ann bwt pac sa; do ln -sf "${REF}.${ext}" "ref.fa.${ext}"; done
echo "Stage-in selesai: $(du -sh . | cut -f1)"

# =============================================================================
# 9. QC
# =============================================================================
echo "[$(date '+%F %T')] === QC ==="
conda activate bio-qc
mkdir -p qc
fastp --thread 16 \
      -i "$(basename "$R1")" -I "$(basename "$R2")" \
      -o "${SAMPLE}_R1.trim.fastq.gz" -O "${SAMPLE}_R2.trim.fastq.gz" \
      --html "qc/${SAMPLE}_fastp.html" --json "qc/${SAMPLE}_fastp.json" \
      --detect_adapter_for_pe

# =============================================================================
# 10. ALIGNMENT — pipe langsung, .sam TIDAK PERNAH menyentuh disk
# =============================================================================
echo "[$(date '+%F %T')] === ALIGNMENT ==="
conda activate bio-align
bwa mem -t "$THREADS" -M \
    -R "@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tPL:ILLUMINA\tLB:lib1" \
    ref.fa "${SAMPLE}_R1.trim.fastq.gz" "${SAMPLE}_R2.trim.fastq.gz" \
  | samtools sort -@ "$SORT_THREADS" -m "${SORT_MEM_GB}G" \
                  -T "${TMPDIR}/sort" -o "${SAMPLE}.sorted.bam" -
samtools index -@ "$THREADS" "${SAMPLE}.sorted.bam"
samtools quickcheck -v "${SAMPLE}.sorted.bam" || { echo "BAM rusak" >&2; exit 1; }

rm -f "${SAMPLE}_R1.trim.fastq.gz" "${SAMPLE}_R2.trim.fastq.gz"

# =============================================================================
# 11. MARK DUPLICATES
# =============================================================================
echo "[$(date '+%F %T')] === MARK DUPLICATES ==="
sambamba markdup -t "$THREADS" --tmpdir="$TMPDIR" \
    "${SAMPLE}.sorted.bam" "${SAMPLE}.markdup.bam"
rm -f "${SAMPLE}.sorted.bam" "${SAMPLE}.sorted.bam.bai"

# =============================================================================
# 12. VARIANT CALLING
# =============================================================================
echo "[$(date '+%F %T')] === VARIANT CALLING ==="
conda activate bio-variant
gatk --java-options "-Xmx24g -Xms24g -XX:ParallelGCThreads=4 -Djava.io.tmpdir=${TMPDIR}" \
     HaplotypeCaller \
     -R ref.fa -I "${SAMPLE}.markdup.bam" \
     -O "${SAMPLE}.g.vcf.gz" -ERC GVCF \
     --native-pair-hmm-threads "$THREADS"

# =============================================================================
# 13. KOMPRESI KE CRAM + VERIFIKASI
# =============================================================================
echo "[$(date '+%F %T')] === KOMPRESI CRAM ==="
conda activate bio-align
samtools view -@ "$THREADS" -C -T ref.fa -o "${SAMPLE}.cram" "${SAMPLE}.markdup.bam"
samtools index -@ "$THREADS" "${SAMPLE}.cram"

n_bam=$(samtools view -@ "$THREADS" -c "${SAMPLE}.markdup.bam")
n_cram=$(samtools view -@ "$THREADS" -c -T ref.fa "${SAMPLE}.cram")
if [ "$n_bam" -ne "$n_cram" ]; then
    echo "ERROR: jumlah read tidak cocok BAM=${n_bam} CRAM=${n_cram}" >&2
    exit 1
fi
echo "Verifikasi CRAM OK: ${n_cram} read"
rm -f "${SAMPLE}.markdup.bam" "${SAMPLE}.markdup.bam.bai"

# =============================================================================
# 14. STAGE-OUT
# =============================================================================
echo "[$(date '+%F %T')] === STAGE-OUT ==="
OUT="${OUT_BASE}/${SAMPLE}"
mkdir -p "$OUT"
cp "${SAMPLE}.cram" "${SAMPLE}.cram.crai" \
   "${SAMPLE}.g.vcf.gz" "${SAMPLE}.g.vcf.gz.tbi" "$OUT/"
cp -r qc "$OUT/"

cd "$OUT"
md5sum ./*.cram ./*.g.vcf.gz > checksums.md5

# =============================================================================
# 15. KUNCI PERMISSION
# =============================================================================
echo "[$(date '+%F %T')] === KUNCI PERMISSION ==="
chgrp -R bioinfo-users "$OUT" 2>/dev/null || true
chmod 444 "$OUT"/*.cram "$OUT"/*.crai "$OUT"/*.g.vcf.gz "$OUT"/*.tbi "$OUT"/checksums.md5
chmod -R 444 "$OUT"/qc/* 2>/dev/null || true
chmod 2550 "$OUT"
ls -la "$OUT"

echo "[$(date '+%F %T')] === SELESAI: ${SAMPLE} ==="
# trap cleanup akan berjalan otomatis setelah ini
```

### Lampiran C — Job Array untuk Banyak Sampel

```bash
#!/bin/bash
#SBATCH --job-name=wgs-array
#SBATCH --partition=bigmem
#SBATCH --array=1-50%8          # 50 sampel, maksimal 8 berjalan bersamaan
#SBATCH --cpus-per-task=32
#SBATCH --mem=200G
#SBATCH --time=24:00:00
#SBATCH --output=/mnt/storage/projects/proyek-A/logs/%x-%A_%a.out
#SBATCH --error=/mnt/storage/projects/proyek-A/logs/%x-%A_%a.err

set -euo pipefail

# Batas %8 penting: 50 job paralel akan menjenuhkan I/O dan membuat
# semuanya lebih lambat daripada 8 job yang berjalan bertahap.

SAMPLE_LIST="/mnt/storage/projects/proyek-A/samples.txt"
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

echo "Task ${SLURM_ARRAY_TASK_ID}: memproses ${SAMPLE}"
bash /opt/scripts/templates/wgs-pipeline.sh "$SAMPLE"
```

### Lampiran D — Perintah Cepat

```bash
# --- SUBMIT & MONITOR ---
sbatch script.sh
sbatch --dependency=afterok:12345 next.sh
squeue -u $USER
squeue -u $USER -o "%.10i %.25j %.8T %.10M %.10L %.6C %.10m %R"
scancel 12345
scancel -u $USER --state=PENDING
scontrol show job 12345

# --- EFISIENSI ---
seff 12345
sacct -j 12345 --format=JobID,JobName,MaxRSS,MaxVMSize,AllocCPUS,Elapsed,State
sacct -u $USER -S 2026-08-01 --format=JobID,JobName,State,Elapsed,MaxRSS
sstat -j 12345.batch --format=JobID,AveCPU,MaxRSS,MaxDiskRead,MaxDiskWrite

# --- STORAGE ---
df -h /scratch /mnt/storage
du -sh /scratch/$USER/* | sort -h | tail -20
xfs_quota -c "quota -h $USER" /scratch
find /scratch/$USER -name "*.sam" -type f -printf '%s %p\n' | sort -rn | head
find /scratch/$USER -type f -atime +11 | wc -l

# --- I/O ---
vmstat 5
iostat -xmz 5
nfsiostat 5
dstat -cdngy 5

# --- ENVIRONMENT ---
conda env list
conda activate bio-align
apptainer exec --bind /scratch,/mnt/storage /opt/containers/gatk_4.5.0.0.sif gatk --version

# --- CLUSTER ---
sinfo -N -l
sinfo -o "%20P %5a %10l %6D %6t %N"
scontrol show partition
```

---

**Riwayat Revisi SOP**

| Versi | Tanggal | Perubahan | Penyusun |
|---|---|---|---|
| `1.0.0` | 2026-08-28 | Versi awal | Sysadmin HPC |

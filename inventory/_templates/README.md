# Template Dokumentasi Node

> ⚠️ **File di folder ini adalah CONTOH / KERANGKA. Jangan diedit, jangan diisi
> data server asli di sini.** Selalu **salin** dulu ke folder node yang sesuai.

Semua angka, serial, IP, dan nama di dalam template adalah **data karangan**
untuk memperlihatkan bentuk isian yang diharapkan — bukan server yang benar-benar ada.

| Template | Untuk | Salin ke |
|---|---|---|
| [`hpc-node.template.md`](hpc-node.template.md) | Node compute bare-metal (CPU/GPU, Slurm, scratch NVMe) | `inventory/hpc-nodes/<hostname>.md` |
| [`storage-node.template.md`](storage-node.template.md) | Node storage/NAS (ZFS, NFS/SMB, snapshot) | `inventory/storage-nodes/<hostname>.md` |
| [`proxmox-node.template.md`](proxmox-node.template.md) | Host hypervisor Proxmox VE (VM/LXC, backup) | `inventory/proxmox-nodes/<hostname>.md` |

## Cara pakai

```bash
cp inventory/_templates/proxmox-node.template.md inventory/proxmox-nodes/<hostname>.md
```

Nama file mengikuti **hostname asli** hasil `hostname -f`, bukan nama urut karangan.

Folder ini kedalamannya sama dengan `inventory/hpc-nodes/`, `inventory/storage-nodes/`,
dan `inventory/proxmox-nodes/`, jadi path relatif di dalam template
(`../../assets/...`, `../../track-record/...`) tetap benar setelah disalin —
tidak perlu diubah.

Prosedur lengkap: [`docs/penginputan-node.md`](../../docs/penginputan-node.md).

## Contoh hasil pengisian

[`inventory/proxmox-nodes/proxmox.md`](../proxmox-nodes/proxmox.md) — data asli,
hasil `scripts/collect-proxmox.sh`.

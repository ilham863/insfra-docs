#!/usr/bin/env bash
#
# collect-hpc.sh — kumpulkan data inventaris dari node compute HPC (bare-metal).
#
# Semua perintah di dalamnya READ-ONLY. Script ini tidak mengubah apa pun
# di server target dan tidak pernah mencetak password, kunci, atau isi
# file kredensial.
#
# Pakai:
#   bash scripts/collect-hpc.sh <host> [user] [ssh-key]   # via SSH
#   bash scripts/collect-hpc.sh --local                   # langsung di node
#
# Contoh:
#   bash scripts/collect-hpc.sh 192.168.18.178 root ~/.ssh/id_hpc > /tmp/hpc-$(date +%F).txt
#
# Sebagian perintah (dmidecode, smartctl, ipmitool) butuh root. Kalau dijalankan
# sebagai user biasa, bagian itu akan kosong — sisanya tetap terkumpul.
#
# Hasilnya dipakai untuk mengisi inventory/hpc-nodes/<hostname>.md
# Lihat docs/penginputan-node.md.

set -uo pipefail

# ---------------------------------------------------------------- mode SSH ---
if [ "${1:-}" != "--local" ] && [ "${1:-}" != "" ]; then
	HOST="$1"
	USER="${2:-root}"
	KEY="${3:-}"
	SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10)
	[ -n "$KEY" ] && SSH_OPTS+=(-i "$KEY")
	exec ssh "${SSH_OPTS[@]}" "${USER}@${HOST}" 'bash -s' -- --local < "$0"
fi

if [ "${1:-}" = "" ]; then
	sed -n '3,22p' "$0" | sed 's/^# \{0,1\}//'
	exit 1
fi

# -------------------------------------------------------------- pengumpulan ---
sec() { echo; echo "########## $1 ##########"; }
run() { echo "--- \$ $* ---"; "$@" 2>&1; }
have() { command -v "$1" >/dev/null 2>&1; }

sec "META"
echo "dikumpulkan : $(date -Is)"
echo "oleh        : $(id -un)@$(hostname -f 2>/dev/null || hostname)"
[ "$(id -u)" -ne 0 ] && echo "PERINGATAN  : bukan root — dmidecode/smartctl/ipmitool akan kosong"

sec "IDENTITAS"
run hostname -f
for f in system-manufacturer system-product-name system-serial-number \
         baseboard-manufacturer baseboard-product-name chassis-type \
         bios-version bios-release-date; do
	printf '%-26s: %s\n' "$f" "$(dmidecode -s "$f" 2>/dev/null)"
done
run uptime
echo "--- \$ /etc/os-release ---"; head -5 /etc/os-release
run uname -a

sec "CPU"
run lscpu
echo "--- \$ topologi NUMA ---"; have numactl && numactl --hardware 2>&1
echo "--- \$ governor ---"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "(tidak ada cpufreq)"

sec "MEMORY"
run free -h
echo "--- \$ dmidecode -t memory ---"
dmidecode -t memory 2>/dev/null |
	grep -E 'Size:|Locator:|Type:|Speed:|Manufacturer:|Part Number:|Rank:' |
	grep -v 'No Module Installed'
echo "--- \$ hugepages ---"; grep -i huge /proc/meminfo

sec "GPU"
if have nvidia-smi; then
	run nvidia-smi
	echo "--- \$ nvidia-smi -L ---"; nvidia-smi -L 2>&1
	echo "--- \$ detail per-GPU ---"
	nvidia-smi --query-gpu=index,name,serial,uuid,pci.bus_id,memory.total,driver_version,vbios_version,power.limit,temperature.gpu \
		--format=csv 2>&1
	echo "--- \$ topologi GPU ---"; nvidia-smi topo -m 2>&1
	echo "--- \$ persistence & ECC ---"
	nvidia-smi --query-gpu=index,persistence_mode,ecc.mode.current,compute_mode --format=csv 2>&1
elif have rocm-smi; then
	run rocm-smi
else
	echo "(tidak ada nvidia-smi / rocm-smi — kemungkinan node tanpa GPU)"
fi
echo "--- \$ GPU di PCI ---"; lspci 2>/dev/null | grep -Ei 'vga|3d|display'
echo "--- \$ CUDA ---"; have nvcc && nvcc --version 2>&1 | tail -2

sec "STORAGE-LOKAL"
run lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL,ROTA,MOUNTPOINT
run df -h -x tmpfs -x devtmpfs
echo "--- \$ mdadm ---"; cat /proc/mdstat 2>/dev/null; have mdadm && mdadm --detail /dev/md* 2>/dev/null
echo "--- \$ ZFS (kalau ada) ---"; have zpool && { zpool list 2>&1; zpool status 2>&1; }
echo "--- \$ LVM ---"; have vgs && { vgs 2>/dev/null; lvs 2>/dev/null; }
echo "--- \$ smartctl per-disk ---"
for d in /dev/sd? /dev/nvme?n1; do
	[ -e "$d" ] || continue
	echo "== $d =="
	smartctl -i -H "$d" 2>/dev/null |
		grep -Ei 'Model|Serial|Capacity|Rotation|health|Firmware'
	smartctl -A "$d" 2>/dev/null |
		grep -Ei 'Percentage_Used|Media_Wearout|Wear_Leveling|Reallocated|Pending|Power_On_Hours|Data_Units_Written|Available_Spare|Temperature'
done
echo "--- \$ isi /scratch ---"
[ -d /scratch ] && { du -sh /scratch 2>/dev/null; ls -1 /scratch 2>/dev/null | head -20; } || echo "(/scratch tidak ada)"

sec "MOUNT-REMOTE"
echo "--- \$ mount NFS/CIFS aktif ---"
mount | grep -E 'type (nfs|nfs4|cifs)' || echo "(tidak ada mount jaringan)"
echo "--- \$ /etc/fstab (baris jaringan) ---"
grep -E 'nfs|cifs' /etc/fstab 2>/dev/null || echo "(tidak ada di fstab)"
echo "--- \$ nfsstat ---"; have nfsstat && nfsstat -m 2>&1 | head -40

sec "NETWORK"
run ip -br address
run ip -br link
run ip route
echo "--- \$ speed/mac/mtu per-nic ---"
for i in $(ls /sys/class/net | grep -Ev '^(lo|veth|tap|fw|bonding_masters|docker|br-)'); do
	printf '%-10s speed=%-8s mac=%-18s mtu=%s\n' \
		"$i" "$(cat /sys/class/net/$i/speed 2>/dev/null)" \
		"$(cat /sys/class/net/$i/address 2>/dev/null)" \
		"$(cat /sys/class/net/$i/mtu 2>/dev/null)"
done
echo "--- \$ bonding ---"; cat /proc/net/bonding/* 2>/dev/null | head -40
echo "--- \$ resolv.conf ---"; grep -v '^#' /etc/resolv.conf 2>/dev/null
echo "--- \$ NIC di PCI ---"; lspci 2>/dev/null | grep -Ei 'ethernet|infiniband'

sec "IPMI"
# Catatan: 'lan print' TIDAK menampilkan password, hanya konfigurasi jaringan BMC.
run ipmitool lan print 1
run ipmitool mc info

sec "SLURM"
if have sinfo; then
	run sinfo -N -l
	run scontrol show node
	echo "--- \$ partisi ---"; scontrol show partition 2>&1
	echo "--- \$ job berjalan ---"; squeue -o '%.8i %.9P %.20j %.8u %.2t %.10M %.6D %R' 2>&1 | head -30
	echo "--- \$ versi ---"; sinfo --version 2>&1
	echo "--- \$ slurm.conf (baris node/partition) ---"
	grep -E '^(NodeName|PartitionName|ClusterName|SlurmctldHost)' /etc/slurm/slurm.conf 2>/dev/null
else
	echo "(Slurm tidak terpasang di node ini)"
fi

sec "SOFTWARE-STACK"
echo "--- \$ compiler ---"; have gcc && gcc --version | head -1
have gfortran && gfortran --version | head -1
echo "--- \$ python ---"; have python3 && python3 --version
echo "--- \$ conda ---"
if have conda; then
	conda --version 2>&1
	echo "-- env --"; conda env list 2>&1
else
	for p in /opt/conda /opt/miniconda3 /opt/miniforge3 /usr/local/conda; do
		[ -d "$p" ] && { echo "ditemukan di $p"; ls -1 "$p/envs" 2>/dev/null; }
	done
	echo "(conda tidak ada di PATH)"
fi
echo "--- \$ container runtime ---"
have singularity && singularity --version
have apptainer && apptainer --version
have docker && docker --version
have podman && podman --version
echo "--- \$ image .sif ---"
for p in /opt/containers /opt/sif /srv/containers; do
	[ -d "$p" ] && { echo "== $p =="; ls -lh "$p"/*.sif 2>/dev/null | head -20; }
done
echo "--- \$ environment modules (Lmod) ---"
have module && module avail 2>&1 | head -40 || echo "(Lmod tidak aktif di shell non-interaktif)"
ls -1 /etc/modulefiles /usr/share/modulefiles /opt/modulefiles 2>/dev/null | head -20

sec "MONITORING"
echo "--- \$ exporter / agent ---"
for s in node_exporter nvidia_dcgm_exporter prometheus-node-exporter zabbix-agent zabbix-agent2 netdata telegraf collectd; do
	st=$(systemctl is-active "$s" 2>/dev/null)
	[ -n "$st" ] && [ "$st" != "inactive" ] && printf '%-28s %s\n' "$s" "$st"
done
echo "--- \$ port listening ---"
have ss && ss -tlnp 2>/dev/null | head -25

sec "SERVICES"
run systemctl --failed --no-pager
echo "--- \$ service kunci ---"
for s in slurmd slurmctld munge nfs-client.target nvidia-persistenced sshd chronyd ntpd systemd-timesyncd; do
	st=$(systemctl is-active "$s" 2>/dev/null)
	[ -n "$st" ] && printf '%-24s %s\n' "$s" "$st"
done
echo "--- \$ waktu / NTP ---"; timedatectl 2>&1 | head -8

sec "KEAMANAN"
echo "--- \$ sshd (opsi terpilih) ---"
grep -E '^(Port|PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|AllowUsers|AllowGroups)' \
	/etc/ssh/sshd_config 2>/dev/null
echo "--- \$ firewall ---"
have firewall-cmd && firewall-cmd --list-all 2>&1 | head -20
have ufw && ufw status 2>&1 | head -10
have nft && nft list ruleset 2>/dev/null | head -20
echo "--- \$ SELinux/AppArmor ---"; have getenforce && getenforce; have aa-status && aa-status --enabled && echo "AppArmor aktif"
echo "--- \$ user dengan shell login ---"
awk -F: '$7 !~ /(nologin|false)$/ {print $1" "$7}' /etc/passwd 2>/dev/null | head -20

sec "SENSOR-SUHU"
run sensors
echo "--- \$ suhu GPU ---"; have nvidia-smi && nvidia-smi --query-gpu=index,temperature.gpu,power.draw --format=csv 2>&1

sec "SELESAI"
date -Is

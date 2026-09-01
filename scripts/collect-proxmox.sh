#!/usr/bin/env bash
#
# collect-proxmox.sh — kumpulkan data inventaris dari host Proxmox VE.
#
# Semua perintah di dalamnya READ-ONLY. Script ini tidak mengubah apa pun
# di server target dan tidak pernah mencetak password, kunci, atau isi
# file kredensial.
#
# Pakai:
#   bash scripts/collect-proxmox.sh <host> [user] [ssh-key]   # via SSH
#   bash scripts/collect-proxmox.sh --local                   # langsung di host PVE
#
# Contoh:
#   bash scripts/collect-proxmox.sh 192.168.18.190 root ~/.ssh/id_proxmox > /tmp/pve-$(date +%F).txt
#
# Hasilnya dipakai untuk mengisi inventory/proxmox-nodes/<hostname>.md
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
	sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
	exit 1
fi

# -------------------------------------------------------------- pengumpulan ---
sec() { echo; echo "########## $1 ##########"; }
run() { echo "--- \$ $* ---"; "$@" 2>&1; }

sec "META"
echo "dikumpulkan : $(date -Is)"
echo "oleh        : $(id -un)@$(hostname -f 2>/dev/null || hostname)"

sec "IDENTITAS"
run hostname -f
for f in system-manufacturer system-product-name system-serial-number \
         baseboard-manufacturer baseboard-product-name chassis-type \
         bios-version bios-release-date; do
	printf '%-26s: %s\n' "$f" "$(dmidecode -s "$f" 2>/dev/null)"
done
run uptime

sec "CPU"
run lscpu

sec "MEMORY"
run free -h
echo "--- \$ dmidecode -t memory ---"
dmidecode -t memory 2>/dev/null |
	grep -E 'Size:|Locator:|Type:|Speed:|Manufacturer:|Part Number:|Rank:' |
	grep -v 'No Module Installed'

sec "DISK"
run lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL,ROTA,MOUNTPOINT
echo "--- \$ smartctl per-disk ---"
for d in /dev/sd? /dev/nvme?n1; do
	[ -e "$d" ] || continue
	echo "== $d =="
	smartctl -i -H "$d" 2>/dev/null |
		grep -Ei 'Model|Serial|Capacity|Rotation|health|Firmware'
done

sec "PCI"
run lspci -nn
echo "--- \$ perangkat penting + driver ---"
lspci -nnk 2>/dev/null | grep -A3 -Ei 'ethernet|network|3d controller|vga compatible|non-volatile|raid bus|fibre channel'
echo "--- \$ okupansi slot PCIe ---"
dmidecode -t slot 2>/dev/null | grep -E 'Designation:|Type:|Current Usage:|Bus Address:'
echo "--- \$ GPU ---"
if command -v nvidia-smi >/dev/null 2>&1; then
	nvidia-smi --query-gpu=name,memory.total,driver_version,pci.bus_id --format=csv 2>&1
else
	echo "nvidia-smi tidak terpasang di host"
	lspci -nnk 2>/dev/null | grep -A3 -Ei '3d controller|vga compatible' || echo "(tidak ada GPU terdeteksi)"
fi

sec "PVE-VERSION"
run pveversion -v
run uname -a
echo "--- \$ /etc/os-release ---"; head -5 /etc/os-release

sec "CLUSTER"
run pvecm status
run pvecm nodes

sec "NETWORK"
run ip -br address
run ip -br link
echo "--- \$ /etc/network/interfaces ---"; cat /etc/network/interfaces
run ip route
echo "--- \$ resolv.conf ---"; grep -v '^#' /etc/resolv.conf 2>/dev/null
echo "--- \$ speed/mac/mtu per-nic ---"
for i in $(ls /sys/class/net | grep -Ev '^(lo|veth|tap|fw|bonding_masters)'); do
	drv=$(basename "$(readlink -f /sys/class/net/$i/device/driver 2>/dev/null)" 2>/dev/null)
	if [ -e "/sys/class/net/$i/device" ]; then
		case "$(readlink -f /sys/class/net/$i/device)" in
			*usb*) bus=USB ;;
			*)     bus=PCI ;;
		esac
	else
		bus=virtual
	fi
	printf '%-10s speed=%-8s mac=%-18s mtu=%-6s driver=%-12s bus=%s\n' \
		"$i" "$(cat /sys/class/net/$i/speed 2>/dev/null)" \
		"$(cat /sys/class/net/$i/address 2>/dev/null)" \
		"$(cat /sys/class/net/$i/mtu 2>/dev/null)" \
		"${drv:-none}" "$bus"
done
run brctl show

sec "IPMI"
# Catatan: 'lan print' TIDAK menampilkan password, hanya konfigurasi jaringan BMC.
run ipmitool lan print 1
run ipmitool mc info

sec "ZFS"
run zpool list
run zpool status
run zfs list
run zfs get -o name,property,value compression,recordsize,volblocksize
echo "--- \$ zfs_arc_max ---"; cat /sys/module/zfs/parameters/zfs_arc_max 2>/dev/null

sec "STORAGE-PVE"
run pvesm status
echo "--- \$ /etc/pve/storage.cfg ---"; cat /etc/pve/storage.cfg 2>&1
run df -h -x tmpfs -x devtmpfs

sec "VM-LXC"
run qm list
run pct list
echo "--- \$ konfigurasi VM ---"
for f in /etc/pve/qemu-server/*.conf; do
	[ -e "$f" ] || continue
	echo "=== VM $(basename "$f" .conf) ==="; cat "$f"
done
echo "--- \$ konfigurasi LXC ---"
for f in /etc/pve/lxc/*.conf; do
	[ -e "$f" ] || continue
	echo "=== CT $(basename "$f" .conf) ==="; cat "$f"
done

sec "BACKUP"
echo "--- \$ /etc/pve/jobs.cfg ---"; cat /etc/pve/jobs.cfg 2>&1
echo "--- \$ /etc/vzdump.conf ---"; grep -Ev '^(#|$)' /etc/vzdump.conf 2>/dev/null
echo "--- \$ isi dump dir ---"; ls -lh /var/lib/vz/dump/ 2>/dev/null

sec "KEAMANAN"
echo "--- \$ firewall ---"; cat /etc/pve/firewall/*.fw 2>&1
run pveum user list
echo "--- \$ sshd (opsi terpilih) ---"
grep -E '^(Port|PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)' \
	/etc/ssh/sshd_config 2>/dev/null

sec "SERVICES"
run systemctl --failed --no-pager
for s in pve-cluster pvedaemon pveproxy pvestatd corosync; do
	printf '%-14s %s\n' "$s" "$(systemctl is-active "$s" 2>&1)"
done

sec "SENSOR"
run sensors

sec "SELESAI"
date -Is

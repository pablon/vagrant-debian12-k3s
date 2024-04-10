#!/usr/bin/env bash
##########################################################
# Description:
#   Debian 12 VM with k3s
#   Vagrant + VirtualBox driver
#
# Author: https://github.com/pablon
##########################################################

OUTPUT_DIR='/vagrant/outputs'

# ===============================================================
ROOT_PASSWD="$(cat ${OUTPUT_DIR}/root_password.txt)"
source "${OUTPUT_DIR}/.env"

# ===============================================================
# Colors:
export BOLD="\033[1;37m"
export RED="\033[1;31m"
export GREEN="\033[1;92m"
export YELLOW="\033[1;93m"
export BLUE="\033[1;94m"
export MAGENTA="\033[1;95m"
export CYAN="\033[1;96m"
export NONE="\033[0m"

# ===============================================================
# multi purpose banner
function _banner() {
  echo -e "\n${MAGENTA}==> ${BOLD}${1}${NONE}\n"
}

# ===============================================================
# base OS

APT_OPTIONS='-qqqy -o Dpkg::Progress-Fancy="0" -o APT::Color="0" -o Dpkg::Use-Pty="0"'

_banner "Updating OS"

apt-get dist-upgrade -qqqy && apt-get -qqqy update && apt-get -qqqy upgrade

_banner "Installing OS packages"
apt-get install ${APT_OPTIONS} curl wget parted procps coreutils sudo sed gawk nmap vim tree \
  htop git net-tools netcat-traditional ca-certificates gnupg lsb-release tar gzip bzip2 jq dpkg-dev || exit 1

# disable ipv6
echo -e "\nnet.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.d/99-sysctl.conf
sysctl -p
apt-get -qqqy update
apt-get -qqqy autoclean
# tweak services
systemctl restart rsyslog
# install latest k9s
K9S_LATEST="$(curl -s "https://api.github.com/repos/derailed/k9s/releases/latest" | jq -r ".tag_name")"
wget -qc "https://github.com/derailed/k9s/releases/download/${K9S_LATEST}/k9s_linux_amd64.deb" &>/dev/null
dpkg -i k9s_linux_amd64.deb  &>/dev/null && rm -f k9s_linux_amd64.deb

# ===============================================================
# resize primary partition & root filesystem

VM_DISK="/dev/$(lsblk -l | awk '/disk/ {print $1}' | head -1)"
VM_PARTITION="/dev/$(lsblk -l | grep part | awk '/\/$/ {print $1}')"
_banner "Disk & root partition size"
fdisk -l ${VM_DISK} | grep '^Disk /'
echo
df -h /
_banner "Resizing root partition & filesystem"
sync ; sync
echo 'Yes' | parted -fa optimal /dev/sda ---pretend-input-tty resizepart 1 100% &>/dev/null || exit 1
sync ; sync
resize2fs -p -F /dev/sda1 &>/dev/null || exit 1
df -h /
echo "✅"

# ===============================================================

_banner "Tweaking stuff..."

DISABLE_SVC="proc-sys-fs-binfmt_misc unattended-upgrades.service"
echo "✅ system services"
for svc in ${DISABLE_SVC} ; do
  systemctl stop ${svc} &>/dev/null
  systemctl disable ${svc} &>/dev/null
  echo " - ✅ ${svc}"
done

# adjust timezone if needed
if [ "${TIMEZONE}" ] ; then
  if [[ -f "/usr/share/zoneinfo/${TIMEZONE}" ]] ; then
    rm -f /etc/localtime && \
    ln -s "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime && \
    _banner "Timezone set to ${TIMEZONE}"
    echo "✅ system timezone => ${TIMEZONE}"
  fi
fi

# vim tweaks
update-alternatives --set editor /usr/bin/vim.basic &>/dev/null
cp -f /vagrant/files/vimrc.local /etc/vim/vimrc.local
echo "✅ /etc/vim/vimrc.local"

# env tweaks

cp -f /vagrant/files/sshd_config /etc/ssh/sshd_config
systemctl restart sshd.service
echo "✅ /etc/ssh/sshd_config"

# /etc/default/useradd
sed -i -e '/^SHELL/ s|=.*$|=/usr/bin/bash|' -e '/CREATE_MAIL_SPOOL/ s|^.*$|CREATE_MAIL_SPOOL=no|' /etc/default/useradd
echo "✅ /etc/default/useradd"

# sudoers for %sudo
cat << EOF > /etc/sudoers.d/sudo
%sudo ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/sudo
echo "✅ /etc/sudoers.d/sudo"

# logrotate
cat << EOF > /etc/logrotate.d/rsyslog
/var/log/syslog
/var/log/mail.log
/var/log/kern.log
/var/log/auth.log
/var/log/user.log
/var/log/cron.log
{
	rotate 1
	daily
	missingok
	notifempty
	compress
	delaycompress
	sharedscripts
	postrotate
		/usr/lib/rsyslog/rsyslog-rotate
	endscript
}
EOF
echo "✅ /etc/logrotate.d/rsyslog"

# bash tweaks
mkdir -p /root/bin /root/.local/bin
cat /vagrant/files/bash.bashrc >> /etc/bash.bashrc
source /etc/bash.bashrc &>/dev/null
echo "✅ /etc/bash.bashrc"

# motd
cat << EOF > /etc/motd

  ██╗  ██╗██████╗ ███████╗
  ██║ ██╔╝╚════██╗██╔════╝
  █████╔╝  █████╔╝███████╗
  ██╔═██╗  ╚═══██╗╚════██║
  ██║  ██╗██████╔╝███████║
  ╚═╝  ╚═╝╚═════╝ ╚══════╝
 Development VM Environment
Build date: $(date +%F\ %T)

EOF
echo "✅ /etc/motd"

# /etc/resolv.conf
sed -i 's|home|local|' /etc/resolv.conf
echo "✅ /etc/resolv.conf"

# script to sync VM clock on boot
cat << EOF > /usr/local/sbin/timesync
#!$(which bash)
SOURCE=google.com
if ( ping -c 1 \${SOURCE} &>/dev/null ) ; then
    echo "HWCLOCK PRE: \$(hwclock -r)"
    echo -en "SYS PRE:  \$(date)\nSYS SET:  "
    date -s "\$(wget --method=HEAD -qSO- --max-redirect=0 \${SOURCE} 2>&1 | sed -n 's/^.*Date: *//p')"
    echo "SYS POST: \$(date)"
    echo "HWCLOCK POST: \$(hwclock --systohc && hwclock -r)"
fi
EOF
chmod 750 /usr/local/sbin/timesync
/usr/local/sbin/timesync logger -t "timesync" &>/dev/null
echo "✅ /usr/local/sbin/timesync"

# crontab to sync clock on boot and every 1 hour
cat << EOF > /etc/cron.d/timesync
SHELL=$(which bash)
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
MAILTO=""
@reboot root sleep 10 && /usr/local/sbin/timesync &>/dev/null
* */1 * * * root /usr/local/sbin/timesync &>/dev/null
EOF
systemctl restart cron.service
echo "✅ /etc/cron.d/timesync"


# set root password
ROOT_PASSWD="$(echo "${ROOT_PASSWD}" | base64 -d)" ; echo -e "${ROOT_PASSWD}\n${ROOT_PASSWD}" | passwd root &>/dev/null && \
echo "✅ root passsword"

# ===============================================================
# install k3s

_banner "Installing k3s"
mkdir -p /etc/rancher/k3s
cat << EOF > /etc/rancher/k3s/config.yaml
write-kubeconfig-mode: ${K3S_KUBECONFIG_MODE}
token: ${TOKEN}
cluster-init: true
EOF

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_CHANNEL=stable \
  K3S_KUBECONFIG_MODE=${K3S_KUBECONFIG_MODE} \
  K3S_KUBECONFIG_OUTPUT=${OUTPUT_DIR}/${NODE_NAME}.yaml \
  INSTALL_K3S_EXEC="server --disable=traefik --bind-address 0.0.0.0 --node-external-ip ${EXTERNAL_IP}" sh -s -

mkdir -pm 700 "${HOME}/.kube" "/home/vagrant/.kube"
cp -vpf /etc/rancher/k3s/k3s.yaml "${HOME}/.kube/config"
cp -vpf /etc/rancher/k3s/k3s.yaml "/home/vagrant/.kube/config"
sed -i -e "/server:/ s|0.0.0.0|${EXTERNAL_IP}|" -e "11s|default|${NODE_NAME}|" -e "/current-context:/ s|default|${NODE_NAME}|" "${OUTPUT_DIR}/${NODE_NAME}.yaml"

_banner "Waiting 40s until all pods are in Running state..."
sleep 40
echo -e "✅ Done"

# ===============================================================
# print info

_banner "Network information"
ip -br a s | grep 'UP' | column -t

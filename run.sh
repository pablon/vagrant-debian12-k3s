#!/usr/bin/env bash
##########################################################
# Description:
#   Debian 12 VM with k3s
#   Vagrant + VirtualBox driver
#
# Author: https://github.com/pablon
##########################################################
# Requirements:
#   * 'vagrant' and 'VirtualBox' must be installed
##########################################################

OUTPUT_DIR="$(dirname ${0})/outputs"
[ -d "${OUTPUT_DIR}" ] || mkdir -pm 750 "${OUTPUT_DIR}"

ROOT_PASSWD="$(openssl rand -base64 24)"
EXTERNAL_IP="$(awk -F'"' '/^VM_NET_IP/ {print $2;exit}' ./Vagrantfile | xargs)"
NODE_NAME="$(awk -F'"' '/^VM_HOSTNAME/ {print $2;exit}' ./Vagrantfile | xargs)"
VM_NAME="$(awk -F'"' '/^VM_NAME/ {print $2}' Vagrantfile | xargs)"
VM_PROVIDER="$(awk -F'"' '/config\.vm\.provider/ {print $2;exit}' Vagrantfile)"

# Change timezone if needed (default: autodetect host timezone or set to Etc/UTC):
TIMEZONE="$(echo "$(ls -lo /etc/localtime | awk '{print $NF}')" | awk -F'zoneinfo/' '{print $NF}')"
[ -z "${TIMEZONE}" ] && TIMEZONE="Etc/UTC"

# write output: root password
echo "${ROOT_PASSWD}" > "${OUTPUT_DIR}/root_password.txt"

# write output: ${OUTPUT_DIR}/.env is needed by scripts/bootstrap.sh
cat << EOF > "${OUTPUT_DIR}/.env"
EXTERNAL_IP="${EXTERNAL_IP}"
K3S_KUBECONFIG_MODE=664
NODE_NAME="${NODE_NAME}"
TIMEZONE="${TIMEZONE}"
TOKEN="$(openssl rand -base64 12)"
EOF


# ===============================================================
export BOLD="\033[1;37m"
export RED="\033[1;31m"
export GREEN="\033[1;92m"
export YELLOW="\033[1;93m"
export BLUE="\033[1;94m"
export MAGENTA="\033[1;95m"
export CYAN="\033[1;96m"
export NONE="\033[0m"

# ===============================================================
# multi purpose banners
function _banner() {
  echo -e "${BLUE}==> ${NONE}[$(date +%F\ %T)] ${BOLD}${1}${NONE}\n"
}

function _error() {
  echo -e "${RED}ERROR:${NONE} ${1}\n"
  exit 1
}

# sanity checks
for i in vagrant VBoxManage ; do
  if ! ( command -v ${i} &>/dev/null ) ; then
    _error "❌ ${YELLOW}${i}${NONE} not found in \$PATH -- Aborting"
  else
    _banner "✅ ${GREEN}${i}${NONE} found: $(which ${i})"
  fi
done

# ===============================================================
if ( VBoxManage list vms | grep "${VM_NAME}" &>/dev/null ) ; then
  _error "VM ${VM_NAME} already exists:
  \t${YELLOW}$(VBoxManage list vms | grep "${VM_NAME}")${NONE}
  \nTo destroy the VM run ${MAGENTA}vagrant destroy -f\n"
  exit 1
fi

_banner "${MAGENTA}Creating [${VM_PROVIDER}] vm ${CYAN}${VM_NAME}"

# ===============================================================
_banner "${YELLOW}vagrant box update"
vagrant box update

# ===============================================================
_banner "${YELLOW}vagrant up"
vagrant up || _error "vagrant up failed!"

# ===============================================================
_banner "Running: ${YELLOW}kubectl --kubeconfig ${OUTPUT_DIR}/${NODE_NAME}.yaml get node -o wide"
kubectl --kubeconfig ${OUTPUT_DIR}/${NODE_NAME}.yaml get node -o wide ; echo

_banner "Running: ${YELLOW}kubectl --kubeconfig ${OUTPUT_DIR}/${NODE_NAME}.yaml get all -A"
kubectl --kubeconfig ${OUTPUT_DIR}/${NODE_NAME}.yaml get all -A ; echo

# ===============================================================
_banner "VM Network info:\n${YELLOW}$(vagrant ssh -- "ip -br a s | grep 'UP' | column -t | sed -e 's|^|\t|'")"
_banner "root password = ${RED}${ROOT_PASSWD}"
_banner "root password saved as ${CYAN}${OUTPUT_DIR}/root_password.txt"
_banner "KUBECONFIG saved as ${CYAN}${OUTPUT_DIR}/${NODE_NAME}.yaml"

# ===============================================================
if [ -z "${VAGRANT_SKIP_SNAPSHOT}" ] ; then
  VM_SNAPSHOT_NAME="base-$(date +%Y%m%d-%H%M%S)"
  _banner "${YELLOW}vagrant snapshot save \"${VM_SNAPSHOT_NAME}\""
  vagrant snapshot save --no-tty "${VM_SNAPSHOT_NAME}"
fi

# ===============================================================
# export VM as a VirtualBox appliance (.ova)
# _banner "Exporting ${VM_NAME} as OVA appliance"
# vagrant halt && VBoxManage export ${VM_NAME} -o ${VM_NAME}.ova

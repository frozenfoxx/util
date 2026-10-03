#!/usr/bin/env bash

# Build an Ubuntu cloud-init template on this Proxmox node, then prove it works
# by booting a throwaway clone and checking cloud-init applied its config.

set -Eeuo pipefail

# Variables
VMID=${VMID:-}
TEMPLATE_NAME=${TEMPLATE_NAME:-ubuntu-2604}
TEMPLATE_STORAGE=${TEMPLATE_STORAGE:-images}
CLONE_STORAGE=${CLONE_STORAGE:-local-lvm}
IMAGE_DIR=${IMAGE_DIR:-/opt/images}
IMAGE_BASE_URL=${IMAGE_BASE_URL:-https://cloud-images.ubuntu.com/releases/26.04/release}
IMAGE_FILE=${IMAGE_FILE:-ubuntu-26.04-server-cloudimg-amd64.img}
CUSTOM_FILE=${CUSTOM_FILE:-${TEMPLATE_NAME}-custom.img}
SSH_KEY=${SSH_KEY:-}
TEST_VMID=${TEST_VMID:-999}
TEST_NAME=${TEST_NAME:-tpl-test}
TEST_IP=${TEST_IP:-192.168.2.99}
TEST_PREFIX=${TEST_PREFIX:-24}
GATEWAY=${GATEWAY:-192.168.2.1}
REBUILD=${REBUILD:-false}

# Functions

## Print a timestamped message
log()
{
    echo "[$(date +%T)] $*"
}

## Report the command that failed, so set -e never exits silently
on_error()
{
    echo "ERROR: line $1: \"$2\" exited with status $3" >&2
}

## Print an error and exit
die()
{
    echo "ERROR: $*" >&2
    exit 1
}

## Print a VM's name, or nothing if the VMID doesn't exist
vm_name()
{
    # `qm config` exits non-zero for a missing VMID; that's an answer, not an error
    qm config "$1" 2>/dev/null | awk '/^name:/ {print $2}' || true
}

## Run a command inside the test VM through the guest agent and print its output
guest()
{
    qm guest exec "$TEST_VMID" --timeout "${GUEST_TIMEOUT:-60}" -- "$@" 2>/dev/null \
        | perl -MJSON::PP -0777 -ne 'my $r = decode_json($_); print $r->{"out-data"} // ""; print $r->{"err-data"} // ""'
}

## Check for required tools and settings
check_requirements()
{
    [ -n "$VMID" ] || die "set VMID (9002 on host-1, 9003 on host-2)"
    [ -n "$SSH_KEY" ] && [ -r "$SSH_KEY" ] || die "set SSH_KEY to a readable public key file"
    command -v virt-customize >/dev/null || die "virt-customize not found: apt install -y libguestfs-tools"
    command -v virt-cat >/dev/null || die "virt-cat not found: apt install -y libguestfs-tools"
    for cmd in qm wget sha256sum perl ssh ping; do
        command -v "$cmd" >/dev/null || die "$cmd not found"
    done
}

## Remove a previous template/test VM, only with REBUILD=true and only if the names match
remove_previous()
{
    local pair id expected name
    for pair in "${TEST_VMID}:${TEST_NAME}" "${VMID}:${TEMPLATE_NAME}"; do
        id=${pair%%:*}
        expected=${pair#*:}
        name=$(vm_name "$id")
        [ -z "$name" ] && continue
        [ "$REBUILD" = true ] || die "VMID $id ($name) already exists; rerun with REBUILD=true to replace it"
        [ "$name" = "$expected" ] || die "VMID $id is '$name', not '$expected'; refusing to destroy it"
        log "Destroying existing VM $id ($name)"
        qm stop "$id" >/dev/null 2>&1 || true
        qm destroy "$id" --purge
    done
}

## Download and verify the cloud image, then customize a fresh copy
prepare_image()
{
    mkdir -p "$IMAGE_DIR"
    cd "$IMAGE_DIR"

    log "Downloading $IMAGE_FILE (skipped if unchanged)"
    wget -q -N "$IMAGE_BASE_URL/$IMAGE_FILE" "$IMAGE_BASE_URL/SHA256SUMS" \
        || die "download from $IMAGE_BASE_URL failed"

    log "Verifying checksum"
    grep -E "[ *]${IMAGE_FILE}\$" SHA256SUMS > "${IMAGE_FILE}.sha256" \
        || die "$IMAGE_FILE not listed in SHA256SUMS"
    sha256sum -c "${IMAGE_FILE}.sha256"

    log "Customizing a fresh copy as $CUSTOM_FILE"
    cp -f "$IMAGE_FILE" "$CUSTOM_FILE"
    # net.ifnames=0 keeps the NIC named eth0 from the start. Proxmox's cloud-init
    # network config names the NIC eth0, and on 26.04 the NIC is already up by the
    # time cloud-init tries to rename ens18 -> eth0, so the rename fails as "busy".
    # shellcheck disable=SC2016 # $GRUB_CMDLINE_LINUX is expanded by update-grub in the guest
    virt-customize -a "$CUSTOM_FILE" \
        --install qemu-guest-agent \
        --write '/etc/default/grub.d/90-net-ifnames.cfg:GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX net.ifnames=0 biosdevname=0"' \
        --run-command 'update-grub' \
        --truncate /etc/machine-id

    # plain grep (not -q) reads all input, so virt-cat never gets SIGPIPE under pipefail
    virt-cat -a "$CUSTOM_FILE" /boot/grub/grub.cfg | grep 'net.ifnames=0' >/dev/null \
        || die "update-grub did not add net.ifnames=0 to /boot/grub/grub.cfg"
    log "Kernel command line now includes net.ifnames=0"
}

## Create the template: SeaBIOS + IDE cloud-init drive, the runtime the existing VMs use
create_template()
{
    log "Creating template $VMID ($TEMPLATE_NAME) on $TEMPLATE_STORAGE"
    qm create "$VMID" --name "$TEMPLATE_NAME" --ostype l26 --bios seabios --memory 2048 \
        --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
    qm set "$VMID" --scsi0 "${TEMPLATE_STORAGE}:0,import-from=${IMAGE_DIR}/${CUSTOM_FILE}"
    qm set "$VMID" --ide2 "${TEMPLATE_STORAGE}:cloudinit"
    qm set "$VMID" --boot order=scsi0
    qm set "$VMID" --serial0 socket --vga serial0
    qm set "$VMID" --agent enabled=1
    qm template "$VMID"
}

## Print what the test VM can tell us about cloud-init
diagnose()
{
    echo "----- diagnostics from test VM $TEST_VMID -----"
    guest bash -c 'cloud-init status --long; echo; cat /proc/cmdline; echo; lsblk -o NAME,TYPE,FSTYPE,LABEL; echo; tail -25 /run/cloud-init/ds-identify.log; echo; ip -br addr; echo; ls /etc/netplan/ /run/systemd/network/' \
        || echo "(guest agent unavailable)"
    echo
    echo "-----------------------------------------------"
}

## Clone the template, boot it, and check cloud-init applied network, keys and host keys
smoke_test()
{
    local i state

    if ping -c1 -W1 "$TEST_IP" >/dev/null 2>&1; then
        die "$TEST_IP already answers ping; set TEST_IP to a free address"
    fi

    log "Cloning $VMID to test VM $TEST_VMID at $TEST_IP"
    qm clone "$VMID" "$TEST_VMID" --name "$TEST_NAME" --full --storage "$CLONE_STORAGE"
    qm set "$TEST_VMID" --ipconfig0 "ip=${TEST_IP}/${TEST_PREFIX},gw=${GATEWAY}" --sshkeys "$SSH_KEY"
    qm resize "$TEST_VMID" scsi0 +10G
    qm start "$TEST_VMID"

    log "Waiting for the guest agent"
    for i in $(seq 1 60); do
        qm agent "$TEST_VMID" ping >/dev/null 2>&1 && break
        if [ "$i" -eq 60 ]; then
            die "guest agent never answered; watch the boot with: qm terminal $TEST_VMID"
        fi
        sleep 3
    done

    # Poll instead of `cloud-init status --wait`: --wait prints progress dots and can
    # outlast the guest agent's exec timeout, either of which hides the real status.
    log "Waiting for cloud-init to finish (up to 10 minutes)"
    for i in $(seq 1 120); do
        state=$(guest cloud-init status | awk '/^status:/ {print $2}' || true)
        case "$state" in
            "done"|"error"|"disabled") break ;;
        esac
        sleep 5
    done
    guest cloud-init status --long || true
    echo
    if [ "$state" != "done" ]; then
        diagnose
        die "cloud-init status is '${state:-unknown}', not 'done'; test VM $TEST_VMID left running for inspection"
    fi

    log "Verifying"
    # shellcheck disable=SC2016 # expanded inside the guest, not here
    guest bash -c 'lsb_release -ds; ip -br addr show eth0; df -h / | tail -1; echo "machine-id: $(cat /etc/machine-id)"; ls /etc/ssh/ssh_host_ed25519_key.pub; systemctl is-active qemu-guest-agent' || true
    echo
    if ! guest hostname -I | grep -wF "$TEST_IP" >/dev/null; then
        diagnose
        die "guest does not have $TEST_IP; test VM $TEST_VMID left running for inspection"
    fi

    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null "ubuntu@$TEST_IP" true 2>/dev/null; then
        log "ssh ubuntu@$TEST_IP works from this host"
    else
        log "Note: ssh from this host was refused; expected if $SSH_KEY isn't this host's own key"
    fi

    log "Smoke test passed; removing test VM $TEST_VMID"
    qm stop "$TEST_VMID"
    qm destroy "$TEST_VMID" --purge
}

# Logic

trap 'on_error "$LINENO" "$BASH_COMMAND" "$?"' ERR

check_requirements
remove_previous
prepare_image
create_template
smoke_test

log "Template $VMID ($TEMPLATE_NAME) is ready"
qm config "$VMID"

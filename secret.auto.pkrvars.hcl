skip_tls                 = true
proxmox_url              = "https://10.10.100.1:8006/api2/json"
proxmox_token_id         = "username@pve!token_name"
proxmox_token_secret     = "token_secret"
node                     = "node"
vm_id                    = "9000"
vm_name                  = "ubuntu-22.04-template"
core_number              = "2"
socket_number            = "1"
memory_size              = "2048"

vm_network_adapter       = "vmbr10"
vm_network_model         = "virtio"

vm_disk_size             = "200G"
vm_disk_type             = "scsi"
vm_disk_storage          = "local-lvm"

iso_url                 = "http://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"
iso_type                = "scsi"
iso_storage_pool        = "local"
iso_download_pve        = true
iso_checksum            = "file:https://releases.ubuntu.com/22.04/SHA256SUMS"
iso_unmount             = true
cloud_init_storage_pool = "local-lvm"

boot_key_interval       = "100ms"
boot_command            = [
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall 'ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot<enter>"
]
http_directory          = "http"
extra_packages          = "vim git curl"

skip_tls                 = true
proxmox_url              = "https://10.10.100.1:8006/api2/json" # Not required
proxmox_token_id         = "username@pve!token_name"
proxmox_token_secret     = "token_secret"
node                     = "node"
vm_id                    = "9000"
vm_name                  = "ubuntu-22.04-template"
core_number              = "2"
socket_number            = "1"
memory_size              = "2048"

vm_network_adapter       = "vmbr10"

vm_disk_size             = "200G"
vm_disk_storage          = "local-lvm"

iso_storage_pool        = "local"
cloud_init_storage_pool = "local-lvm"

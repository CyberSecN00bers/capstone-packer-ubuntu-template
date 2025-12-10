packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# --- VARIABLES (REQUIRED TO BE HERE) ---
variable "proxmox_url" {
  type = string
}

variable "proxmox_token_id" {
  type = string
}

variable "proxmox_token_secret" {
  type = string
  sensitive = true
}

variable "node" {
  type = string
  default = "pve1" # You can keep the default if you want
}

variable "vm_id" {
  type = string
}

variable "skip_tls" {
  type = bool
  default = true
}

variable "vm_name" {
  type = string
}

variable "core_number" {
  type = string
}

variable "socket_number" {
  type = string
}

variable "memory_size" {
  type = string
}

variable "vm_network_adapter" {
  type = string
}

variable "vm_network_model" {
  type = string
}

variable "vm_disk_size" {
  type = string
}

variable "vm_disk_type" {
  type = string
}

variable "vm_disk_storage" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "ssh_password" {
  type = string
  sensitive = true
}

variable "iso_url" {
  type = string
}

variable "iso_type" {
  type = string
}

variable "iso_storage_pool" {
  type = string
}

variable "iso_download_pve" {
  type = bool
}

variable "iso_checksum" {
  type = string
}

variable "iso_unmount" {
  type = bool
}

variable "cloud_init_storage_pool" {
  type = string
}

variable "boot_key_interval" {
  type = string
}

variable "boot_command" {
  type = list(string)
}

variable "http_directory" {
  type = string
}

variable "extra_packages" {
  type = string
}

# --- SOURCE (Define the VM to be built) ---
source "proxmox-iso" "vm" {
  # Connect to Proxmox
  proxmox_url = var.proxmox_url
  # Configure authentication using Token
  username = var.proxmox_token_id
  token    = var.proxmox_token_secret
  node        = var.node

  # Skip TLS verification (if using local IP address/ self-signed certs)
  insecure_skip_tls_verify = var.skip_tls

  # Basic VM configuration
  vm_id    = var.vm_id
  vm_name  = var.vm_name
  cores    = var.core_number
  memory   = var.memory_size
  sockets  = var.socket_number

  # Network & Disk configuration
  network_adapters {
    bridge = var.vm_network_adapter
    model  = var.vm_network_model
  }

  scsi_controller = "virtio-scsi-pci"
  disks {
    disk_size    = var.vm_disk_size
    storage_pool = var.vm_disk_storage
    type         = var.vm_disk_type
  }

  # ISO file (Packer will download to Proxmox if not present, or you can upload it manually)
  # iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
  # iso_checksum = "file:https://releases.ubuntu.com/22.04/SHA256SUMS"
  # iso_storage_pool = "local"
  # unmount_iso  = true

  boot_iso {
    type = var.iso_type
    iso_storage_pool = var.iso_storage_pool
    iso_download_pve = var.iso_download_pve
    iso_url  = var.iso_url
    unmount = var.iso_unmount
    iso_checksum = var.iso_checksum
  }

  qemu_agent = true
  # IMPORTANT: Create a Cloud-Init disk for the output Template
  # So that Terraform can inject IP/User later
  cloud_init              = true
  cloud_init_storage_pool = var.cloud_init_storage_pool

  # SSH config for Packer to connect and run provisioning scripts
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"

  # --- MAGIC PART (Autoinstall) ---
  boot_key_interval = var.boot_key_interval
  boot_command = var.boot_command

  # Packer will set up a temporary web server to serve the user-data file
  http_directory = var.http_directory
}

# --- BUILD ---
build {

  # Step 1: Wait for reboot and login
  sources = ["source.proxmox-iso.vm"]

  # Step 2: Install cloud-init and qemu-guest-agent
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo apt-get update",
      "sudo apt-get install -y cloud-init ${var.extra_packages}",
      "sudo apt-get clean"
    ]
  }

  # Step 3: Install Docker
  provisioner "shell" {
    inline = [
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sh get-docker.sh",
      "sudo usermod -aG docker ${var.ssh_username}",
      "rm get-docker.sh"
    ]
  }

  # Step 4: Clean up machine-id and SSH keys
  provisioner "shell" {
    inline = [
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm /var/lib/dbus/machine-id",
      "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id",
      "sudo cloud-init clean",
      "sudo rm -f /etc/ssh/ssh_host_*",
      "sudo rm -f /etc/netplan/00-installer-config.yaml"
    ]
  }
}
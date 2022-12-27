terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

variable "private_key_path" {
  description = "Path to ssh private key, which would be used to access workers"
  default     = "~/.ssh/id_rsa"
}

variable "public_key_path" {
  description = "Path to ssh public key, which would be used to access workers"
  default     = "~/.ssh/id_rsa.pub"
}

provider "yandex" {
  token     = "y0_AgAAAABnXmIqAATuwQAAAADXy1FTRNMoi3GvREGW3UmJRHw9t7fOLUo"
  cloud_id  = "myyacloud"
  folder_id = "b1g1d9s6l3sl8friluq4"
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "vm-1" {
  name = "terraform1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ju9iqf6g5bcq77jns"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = "ubuntu:${file("/opt/terraform/meta.yml")}"
    ssh-keys  = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  provisioner "remote-exec" {

    inline = [
      "sudo apt update",
      "sudo DEBIAN_FRONTEND=noninteractive apt -y install default-jdk",
      "sudo DEBIAN_FRONTEND=noninteractive apt -y install maven",
      "sudo apt -y install git",
      "cd ~/",
      "git clone https://github.com/vchevychelov/boxfuse.git",
      "cd  boxfuse/",
      "mvn package",
      "git init && cp ./target/hello-1.0.war ./ && git add --all && git commit -m \"add war\"",
      "git push https://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@github.com/vchevychelov/boxfuse.git",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.network_interface[0].nat_ip_address
    }
  }
}
resource "yandex_compute_instance" "vm-2" {
  name = "terraform2"

  resources {
    cores  = 4
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ju9iqf6g5bcq77jns"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = "ubuntu:${file("/opt/terraform/meta.txt")}"
    ssh-keys  = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  provisioner "remote-exec" {

    inline = [
      "sudo apt update",
      "sudo apt -y install default-jdk",
      "sudo apt -y install tomcat9",
      "sudo apt -y install git",
      "cd ~/",
      "git clone https://github.com/vchevychelov/boxfuse.git",
      "sudo cp ./boxfuse/hello-1.0.war /var/lib/tomcat9/webapps/",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.network_interface[0].nat_ip_address
    }
  }
  depends_on = [
    yandex_compute_instance.vm-1
  ]
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "internal_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.ip_address
}


output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

output "external_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
}



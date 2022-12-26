terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
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
    user-data = "root:${file("/opt/terraform/meta.txt")}"
  }

  provisioner "remote-exec" {

  inline = [
  "sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y",
  "sudo apt install -y openjdk11 && sudo apt install -y maven && sudo apt install -y git",
  "git clone https://github.com/vchevychelov/boxfuse.git",
  "cd /boxfuse-sample-java-war-hello/",
  "mvn package",
  "git push origin main",
  ]
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
    user-data = "root:${file("/opt/terraform/meta.txt")}"
  }

  provisioner "remote-exec" {

  inline = [
  "sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y",
  "sudo apt install -y openjdk11 && sudo apt install -y tomcat9 && sudo apt install -y git",
  "git clone https://github.com/vchevychelov/boxfuse.git",
  "sudo cp /boxfuse-sample-java-war-hello/target/hello-1.0.war /usr/local/tomcat/webapps/",
  ]
  }
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

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}
provider "yandex" {
    token     = "***"
    cloud_id  = "***"
    folder_id = "***"
    zone      = "ru-central1-a"
}


resource "yandex_compute_instance" "vm" {
  count = 2
  name = "vm${count.index}"

  resources {
    core_fraction = 20
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8jovjm8s9nem04bfv3"
      size = 5
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
  
  metadata = {
    user-data = file("./metadata.yaml")
  }

}


resource "yandex_lb_target_group" "testtr-1" {
  name      = "testtr-1"

  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.vm[0].network_interface.0.ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.vm[1].network_interface.0.ip_address
  }

}


resource "yandex_lb_network_load_balancer" "testlb-1" {
  name = "testlb1"
  listener {
    name = "my-list"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.testtr-1.id
    healthcheck {
      name = "http"
        http_options {
          port = 80
          path = "/"
        }
    }
  }
}


resource "yandex_vpc_network" "network-1"{
name = "network1"
}
resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
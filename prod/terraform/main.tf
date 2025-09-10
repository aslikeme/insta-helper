terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

##### Data #####
data "yandex_compute_image" "OS" {
  family = var.instance_os
}

                                    ###  INSTANCES ###
# prod instance #
resource "yandex_compute_instance" "prod" {
  name        = var.prod_server_name
  platform_id = var.platform_id
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "${data.yandex_compute_image.OS.id}"
      size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.prod_subnet.id
    nat       = true
  }

# пользователь и путь к ssh-ключу для подключения к серверу
  metadata = {
    ssh-keys =  "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
# прерываемая
  scheduling_policy {
    preemptible = true
  }
}

# gitlab runner instance #
resource "yandex_compute_instance" "runner" {
  name        = "git-runner"
  platform_id = var.platform_id
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "${data.yandex_compute_image.OS.id}"
      size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.prod_subnet.id
    nat       = true
  }

# пользователь и путь к ssh-ключу для подключения к серверу
  metadata = {
    ssh-keys =  "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
# прерываемая
  scheduling_policy {
    preemptible = true
  }
}

# monitoring instance #
resource "yandex_compute_instance" "monitoring" {
  name        = var.monitoring_server_name
  platform_id = var.platform_id
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "${data.yandex_compute_image.OS.id}"
      size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.prod_subnet.id
    nat       = true
  }

# пользователь и путь к ssh-ключу для подключения к серверу
  metadata = {
    ssh-keys =  "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
# прерываемая
  scheduling_policy {
    preemptible = true
  }
}

# grafana instance #
resource "yandex_compute_instance" "grafana" {
  name        = var.grafana_server_name
  platform_id = var.platform_id
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "${data.yandex_compute_image.OS.id}"
      size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.prod_subnet.id
    nat       = true
  }

# пользователь и путь к ssh-ключу для подключения к серверу
  metadata = {
    ssh-keys =  "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
# прерываемая
  scheduling_policy {
    preemptible = true
  }
}


                                        #####  VPC #####
resource "yandex_vpc_network" "vpc" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "prod_subnet" {
  zone           = var.zone
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = var.prod_subnet_cidr
}

                                          ##### DNS #####
resource "yandex_dns_zone" "main-zone" {
  name        = var.dns_zone_name
  description = var.dns_zone_desc

  labels = {
    label1 = var.dns_zone_label
  }

  zone             = var.prod_dns_domain
  public           = true
}
 
# prod load balancer recordset #
resource "yandex_dns_recordset" "lb_prod" {
  zone_id = yandex_dns_zone.main-zone.id
  name    = "@"
  type    = "A"
  ttl     = 200
  data    = [[for s in yandex_lb_network_load_balancer.lb_prod.listener: s.external_address_spec.*.address].0[0]]
}

# Prod -server #
resource "yandex_dns_recordset" "prod" {
  zone_id = yandex_dns_zone.main-zone.id
  name    = var.dns_prod_server_name
  type    = "A"
  ttl     = 200
  data    = [yandex_compute_instance.prod.network_interface.0.nat_ip_address]
}

# monitoring -server #
resource "yandex_dns_recordset" "monitoring" {
  zone_id = yandex_dns_zone.main-zone.id
  name    = var.dns_monitoring_server_name
  type    = "A"
  ttl     = 200
  data    = [yandex_compute_instance.monitoring.network_interface.0.nat_ip_address]
}

# grafana -server #
resource "yandex_dns_recordset" "grafana" {
  zone_id = yandex_dns_zone.main-zone.id
  name    = var.grafana_server_name
  type    = "A"
  ttl     = 200
  data    = [yandex_compute_instance.grafana.network_interface.0.nat_ip_address]
}

                                          ##### LOAD BALANCER #####
# load balancer prod #                                          
resource "yandex_lb_network_load_balancer" "lb_prod" {
  name = var.lb_name_prod

  listener {
    name = "prod-listener"
    port = 8080
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.tGroup.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 8080
      }
    }
  }
}

                                                    ###### TARGET GROUP ######
# target group prod #
resource "yandex_lb_target_group" "tGroup" {
  name      = var.tg_name
  region_id = var.tg_region_id

  target {
    subnet_id = "${yandex_vpc_subnet.prod_subnet.id}"
    address   = "${yandex_compute_instance.prod.network_interface.0.ip_address}"
  }

}

                                                  ##### OUTPUT #####
output "internal_ip_address_prod" {
  value = yandex_compute_instance.prod.network_interface.0.ip_address
}
output "external_ip_address_prod" {
  value = yandex_compute_instance.prod.network_interface.0.nat_ip_address
}

output "internal_ip_address_monitoring" {
  value = yandex_compute_instance.monitoring.network_interface.0.ip_address
}
output "external_ip_address_monitoring" {
  value = yandex_compute_instance.monitoring.network_interface.0.nat_ip_address
}

output "internal_ip_address_grafana" {
  value = yandex_compute_instance.grafana.network_interface.0.ip_address
}
output "external_ip_address_grafana" {
  value = yandex_compute_instance.grafana.network_interface.0.nat_ip_address
}

output "internal_ip_address_runner" {
  value = yandex_compute_instance.runner.network_interface.0.ip_address
}
output "external_ip_address_runner" {
  value = yandex_compute_instance.runner.network_interface.0.nat_ip_address
}

# generating inventory files #
resource "local_file" "inventory_infra" {
  filename = "../ansible/hosts"
  content = <<EOF
[prodServers]
  ${yandex_compute_instance.prod.network_interface.0.nat_ip_address} ansible_user=ubuntu ansible_ssh_private_key=~/.ssh/id_ed25519 vm_label=prodServer1
[runner]
  ${yandex_compute_instance.runner.network_interface.0.nat_ip_address} ansible_user=ubuntu ansible_ssh_private_key=~/.ssh/id_ed25519 vm_label=runner
[monitoring]
  ${yandex_compute_instance.monitoring.network_interface.0.nat_ip_address} ansible_user=ubuntu ansible_ssh_private_key=~/.ssh/id_ed25519 vm_label=monitoring
[grafana]
  ${yandex_compute_instance.grafana.network_interface.0.nat_ip_address} ansible_user=ubuntu ansible_ssh_private_key=~/.ssh/id_ed25519 vm_label=grafana
[prod:children]
prodServers
runner
monitoring
grafana
  EOF
}
resource "local_file" "inventory_service" {
  filename = "../../../service/ansible/hosts"
  content = <<EOF
[runnerVM]
  ${yandex_compute_instance.runner.network_interface.0.nat_ip_address} ansible_user=ubuntu ansible_ssh_private_key=~/.ssh/id_ed25519

  EOF
}
 
resource "local_file" "inventory_for_runner" {
  filename = "../../../service/ansible/ansible_export/hosts"
  content = <<EOF
[prodServers]
  ${yandex_compute_instance.prod.network_interface.0.nat_ip_address} ansible_user=ubuntu 

  EOF
}

 
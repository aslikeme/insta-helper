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

# test instance #
resource "yandex_compute_instance" "test" {
  name        = var.test_server_name
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
    subnet_id = yandex_vpc_subnet.test_subnet.id
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
  provisioner "local-exec" {
    command =" echo '[testServers]' >> ../../../service/ansible/ansible_export/hosts && echo ${self.network_interface.0.nat_ip_address} ansible_user=ubuntu   >> ../../../service/ansible/ansible_export/hosts "
  }
  provisioner "local-exec" {
    command =" echo '[testServers]' >> ../../prod/ansible/hosts && echo ${self.network_interface.0.nat_ip_address} ansible_user=ubuntu  vm_label=testServer1 >> ../../prod/ansible/hosts"
  }
}

# monitoring instance #
resource "yandex_compute_instance" "monitoring-testing" {
  name        = var.test_monitoring_server_name
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
    subnet_id = yandex_vpc_subnet.test_subnet.id
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
  provisioner "local-exec" {
    command =" echo '[monitoringTestingVM]' >> ../../prod/ansible/hosts && echo ${self.network_interface.0.nat_ip_address} ansible_user=ubuntu  vm_label=monitoringTestingVM >> ../../prod/ansible/hosts"
  }
}

# grafana instance #
resource "yandex_compute_instance" "grafana-testing" {
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
    subnet_id = yandex_vpc_subnet.test_subnet.id
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
  provisioner "local-exec" {
    command =" echo '[grafanaTestingVM]' >> ../../prod/ansible/hosts && echo ${self.network_interface.0.nat_ip_address} ansible_user=ubuntu vm_label=grafanaTestingVM >> ../../prod/ansible/hosts"
  }
  provisioner "local-exec" {
    command =" echo '[testing:children]' >> ../../prod/ansible/hosts && echo  testServers >> ../../prod/ansible/hosts && echo monitoringTestingVM  >> ../../prod/ansible/hosts && echo grafanaTestingVM >> ../../prod/ansible/hosts"
  }

}


                                        #####  VPC #####
resource "yandex_vpc_network" "vpc-testing" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "test_subnet" {
  zone           = var.zone
  network_id     = yandex_vpc_network.vpc-testing.id
  v4_cidr_blocks = var.test_subnet_cidr
}

                                          ##### DNS #####
resource "yandex_dns_zone" "main-zone" {
  name        = var.dns_zone_name
  description = var.dns_zone_desc

  labels = {
    label1 = var.dns_zone_label
  }

  #zone             = var.prod_dns_domain
  zone             = var.test_dns_domain
  public           = true
}


# monitoring -server #
resource "yandex_dns_recordset" "monitoring-testing" {
  zone_id = yandex_dns_zone.main-zone.id 
  name    = var.dns_monitoring_server_name
  type    = "A"
  ttl     = 200
  data    = [yandex_compute_instance.monitoring-testing.network_interface.0.nat_ip_address]
}

# grafana -server #
resource "yandex_dns_recordset" "grafana-testing" {
  zone_id = yandex_dns_zone.main-zone.id
  name    = var.dns_grafana_server_name
  type    = "A"
  ttl     = 200
  data    = [yandex_compute_instance.grafana-testing.network_interface.0.nat_ip_address]
}
 
# test load balancer recordset #
resource "yandex_dns_recordset" "lb_test" {
  zone_id = yandex_dns_zone.main-zone.id
  name    = "@"
  type    = "A"
  ttl     = 200
  data    = [[for s in yandex_lb_network_load_balancer.lb_test.listener: s.external_address_spec.*.address].0[0]]
}

# test -server #
resource "yandex_dns_recordset" "test" {
  zone_id = yandex_dns_zone.main-zone.id
  name    = var.dns_test_server_name
  type    = "A"
  ttl     = 200
  data    = [yandex_compute_instance.test.network_interface.0.nat_ip_address]
}
                                          ##### LOAD BALANCER #####

# load balancer test #
resource "yandex_lb_network_load_balancer" "lb_test" {
  name = var.lb_name_test

  listener {
    name = "test-listener"
    port = 8080
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.tGroup_test.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 8080
      }
    }
  }
}
                                                    ###### TARGET GROUP ######

# target group test #
resource "yandex_lb_target_group" "tGroup_test" {
  name      = var.tg_name_test
  region_id = var.tg_region_id_test

  target {
    subnet_id = "${yandex_vpc_subnet.test_subnet.id}"
    address   = "${yandex_compute_instance.test.network_interface.0.ip_address}"
  }

}


                                                  ##### OUTPUT #####

output "internal_ip_address_test" {
  value = yandex_compute_instance.test.network_interface.0.ip_address
}
output "external_ip_address_test" {
  value = yandex_compute_instance.test.network_interface.0.nat_ip_address
}

output "internal_ip_address_monitoring" {
  value = yandex_compute_instance.monitoring-testing.network_interface.0.ip_address
}
output "external_ip_address_monitoring" {
  value = yandex_compute_instance.monitoring-testing.network_interface.0.nat_ip_address
}

output "internal_ip_address_grafana" {
  value = yandex_compute_instance.grafana-testing.network_interface.0.ip_address
}
output "external_ip_address_grafana" {
  value = yandex_compute_instance.grafana-testing.network_interface.0.nat_ip_address
}

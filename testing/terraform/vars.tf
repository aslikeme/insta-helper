        ## Provider ##
# настройка  параметров провайдера #
variable "token" {
  default= "XXX"
}

variable "cloud_id" {
  default= "XXXX"
}

variable "folder_id" {
  default= "XXX"
}

variable "zone" {
  default= "ru-central1-b"
}

        ## Instance ##
# операционная система сервера 
variable "instance_os" {
  default= "ubuntu-2004-lts"
}

variable "test_server_name" {
  default= "test-server"
}
# тип инстанса сервера приложения
variable "platform_id" {
  default= "standard-v1"
}
variable "test_monitoring_server_name" {
  default = "monitoring-testing"
}
variable "grafana_server_name" {
  default = "grafana-testing"
}

        ## Network ##
# имя сети
variable "vpc_name" {
  default= "VPC-TESTING"
}

# адрес подсети test
variable "test_subnet_cidr" {
  type = list  
  default= ["192.168.11.0/24"]
}

        ## DNS  ##
# имя днс зоны prod
variable "dns_zone_name" {
  default= "my-test-public-zone"
}

# имя днс зоны test
variable "dns_test_zone_name" {
  default= "my-test-public-zone"
}
# домен prod
variable "prod_dns_domain" {
  default= "skbx-domain.ru."
}
# описание днс зоны
variable "dns_zone_desc" {
  default= "my-public-zone"
}
# метка днс зоны
variable "dns_zone_label" {
  default= "public"
}

# домен test
variable "test_dns_domain" {
  default= "testing.skbx-domain.ru."
}

# имя днс записи тестового сервера приложения
variable "dns_test_server_name" {
  default= "test-server"
}

# имя днс записи сервера мониторинга
variable "dns_monitoring_server_name" {
  default= "monitoring.testing.skbx-domain.ru."
}

# имя днс записи сервера grafana
variable "dns_grafana_server_name" {
  default= "grafana.testing.skbx-domain.ru."
}

        ## Load balancer test ##
# имя test балансировщика
variable "lb_name_test" {
  default= "test-network-load-balancer"
}

        ## Testing Target Group ##

# имя таргет группы
variable "tg_name_test" {
  default= "test-target-group"
}        

# id региона таргет группы
variable "tg_region_id_test" {
  default= "ru-central1"
}

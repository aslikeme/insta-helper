        ## Provider ##
# настройка  параметров провайдера #
variable "token" {
  default= "XXX"
}

variable "cloud_id" {
  default= "XXX"
}

variable "folder_id" {
  default= "XXXXX"
}

variable "zone" {
  default= "ru-central1-b"
}

        ## Instance ##
# операционная система сервера 
variable "instance_os" {
  default= "ubuntu-2004-lts"
}
# имя серверов прилложения 
variable "prod_server_name" {
  default= "prod-server"
}

# тип инстанса сервера приложения
variable "platform_id" {
  default= "standard-v1"
}
variable "monitoring_server_name" {
  default = "monitoring"
}
variable "grafana_server_name" {
  default = "grafana"
}


        ## Network ##
# имя сети
variable "vpc_name" {
  default= "VPC"
}
# адрес подсети prod
variable "prod_subnet_cidr" {
  type = list  
  default= ["192.168.10.0/24"]
}

        ## DNS  ##
# имя днс зоны prod
variable "dns_zone_name" {
  default= "my-prod-public-zone"
}

# описание днс зоны
variable "dns_zone_desc" {
  default= "my-public-zone"
}
# метка днс зоны
variable "dns_zone_label" {
  default= "public"
}
# домен prod
variable "prod_dns_domain" {
  default= "skbx-domain.ru."
}

# имя днс записи сервера приложения
variable "dns_prod_server_name" {
  default= "prod-server"
}

# имя днс записи сервера мониторинга
variable "dns_monitoring_server_name" {
  default= "monitoring.skbx-domain.ru."
}

# имя днс записи сервера grafana
variable "dns_grafana_server_name" {
  default= "grafana.skbx-domain.ru."
}
        ## Load balancer prod ##
# имя prod балансировщика
variable "lb_name_prod" {
  default= "prod-network-load-balancer"
}

        ## Prod Target Group ##

# имя таргет группы
variable "tg_name" {
  default= "prod-target-group"
}        

# id региона таргет группы
variable "tg_region_id" {
  default= "ru-central1"
}

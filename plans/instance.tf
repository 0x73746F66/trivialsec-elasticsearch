resource "random_string" "es_password" {
    length  = 32
    special = false
}
resource "random_string" "linode_es_password" {
    length  = 32
    special = true
}
resource "linode_instance" "es" {
  label             = local.es_hostname
  group             = "SaaS"
  tags              = ["Database", "Shared"]
  region            = local.linode_default_region
  type              = local.linode_default_type
  image             = local.linode_default_image
  authorized_keys   = length(var.public_key) == 0 ? [] : [
    var.public_key
  ]
  authorized_users  = length(var.allowed_linode_username) == 0 ? [] : [
    var.allowed_linode_username
  ]
  root_pass         = random_string.linode_es_password.result
  stackscript_id    = linode_stackscript.es.id
  stackscript_data  = {
    "FQDN"                  = local.es_hostname
    "ELASTIC_PASSWORD"      = random_string.es_password.result
    "ES_PORT"               = 8888
    "AWS_REGION"            = local.aws_default_region
    "AWS_ACCESS_KEY_ID"     = var.aws_access_key_id
    "AWS_SECRET_ACCESS_KEY" = var.aws_secret_access_key
    "ES_JAVA_OPTS"          = "-Des.cgroups.hierarchy.override=/ -Xms1g -Xmx1g"
    "VERSION"               = "7.15.1"
    "ES_SHA512"             = "84690630bc87fe2655f47500f74130e5a72bdc8b0284a7ba914258cb02b16143c221976f5227c4a520e2634cc3da5f1b1ebe311c578ca22b30561a18354746a0"
    "GPG_KEY"               = "46095ACC8548582C1A2699A9D27D666CD88E42B4"
  }
  alerts {
      cpu            = 90
      io             = 10000
      network_in     = 10
      network_out    = 10
      transfer_quota = 80
  }
}
output "es_id" {
  value = linode_instance.es.id
}
output "es_ipv4" {
  value = [for ip in linode_instance.es.ipv4 : join("/", [ip, "32"])]
}
output "es_ipv6" {
  value = linode_instance.es.ipv6
}
output "linode_password" {
  sensitive = true
  value = random_string.es_password.result
}

resource "aws_ssm_parameter" "ssm_linode_es_password" {
  name        = "/linode/${linode_instance.es.id}/linode_elasticsearch_password"
  description = join(", ", linode_instance.es.ipv4)
  type        = "SecureString"
  value       = random_string.linode_es_password.result
  tags = {
    cost-center = "saas"
  }
}
resource "aws_ssm_parameter" "ssm_es_password" {
  name        = "/Prod/Deploy/trivialsec/elasticsearch_password"
  description = join(", ", linode_instance.es.ipv4)
  type        = "SecureString"
  value       = random_string.es_password.result
  tags = {
    cost-center = "saas"
  }
}

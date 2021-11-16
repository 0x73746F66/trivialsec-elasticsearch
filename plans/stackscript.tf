data "local_file" "alpine_es" {
    filename = "${path.root}/../bin/alpine-es"
}
resource "linode_stackscript" "es" {
  label = "elasticsearch"
  description = "Installs Elasticsearch"
  script = data.local_file.alpine_es.content
  images = [local.linode_default_image]
  rev_note = "v4"
}
output "stackscript_id" {
  value = linode_stackscript.es.id
}

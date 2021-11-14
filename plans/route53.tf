resource "aws_route53_record" "a" {
    zone_id = local.route53_hosted_zone
    name    = local.es_hostname
    type    = "A"
    ttl     = 300
    records = linode_instance.es.ipv4
}
resource "aws_route53_record" "aaaa" {
    zone_id = local.route53_hosted_zone
    name    = local.es_hostname
    type    = "AAAA"
    ttl     = 300
    records = [
        element(split("/", linode_instance.es.ipv6), 0)
    ]
}

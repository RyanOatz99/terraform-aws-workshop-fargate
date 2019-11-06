output "alb_dns_name" {
  value = "http://${module.alb.dns_name}"
}
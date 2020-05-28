variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = ""
}

variable "alb_arn" {
  description = "alb arn"
  type        = string
  default     = ""
}

variable "region" {
  description = "region"
  type        = string
  default     = ""
}

variable "environment" {
  description = "environment"
  type        = string
  default     = ""
}

variable "regional_certificate_arn" {
  type = string
  description = "regional certificate to be used in api gw"
}

variable "endpoint_configuration_types" {
  type = list
  description = "endpoint_configuration_types for api gw"
  default = []
}

variable "route53_zone_id" {
  type = string
  description = "zone id to create custom domain record"
}
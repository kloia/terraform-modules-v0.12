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
  type        = string
  description = "regional certificate to be used in api gw"
}

variable "endpoint_configuration_types" {
  type        = list
  description = "endpoint_configuration_types for api gw"
  default     = []
}

variable "route53_zone_id" {
  type        = string
  description = "zone id to create custom domain record"
}

variable "authorizer_lambda_handler" {
  type        = string
  description = "zone id to create custom domain record"
}

variable "authorizer_lamba_runtime" {
  type        = string
  description = "zone id to create custom domain record"
}

variable "lambda_source_code_key" {
  type        = string
  description = "zone id to create custom domain record"
}

variable "lambda_source_code_bucket" {
  type        = string
  description = "zone id to create custom domain record"
}

variable "vpc_id" {
  type        = string
  description = "vpc id to put authorizer in"
}

variable "subnet_ids" {
  type        = list
  description = "subnet ids to put authorizer in"
  default     = []
}

variable "lambda_memory_size" {
  type = number
  description = "lambda memory size"
}

variable "lambda_timeout" {
  type = number
  description = "lambda timeout"
}

variable "lambda_environment_variables" {
  type = map(string)
  default = {}
}

variable "metrics_enabled" {
  type = bool
  description = "whether to enable metrics or not"
}

variable "data_trace_enabled" {
  type = bool
  description = "Whether to enable data trace or not"
}

variable "logging_level" {
  type = string
  description = "Logging level: OFF|ERROR|INFO"
  default = "OFF"
}
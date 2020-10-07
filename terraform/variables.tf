variable "acm_domain" {
  description = "The domain the certificate should be used is for"
}

variable "acm_domain_jobe" {
  description = "The domain the certificate should be used is for"
}

variable "profile" {
  description = "The AWS profile to use, based on the standard credentials chain"
}

variable "region" {
  description = "The region this will be run in"
}
########################### Network Config ################################
variable "vpc_id" {
  description = "ID of the VPC to use"
}

variable "private_subnets" {
  description = "IDs of the Private Subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "IDs of Public Subnets"
  type        = list(string)
}

variable "hosted_zone" {
  description = "Hosted zone name to be used as the base"
}

variable "dns_name" {
  description = "Building on the hosted zone, what URL should the address be reachable at?"
}

variable "jobe_hosted_zone" {
  description = "Hosted zone name to be used as the base for the Jobe Internal LB"
}

variable "jobe_host_zone_private" {
  description = "Is the Jobe hosted Zone private"
  default     = false
}

variable "jobe_dns_name" {
  description = "Building on the hosted zone, what URL should the address be reachable at? This may be private for extra security"
}
########################### Containers ################################

variable "moodle_image" {
  description = "What image should be used for the Moodle Container"
}

variable "moodle_skip_bootstrap" {
  description = "Should the initial bootstrap be skipped when starting Moodle?"
  default     = "no"
}

variable "moodle_sitename" {
  description = "Name for the Moodle Site"
  default     = "CodeRunner Playpen"
}

variable "jobe_image" {
  description = "What image should be used for the Jobe container(s)"
  default     = "trampgeek/jobeinabox:latest"
}

########################### DB Access ################################
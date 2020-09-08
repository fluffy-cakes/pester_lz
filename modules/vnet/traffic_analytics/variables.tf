variable "ARM_LOCATION" {
    description = "The geo location to which the resources are being deployed"
}

variable "ARM_ENVIRONMENT" {
    description = "The deployment environment acronym to which the resources are being deployed"
}

variable "ARM_SUBSCRIPTION_ID" {
    description = "Azure Subscription for deployment"
}

variable "diagnostics_map" {}

variable "location" {}

variable "netwatcher" {
    description = "(Optional) is a map with two attributes: name, rg who describes the name and rg where the netwatcher was already deployed" 
    default     = {}
}

variable "nsg" {
    description = "(Required) NSG list of objects"
}

variable "nw_config" {
    description = "(Optional) Configuration settings for network watcher."
}

variable "resource_group" {}

variable "tags" {}
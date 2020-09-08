variable "ARM_LOCATION" {
    description = "The geo location to which the resources are being deployed"
}

variable "ARM_ENVIRONMENT" {
    description = "The deployment environment acronym to which the resources are being deployed"
}

variable "ARM_SUBSCRIPTION_ID" {
    description = "Azure Subscription for deployment"
}

variable "networking_object" {
    description = "(Required) configuration object describing the networking configuration, as described in README"
}

variable "tags" {
    description = "(Required) map of tags for the deployment"
}

variable "virtual_network_rg" {
    description = "(Required) Name of the resource group where to create the vnet"
}

variable "netwatcher" {
    description = "(Optional) is a map with two attributes: name, rg who describes the name and rg where the netwatcher was already deployed" 
    default     = {}
}

variable diagnostics_map {}
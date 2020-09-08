variable "ARM_LOCATION" {
    description = "The geo location to which the resources are being deployed"
}

variable "ARM_ENVIRONMENT" {
    description = "The deployment environment acronym to which the resources are being deployed"
}

variable "ARM_SUBSCRIPTION_ID" {
    description = "Azure Subscription for deployment"
}

variable "resource_group" {
    description = "(Required) Map of the resource groups to create"
    type        = string
}

variable "subnets" {
    description = "map structure for the subnets to be created"
}

variable "tags" {
    description = "tags of the resource"
}

variable "virtual_network_name" {
    description = "name of the parent virtual network"
}
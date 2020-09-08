terraform {
    backend "azurerm" {}
}

provider "azurerm" {
    version                  = "2.18.0"
    features{}
    client_id                = var.ARM_CLIENT_ID
    client_secret            = var.ARM_CLIENT_SECRET
    subscription_id          = var.ARM_SUBSCRIPTION_ID
    tenant_id                = var.ARM_TENANT_ID
}
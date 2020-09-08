module "names" {
    source   = "../naming-standard"
    env      = var.ARM_ENVIRONMENT
    location = var.ARM_LOCATION
    subId    = var.ARM_SUBSCRIPTION_ID
}
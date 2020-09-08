variable "env" {
  description              = "Environment acronym for deployment; DEV, NPD, PRD"
}

variable "location" {
  description              = "Location for the deployment; uksouth, ukwest..."
}

variable "subId" {
  description              = "Subscription ID where the resources are being deployed; full 37 character subscription ID"
}

variable "location-map" {
  description              = "Azure location map used for naming abberviations"
  type                     = map
  default                  = {
    "Australia Central 2"  = "cau2",
    "Australia Central"    = "cau",
    "Australia East"       = "eau",
    "Australia Southeast"  = "seau",
    "australiacentral"     = "cau",
    "australiacentral2"    = "cau2",
    "australiaeast"        = "eau",
    "australiasoutheast"   = "seau",
    "Brazil South"         = "sbr",
    "brazilsouth"          = "sbr",
    "Canada Central"       = "cac",
    "Canada East"          = "eca",
    "canadacentral"        = "cac",
    "canadaeast"           = "eca",
    "Central India"        = "cin",
    "Central US"           = "cus",
    "centralindia"         = "cin",
    "centralus"            = "cus",
    "East Asia"            = "eaa",
    "East US 2"            = "eus2",
    "East US"              = "eus",
    "eastasia"             = "eaa",
    "eastus"               = "eus",
    "eastus2"              = "eus2",
    "France Central"       = "cfr",
    "France South"         = "sfr",
    "francecentral"        = "cfr",
    "francesouth"          = "sfr",
    "Germany North"        = "nge",
    "Germany West Central" = "wcge",
    "germanynorth"         = "nge",
    "germanywestcentral"   = "wcge",
    "Japan East"           = "eja",
    "Japan West"           = "wja",
    "japaneast"            = "eja",
    "japanwest"            = "wja",
    "Korea Central"        = "cko",
    "Korea South"          = "sko",
    "koreacentral"         = "cko",
    "koreasouth"           = "sko",
    "North Central US"     = "ncus",
    "North Europe"         = "eun",
    "northcentralus"       = "ncus",
    "northeurope"          = "eun",
    "South Africa North"   = "nsa",
    "South Africa West"    = "wsa",
    "South Central US"     = "scus",
    "South India"          = "sin",
    "southafricanorth"     = "nsa",
    "southafricawest"      = "wsa",
    "southcentralus"       = "scus",
    "Southeast Asia"       = "sea",
    "southeastasia"        = "sea",
    "southindia"           = "sin",
    "UAE Central"          = "cua",
    "UAE North"            = "nua",
    "uaecentral"           = "cua",
    "uaenorth"             = "nua",
    "UK South"             = "uks",
    "UK West"              = "ukw",
    "uksouth"              = "uks",
    "ukwest"               = "ukw",
    "West Central US"      = "wcus",
    "West Europe"          = "euw",
    "West India"           = "win",
    "West US 2"            = "wus2",
    "West US"              = "wus",
    "westcentralus"        = "wcus",
    "westeurope"           = "euw",
    "westindia"            = "win",
    "westus"               = "wus",
    "westus2"              = "wus2"
  }
}
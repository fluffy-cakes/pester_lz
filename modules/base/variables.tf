variable ARM_CLIENT_ID {
    description = "Client ID for Service Principal"
}

variable ARM_CLIENT_SECRET {
    description = "Client Secret for Service Principal"
}

variable ARM_ENVIRONMENT {
    description = "The deployment environment acronym to which the resources are being deployed"
    default     = "dev"
}

variable ARM_LOCATION {
    description = "The geo location to which the resources are being deployed"
    default     = "uksouth"
}

variable ARM_SUBSCRIPTION_ID {
    description = "Azure Subscription for deployment"
}

variable ARM_TENANT_ID {
    description = "Azure AD tenant identifier for Service Principal"
}


variable eventhub_list {}
variable global_settings {}
variable logging_settings {}
variable route_tables {}
variable vnet_list {}


# Azure DevOps Agent
variable "azdo_agent_count" {
    description = "The number of Azure DevOps agents to deploy"
    default     = 1
}

variable "azdo_agent_pool" {
    description = "The Azure DevOps Pool name for which this agent connects to"
}

variable "azdo_agent_install_folder" {
    description = "The location where the DevOps agent was installed"
    default     = "/vsts"
}

variable "azdo_hostname" {
    description = "The name used to identify this virtual machine as"
    default     = "azdo"
}

variable "azdo_organisation_name" {
    description = "The name of the Azure DevOps organisation. eg; 'myorganisation' in https://dev.azure.com/myorganisation"
}

variable "azdo_pat" {
    description = "The Personal Access Token for which allows this agent to connect to Azure DevOps"
}
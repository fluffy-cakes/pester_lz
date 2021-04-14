[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string]$environment,
    [ValidateNotNullOrEmpty()]
    [string]$location,
    [ValidateNotNullOrEmpty()]
    [string]$subscription
)

# Required to build out resource names dynamically for the loaded functions
$namingReqs           = @{
    environment       = $environment
    location          = $location
    subscription      = $subscription
}

$blobContainer        = "tfstate"

if ($list.length -ge 4) {
    $splitList        = @($list.split(","))
    $sctx             = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey

    foreach($item in $splitList) {
        try {
            $blob     = Get-AzStorageBlob -Context $sctx -Container $blobContainer -Blob "$item"
        } catch {
            $error
            Write-Host "$item not found, skipping"
        }

        # 'IF' statement required in case value passed in does not exist
        if ($blob) {
            $destname = $blob.name.split("/")[-1]
            Get-AzStorageBlobContent -CloudBlob $blob.ICloudBlob -Context $sctx -Destination "$destname" -Force
            Write-Host $destname
        }
    }
} else {
    $sctx             = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
    $blobs            = Get-AzStorageBlob -Context $sctx -Container $blobContainer -Blob "*"
    foreach($blob in $blobs) {
        $destname     = $blob.name.split("/")[-1]
        Get-AzStorageBlobContent -CloudBlob $blob.ICloudBlob -Context $sctx -Destination "$destname" -Force
        Write-Host $destname
    }
}

$fileList             = Get-ChildItem -Path "./" -Filter *.tfstate -File

foreach ($file in $filelist) {
    $infrastructure   = Get-Content $file.name | ConvertFrom-Json
    $filename         = $file.name.split("/")[-1]
    Describe "Azure Landing Zone $filename" {
        foreach($resource in $infrastructure.resources) {

            if(($resource.type -eq "azurerm_eventhub") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_eventhub($resource)
            }

            if(($resource.type -eq "azurerm_eventhub_namespace") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_eventhub_namespace($resource)
            }

            if(($resource.type -eq "azurerm_firewall") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_fw($resource)
            }

            if(($resource.type -eq "azurerm_firewall_network_rule_collection") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_fw_rules($resource)
            }

            if(($resource.type -eq "azurerm_key_vault") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_kv($resource)
            }

            if(($resource.type -eq "azurerm_lb") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_lb($resource)
            }

            if(($resource.type -eq "azurerm_lb_backend_address_pool") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_lb_backend_address_pool($resource)
            }

            if(($resource.type -eq "azurerm_lb_probe") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_lb_probe($resource)
            }

            if(($resource.type -eq "azurerm_lb_rule") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_lb_rule($resource)
            }

            if(($resource.type -eq "azurerm_log_analytics_workspace") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_log_analytics_workspace($resource)
            }

            if(($resource.type -eq "azurerm_network_interface") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_network_interface($resource)
            }

            if(($resource.type -eq "azurerm_network_interface_backend_address_pool_association") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_network_interface_association($resource)
            }

            if(($resource.type -eq "azurerm_network_security_group") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_nsg($resource)
            }

            if(($resource.type -eq "azurerm_policy_assignment") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_policy_assignment($resource)
            }

            if(($resource.type -eq "azurerm_policy_definition") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_policy_definition($resource)
            }

            if(($resource.type -eq "azurerm_policy_remediation") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_policy_remediation($resource)
            }

            if(($resource.type -eq "azurerm_public_ip") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_public_ip($resource)
            }

            if(($resource.type -eq "azurerm_resource_group") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_resource_group($resource)
            }

            if(($resource.type -eq "azurerm_route_table") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_routes($resource)
            }

            if(($resource.type -eq "azurerm_security_center_workspace") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_security_center_workspace($resource)
            }

            if(($resource.type -eq "azurerm_storage_account") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_storage_account($resource)
            }

            if(($resource.type -eq "azurerm_subnet_network_security_group_association") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_nsg_subnet_association($resource)
            }

            if(($resource.type -eq "azurerm_subnet_route_table_association") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_route_association($resource)
            }

            if(($resource.type -eq "azurerm_subnet") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_subnet($resource)
            }

            if(($resource.type -eq "azurerm_virtual_machine") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_virtual_machine($resource)
            }

            if(($resource.type -eq "azurerm_virtual_machine_ext") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_virtual_machine($resource)
            }

            if(($resource.type -eq "azurerm_virtual_machine_scale_set") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_virtual_machine_scale_set($resource)
            }

            if(($resource.type -eq "azurerm_virtual_network") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azure_virtual_network($resource)
            }

            if(($resource.type -eq "azurerm_virtual_network_peering") `
                -and ($resource.mode -ne "data") `
                -and ($resource.provider -eq "provider.azurerm")) {
                    Write-Host $resource.type
                    check_tf_azure_virtual_network_peering($resource)
            }

            if(($resource.type -eq "azurerm_dns_zone") `
            -and ($resource.mode -ne "data")) {
                Write-Host $resource.type
                check_tf_azurerm_dns_zone($resource)
            }

            if(($resource.type -eq "azurerm_private_dns_zone") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azurerm_private_dns_zone($resource)
            }

            if(($resource.type -eq "azurerm_private_dns_zone_virtual_network_link") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azurerm_private_dns_zone_virtual_network_link($resource)
            }


            # Below added by PR

            if(($resource.type -eq "azurerm_firewall_nat_rule_collection") `
                -and ($resource.mode -ne "data")) {
                    $resourceTypes += $resource.type
                    check_tf_azure_fw_nat_rules($resource)
            }

            if(($resource.type -eq "azurerm_bastion_host") `
                -and ($resource.mode -ne "data")) {
                    $resourceTypes += $resource.type
                    check_tf_azurerm_bastion_host($resource)
            }

            if(($resource.type -eq "azurerm_application_gateway") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azurerm_application_gateway($resource)
            }

            if(($resource.type -eq "azurerm_dns_a_record") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.type
                    check_tf_azurerm_dns_a_record($resource)
            }

            if(($resource.type -eq "azurerm_dns_caa_record") `
                -and ($resource.mode -ne "data")) {
                    Write-Host $resource.types
                    check_tf_azurerm_dns_caa_record($resource)
            }
        }
    }
}


# Imported function runs done by Switch statement, now. Will adjust when have time

# foreach ($file in $filelist) {
#     $infrastructure = Get-Content $file.name | ConvertFrom-Json
#     $filename       = $file.name.split("/")[-1]
#     Describe "Azure Landing Zone $filename" {
#         foreach ($resource in ($infrastructure.resources | Where-Object { $_.mode -ne "data" })) {

#             Write-Host $resource.type

#             switch ($resource.type) {
#                 "azurerm_application_insights"                               { check_tf_azure_app_insights                  ($resource)          }
#                 "azurerm_app_service_plan"                                   { check_tf_azure_app_service_plan              ($resource)          }
#                 "azurerm_dns_zone"                                           { check_tf_azure_dns                           ($resource)          }
#                 "azurerm_eventhub"                                           { check_tf_azure_eventhub                      ($resource)          }
#                 "azurerm_eventhub_namespace"                                 { check_tf_azure_eventhub_namespace            ($resource)          }
#                 "azurerm_firewall"                                           { check_tf_azure_fw                            ($resource)          }
#                 "azurerm_firewall_network_rule_collection"                   { check_tf_azure_fw_rules                      ($resource)          }
#                 "azurerm_function_app"                                       { check_tf_azure_function_app                  ($resource)          }
#                 "azurerm_key_vault"                                          { check_tf_azure_kv                            ($resource)          }
#                 "azurerm_lb"                                                 { check_tf_azure_lb                            ($resource)          }
#                 "azurerm_lb_backend_address_pool"                            { check_tf_azure_lb_backend_address_pool       ($resource)          }
#                 "azurerm_lb_probe"                                           { check_tf_azure_lb_probe                      ($resource)          }
#                 "azurerm_lb_rule"                                            { check_tf_azure_lb_rule                       ($resource)          }
#                 "azurerm_log_analytics_workspace"                            { check_tf_azure_log_analytics_workspace       ($resource)          }
#                 "azurerm_network_interface"                                  { check_tf_azure_network_interface             ($resource)          }
#                 "azurerm_network_interface_backend_address_pool_association" { check_tf_azure_network_interface_association ($resource)          }
#                 "azurerm_network_security_group"                             { check_tf_azure_nsg                           ($resource)          }
#                 "azurerm_private_dns_zone"                                   { check_tf_azure_dns_private                   ($resource)          }
#                 "azurerm_private_dns_a_record"                               { check_tf_azure_dns_private_record_a          ($resource)          }
#                 "azurerm_private_dns_cname_record"                           { check_tf_azure_dns_private_record_cname      ($resource)          }
#                 "azurerm_private_dns_zone_virtual_network_link"              { check_tf_azure_dns_private_vnet_link         ($resource)          }
#                 "azurerm_policy_assignment"                                  { check_tf_azure_policy_assignment             ($resource)          }
#                 "azurerm_policy_definition"                                  { check_tf_azure_policy_definition             ($resource)          }
#                 "azurerm_policy_remediation"                                 { check_tf_azure_policy_remediation            ($resource)          }
#                 "azurerm_public_ip"                                          { check_tf_azure_public_ip                     ($resource)          }
#                 "azurerm_resource_group"                                     { check_tf_azure_resource_group                ($resource)          }
#                 "azurerm_route_table"                                        { check_tf_azure_routes -namingReqs $namingReqs -resource $resource }
#                 "azurerm_security_center_workspace"                          { check_tf_azure_security_center_workspace     ($resource)          }
#                 "azurerm_storage_account"                                    { check_tf_azure_storage_account               ($resource)          }
#                 "azurerm_subnet_network_security_group_association"          { check_tf_azure_nsg_subnet_association        ($resource)          }
#                 "azurerm_subnet_route_table_association"                     { check_tf_azure_route_association             ($resource)          }
#                 "azurerm_subnet"                                             { check_tf_azure_subnet                        ($resource)          }
#                 "azurerm_virtual_machine"                                    { check_tf_azure_virtual_machine               ($resource)          }
#                 "azurerm_virtual_machine_ext"                                { check_tf_azure_virtual_machine               ($resource)          }
#                 "azurerm_virtual_machine_scale_set"                          { check_tf_azure_virtual_machine_scale_set     ($resource)          }
#                 "azurerm_virtual_network"                                    { check_tf_azure_virtual_network               ($resource)          }
#                 "azurerm_virtual_network_peering"                            {
#                     if ($resource.instances.attributes.id.Contains($subscription)) {
#                         check_tf_azure_virtual_network_peering ($resource)
#                     }
#                 }
#             }
#         }
#     }
# }

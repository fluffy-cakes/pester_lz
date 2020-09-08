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
        }
    }
}
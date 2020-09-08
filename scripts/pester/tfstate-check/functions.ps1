function check_tf_azure_eventhub ($resource) {
    foreach($instance in $resource.instances) {

        $nameEvh         = $instance.attributes.name
        $evhMsgRetention = $instance.attributes.message_retention
        $evhNamespace    = $instance.attributes.namespace_name
        $evhPartCount    = $instance.attributes.partition_count
        $evhRg           = $instance.attributes.resource_group_name
        $evh             = Get-AzEventHub -Name $nameEvh -ResourceGroupName $evhRg -Namespace $evhNamespace

        It "$nameEvh should be provisioned" {
            $evh.PartitionCount           | Should -Be $evhPartCount
            $evh.MessageRetentionInDays   | Should -Be $evhMsgRetention
            $evh.Status                   | Should -Be "Active"
        }
    }
}



function check_tf_azure_eventhub_namespace ($resource) {
    foreach($instance in $resource.instances) {

        $nameEvhnm     = $instance.attributes.name
        # $evhnmLocation = $instance.attributes.location
        $evhnmSku      = $instance.attributes.sku
        $evhnm         = Get-AzEventHubNamespace -NamespaceName $nameEvhnm

        It "$nameEvhnm should be provisioned" {
            # $evhnm.Location          | Should -Be $evhnmLocation # But was:  'UK South'
            $evhnm.ProvisioningState | Should -Be "Succeeded"
            $evhnm.Sku.Name          | Should -Be $evhnmSku
        }
    }
}



function check_tf_azure_fw ($resource) {
    foreach ($instance in $resource.instances) {

        $nameFw     = $instance.attributes.name
        $fwLocation = $instance.attributes.location
        $fwRg       = $instance.attributes.resource_group_name
        $fw         = Get-AzFirewall -Name $nameFw

        It "$nameFw should be provisioned" {
            $fw.Location          | Should -Be $fwLocation
            $fw.ProvisioningState | Should -Be "Succeeded"
            $fw.ResourceGroupName | Should -Be $fwRg
        }
    }
}



function check_tf_azure_fw_rules ($resource) {
    foreach($instance in $resource.instances) {

        $nameFwRule       = $instance.attributes.name
        $fwRuleAction     = $instance.attributes.action
        $fwRulePriority   = $instance.attributes.priority
        $fwRuleId         = $instance.attributes.id
        $fwRuleFwName     = $fwRuleId.split("/")[-3]
        $fwRuleCollection = Get-AzFirewall -Name $fwRuleFwName | Select-Object -ExpandProperty NetworkRuleCollections | Where-Object {$_.Name -eq $nameFwRule}

        It "$nameFwRule should be provisioned" {
            $fwRuleCollection.Action.Type | Should -Be $fwRuleAction
            $fwRuleCollection.Priority    | Should -Be $fwRulePriority
        }

        foreach ($rule in $instance.attributes.rule) {

            $nameRule            = $rule.name
            $ruleDestinationAdd  = $rule.destination_addresses | Sort-Object
            $ruleDestinationPort = $rule.destination_ports     | Sort-Object
            $ruleProtocols       = $rule.protocols             | Sort-Object
            $ruleSourceAdd       = $rule.source_addresses      | Sort-Object
            $rule                = $fwRuleCollection.Rules     | Where-Object {$_.Name -eq $nameRule}

            It "$nameRule for `"$nameFwRule`" should be configured" {
                $rule.DestinationAddresses | Sort-Object | Should -Be $ruleDestinationAdd
                $rule.DestinationPorts     | Sort-Object | Should -Be $ruleDestinationPort
                $rule.Protocols            | Sort-Object | Should -Be $ruleProtocols
                $rule.SourceAddresses      | Sort-Object | Should -Be $ruleSourceAdd
            }
        }
    }
}



function check_tf_azure_kv ($resource) {
    foreach($instance in $resource.instances) {

        $nameKv         = $instance.attributes.name
        $kvEnableDeploy = $instance.attributes.enabled_for_deployment
        $kvEnableTempl  = $instance.attributes.enabled_for_template_deployment
        $kvLocation     = $instance.attributes.location
        $kvSku          = $instance.attributes.sku_name
        $kv             = Get-AzKeyVault -Name $nameKv

        It "$nameKv should be provisioned" {
            $kv.EnabledForDeployment         | Should -Be $kvEnableDeploy
            $kv.EnabledForTemplateDeployment | Should -Be $kvEnableTempl
            $kv.Location                     | Should -Be $kvLocation
            $kv.Sku                          | Should -Be $kvSku
            $kv.VaultName                    | Should -Be $nameKv
        }
    }
}



function check_tf_azure_lb ($resource) {
    foreach($instance in $resource.instances) {

        $nameLb          = $instance.attributes.name
        $lbLocation      = $instance.attributes.location
        $lbRg            = $instance.attributes.resource_group_name
        $lbSku           = $instance.attributes.sku
        $lb              = Get-AzLoadBalancer -Name $nameLb

        It "$nameLb should be provisioned" {
            $lb.Location          | Should -Be $lbLocation
            $lb.ProvisioningState | Should -Be "Succeeded"
            $lb.ResourceGroupName | Should -Be $lbRg
            $lb.Sku.Name          | Should -Be $lbSku
        }

        foreach($frontIpConfig in $instance.attributes.frontend_ip_configuration) {

            $nameFrontIp            = $frontIpConfig.name
            $frontIpPrvIp           = $frontIpConfig.private_ip_address
            $frontIpPrvIpAllocation = $frontIpConfig.private_ip_address_allocation
            $frontIpPubIp           = $frontIpConfig.public_ip_address_id
            $frontIpPubIpAllocation = $frontIpConfig.public_ip_prefix_id
            $frontIpSubnet          = $frontIpConfig.subnet_id
            $frontIp                = $lb.FrontendIpConfigurations

            It "$nameLb Frontend IP Configurations should be configured: $nameFrontIp" {
                $frontIp.Name                                               | Should -Be $nameFrontIp
                $frontIp.ProvisioningState                                  | Should -Be "Succeeded"
                ($frontIp.Subnet | ConvertTo-Json).contains($frontIpSubnet) | Should -Be $true
                if ($frontIpPrvIp) {
                    $frontIp.PrivateIpAddress          | Should -Be $frontIpPrvIp
                }
                if ($frontIpPrvIpAllocation) {
                    $frontIp.PrivateIpAllocationMethod | Should -Be $frontIpPrvIpAllocation
                }
                if ($frontIpPubIp) {
                    $frontIp.PublicIpAddress.Id        | Should -Be $frontIpPubIp
                }
                if ($frontIpPubIpAllocation) {
                    $frontIp.PublicIpAllocationMethod  | Should -Be $frontIpPubIpAllocation
                }
            }
        }
    }
}



function check_tf_azure_lb_backend_address_pool ($resource) {
    foreach($instance in $resource.instances) {

        $nameBePool   = $instance.attributes.name
        $bePoolLb     = $instance.attributes.loadbalancer_id
        $bePoolLbName = $bePoolLb.split("/")[-1]
        $bePool       = Get-AzLoadBalancer -Name $bePoolLbName | Get-AzLoadBalancerBackendAddressPoolConfig -Name $nameBePool

        It "$nameBePool should be provisioned" {
            $bePool.ProvisioningState | Should -Be "Succeeded"
        }
    }
}



function check_tf_azure_lb_probe ($resource) {
    foreach($instance in $resource.instances) {

        $nameProbe     = $instance.attributes.name
        $probeLb       = $instance.attributes.loadbalancer_id
        $probeLbName   = $probeLb.split("/")[-1]
        $probeNumber   = $instance.attributes.number_of_probes
        $probePort     = $instance.attributes.port
        $probeProtocol = $instance.attributes.protocol
        $probe         = Get-AzLoadBalancer -Name $probeLbName | Get-AzLoadBalancerProbeConfig -Name $nameProbe

        It "Probe $nameProbe for `"$probeLbName`" should be provisioned" {
            $probe.NumberOfProbes    | Should -Be $probeNumber
            $probe.Port              | Should -Be $probePort
            $probe.Protocol          | Should -Be $probeProtocol
            $probe.ProvisioningState | Should -Be "Succeeded"
        }
    }
}



function check_tf_azure_lb_rule ($resource) {
    foreach($instance in $resource.instances) {

        $nameRule     = $instance.attributes.name
        $ruleBePort   = $instance.attributes.backend_port
        $ruleFeConfig = $instance.attributes.frontend_ip_configuration_id
        $ruleFePort   = $instance.attributes.frontend_port
        $ruleIdle     = $instance.attributes.idle_timeout_in_minutes
        $ruleLb       = $instance.attributes.loadbalancer_id
        $ruleLbName   = $ruleLb.split("/")[-1]
        $ruleProbe    = $instance.attributes.probe_id
        $ruleProtocol = $instance.attributes.protocol
        $rule         = Get-AzLoadBalancer -Name $ruleLbName | Get-AzLoadBalancerRuleConfig -Name $nameRule

        It "Rule $nameRule for `"$ruleLbName`" should be provisioned" {
            $rule.BackendPort              | Should -Be $ruleBePort
            $rule.FrontendPort             | Should -Be $ruleFePort
            $rule.IdleTimeoutInMinutes     | Should -Be $ruleIdle
            $rule.Protocol                 | Should -Be $ruleProtocol
            ($rule.FrontendIPConfiguration | ConvertTo-Json).contains($ruleFeConfig) | Should -Be $true
            ($rule.Probe | ConvertTo-Json).contains($ruleProbe)                      | Should -Be $true
        }
    }
}



function check_tf_azure_log_analytics_solution ($resource) {
    foreach($instance in $resource.instances) {

        $nameLog      = $instance.attributes.workspace_name
        $logRg        = $instance.attributes.resource_group_name
        $logSolution  = $instance.attributes.solution_name
        $log          = Get-AzOperationalInsightsIntelligencePack -Name $nameLog -ResourceGroupName $logRg | Sort-Object Name

        It "$nameLog should contain $logSolution" {
            $log.Name | Should -Contain $logSolution
            ($log     | Sort-Object Name | Where-Object {$_.Name -eq $logSolution}).Enabled | Should -Be $true
        }
    }
}



function check_tf_azure_log_analytics_workspace ($resource) {
    foreach($instance in $resource.instances) {

        $nameLog      = $instance.attributes.name
        $logLocation  = $instance.attributes.location
        $logRetention = $instance.attributes.retention_in_days
        $logRg        = $instance.attributes.resource_group_name
        $logSku       = $instance.attributes.sku
        $log          = Get-AzOperationalInsightsWorkspace -Name $nameLog -ResourceGroupName $logRg

        It "$nameLog should be provisioned" {
            $log.Location          | Should -Be $logLocation
            $log.ProvisioningState | Should -Be "Succeeded"
            $log.Sku               | Should -Be $logSku
            $log.retentionInDays   | Should -Be $logRetention
        }
    }
}



function check_tf_azure_nsg ($resource) {
    foreach($instance in $resource.instances) {

        $nameNsg            = $instance.attributes.name

        foreach($rule in $instance.attributes.security_rule) {

            $nameRule       = $rule.name
            $ruleAccess     = $rule.access
            $ruleDestAdd    = $rule.destination_address_prefix
            $ruleDestAddX   = $rule.destination_address_prefixes
            $ruleDestPort   = $rule.destination_port_range
            $ruleSourceAdd  = $rule.source_address_prefix
            $ruleSourceAddX = $rule.source_address_prefixes | Sort-Object
            $rule           = Get-AzNetworkSecurityGroup -Name $nameNsg | Get-AzNetworkSecurityRuleConfig -Name $nameRule

            It "Rule $nameRule for `"$nameNsg`" should be properly configured" {
                $rule.Access                       | Should -Be $ruleAccess
                $rule.DestinationPortRange         | Should -Be $ruleDestPort
                if ($ruleDestAddX.count -gt 0) {
                    $rule.DestinationAddressPrefix | Sort-Object | Should -Be $ruleDestAddX
                    } else {
                    $rule.DestinationAddressPrefix | Should -Be $ruleDestAdd
                }
                if ($ruleSourceAddX.count -gt 0) {
                    $rule.SourceAddressPrefix      | Sort-Object | Should -Be $ruleSourceAddX
                    } else {
                    $rule.SourceAddressPrefix      | Should -Be $ruleSourceAdd
                }
            }
        }
    }
} # could be expanded upon



function check_tf_azure_network_interface ($resource) {
    foreach($instance in $resource.instances) {

        $nameNic = $instance.attributes.name
        $nic     = Get-AzNetworkInterface -Name $nameNic

        It "$nameNic should be provisioned" {
            $nic.ProvisioningState | Should -Be "Succeeded"
        }

        foreach ($ipConfig in $instance.attributes.ip_configuration) {

            $nameIpConfig       = $ipConfig.Name
            $ipConfigAddress    = $ipConfig.private_ip_address
            $ipConfigAllocation = $ipConfig.private_ip_address_allocation
            $ipConfigSubnet     = $ipConfig.subnet_id
            $ipConfig           = Get-AzNetworkInterface -Name $nameNic | Select-Object -ExpandProperty IpConfigurations

            It "$nameNic IP Configuration should be configured: $nameIpConfig" {
                $ipConfig.PrivateIpAddress                                    | Should -Be $ipConfigAddress
                $ipConfig.ProvisioningState                                   | Should -Be "Succeeded"
                # ($ipConfig.PrivateIpAllocationMethod).ToLower()               | Should -Be $ipConfigAllocation
                ($ipConfig.PrivateIpAllocationMethod)                         | Should -Be $ipConfigAllocation
                ($ipConfig.Subnet | ConvertTo-Json).contains($ipConfigSubnet) | Should -Be $true
            }
        }
    }
}



function check_tf_azure_network_interface_association ($resource) {
    foreach($instance in $resource.instances) {

        $beAssocId        = $instance.attributes.id
        $nameBeAssoc      = $beAssocId.split("/")[-1]
        $beAssocLbName    = $beAssocId.split("/")[-3]
        $beAssocNicConfig = $instance.attributes.ip_configuration_name
        $beAssocNic       = $instance.attributes.network_interface_id
        $beAssocNicName   = $beAssocNic.split("/")[-1]
        $beAssoc          = (Get-AzLoadBalancer -Name $beAssocLbName).BackendAddressPools

        It "$beAssocNicName should be associated to `"$beAssocLbName`"" {
            $beAssoc.Name                     | Should -Be $nameBeAssoc
            $beAssoc.ProvisioningState        | Should -Be "Succeeded"
            ($beAssoc.BackendIpConfigurations | ConvertTo-Json).contains($beAssocNicConfig) | Should -Be $true
        }
    }
}



function check_tf_azure_policy_assignment ($resource) {
    foreach($instance in $resource.instances) {

        $namePol         = $instance.attributes.name
        $polDefinitionId = $instance.attributes.policy_definition_id
        $polId           = $instance.attributes.id
        $polScope        = $instance.attributes.scope
        $pol             = Get-AzPolicyAssignment -Name $namePol

        It "$namePol should be provisioned" {
            $pol.ResourceId                    | Should -Be $polId
            $pol.Properties.PolicyDefinitionId | Should -Be $polDefinitionId
            $pol.Properties.Scope              | Should -Be $polScope
        }
    }
}



function check_tf_azure_policy_definition ($resource) {
    foreach($instance in $resource.instances) {

        $namePol = $instance.attributes.name
        $polId   = $instance.attributes.id
        $polType = $instance.attributes.policy_type
        $pol     = Get-AzPolicyDefinition -Name $namePol

        It "$namePol should be provisioned" {
            $pol.ResourceId            | Should -Be $polId
            $pol.Properties.PolicyType | Should -Be $polType
        }
    }
}



function check_tf_azure_policy_remediation ($resource) {
    foreach($instance in $resource.instances) {

        $nameRemediate  = $instance.attributes.name
        $remediateId    = $instance.attributes.id
        $remediatePol   = $instance.attributes.policy_assignment_id
        $remediate      = Get-AzPolicyRemediation -Name $nameRemediate

        It "$nameRemediate should be provisioned" {
            $remediate.ProvisioningState  | Should -Be "Succeeded"
            $remediate.Id                 | Should -Be $remediateId
            $remediate.PolicyAssignmentId | Should -Be $remediatePol
        }
    }
}



function check_tf_azure_public_ip ($resource) {
    foreach ($instance in $resource.instances) {

        $namePubip     = $instance.attributes.name
        $pubipAddress  = $instance.attributes.ip_address
        $pubipLocation = $instance.attributes.location
        $pubipRg       = $instance.attributes.resource_group_name
        $pubipSku      = $instance.attributes.sku
        $pubip         = Get-AzPublicIpAddress -Name $namePubip

        It "$namePubip should be provisioned" {
            $pubip.IpAddress         | Should -Be $pubipAddress
            $pubip.Location          | Should -Be $pubipLocation
            $pubip.ProvisioningState | Should -Be "Succeeded"
            $pubip.ResourceGroupName | Should -Be $pubipRg
            $pubip.Sku.Name          | Should -Be $pubipSku
        }
    }
}



function check_tf_azure_resource_group ($resource) {
    foreach($instance in $resource.instances) {

        $nameRg     = $instance.attributes.name
        $rgLocation = $instance.attributes.location
        $rg         = Get-AzResourceGroup -Name $nameRg

        It "$nameRg should be provisioned" {
            $rg.Location          | Should -Be $rgLocation
            $rg.ProvisioningState | Should -Be "Succeeded"
        }
    }
}



function check_tf_azure_routes ($resource) {
    foreach($instance in $resource.instances) {

        $nameRouteTb     = $instance.attributes.name
        $routeTbLocation = $instance.attributes.location
        $routeTbRg       = $instance.attributes.resource_group_name
        $routeTb         = Get-AzRouteTable -Name $nameRouteTb -ResourceGroupName $routeTbRg

        It "$nameRouteTb should be provisioned" {
            $routeTb.Location          | Should -Be $routeTbLocation
            $routeTb.ProvisioningState | Should -Be "Succeeded"
        }

        foreach ($route in $instance.attributes.route) {

            $nameRoute       = $route.name
            $routeAddHop     = $route.next_hop_in_ip_address
            $routeAddHopType = $route.next_hop_type
            $routeAddPfx     = $route.address_prefix
            $route           = Get-AzRouteTable -Name $nameRouteTb -ResourceGroupName $routeTbRg | Get-AzRouteConfig -Name $nameRoute

            It "$nameRoute for `"$nameRouteTb`" should be configured" {
                $route.AddressPrefix     | Should -Be $routeAddPfx
                $route.NextHopType       | Should -Be $routeAddHopType
                $route.ProvisioningState | Should -Be "Succeeded"
                if ($null -eq $route.NextHopIpAddress) {
                    $testString = ""
                } else {
                    $testString = $route.NextHopIpAddress
                }
                $testString | Should -Be $routeAddHop
            }

            # Hub Transit main route table should NOT go straight to internet
            $mainRouteTableHubTransit       = (namingStd @namingReqs -reference "route-table") + "-asdf"
            if (($nameRoute -eq "rt-default") `
                -and ($nameRouteTb -eq $mainRouteTableHubTransit)) {

                It "$nameRoute for `"$nameRouteTb`" should NOT go straight to the internet for next hop" {
                    $route.NextHopType | Should -Not -Be "Internet"
                }
            }

            # Spoke main route table should NOT go straight to internet
            $mainRouteTableSpoke            = (namingStd @namingReqs -reference "route-table") + "-qwer"
            if (($nameRoute -eq "rt-default") `
                -and ($nameRouteTb -eq $mainRouteTableSpoke)) {

                It "$nameRoute for `"$nameRouteTb`" should NOT go straight to the internet for next hop" {
                    $route.NextHopType | Should -Not -Be "Internet"
                }
            }
        }

        foreach ($subnet in $instance.attributes.subnets) {

            $nameSubnet = $subnet.split("/")[-1]

            It "$nameRoute should be linked to `"$nameSubnet`"" {
                ($routeTb.Subnets.Id |ConvertTo-Json).contains($subnet) | Should -Be $true
            }
        }
    }
}



function check_tf_azure_route_association ($resource) {
    foreach($instance in $resource.instances) {

        $routeId         = $instance.attributes.route_table_id
        $nameRoute       = $routeId.split("/")[-1]
        $routeSubnet     = $instance.attributes.subnet_id
        $routeSubnetName = $routeSubnet.split("/")[-1]
        $route           = Get-AzRouteTable -Name $nameRoute

        It "$nameRoute should be linked to `"$routeSubnetName`"" {
            ($route.Subnets | ConvertTo-Json).contains($routeSubnet) | Should -Be $true
        }
    }
}



function check_tf_azure_security_center_workspace ($resource) {
    foreach($instance in $resource.instances) {

        $secId    = $instance.attributes.workspace_id
        $nameSec  = $secId.split("/")[-1]
        $secScope = $instance.attributes.scope
        $sec      = Get-AzSecurityWorkspaceSetting

        It "$nameSec should be provisioned" {
            $sec.WorkspaceId | Should -Be $secId
            $sec.Scope       | Should -Be $secScope
        }
    }
}



function check_tf_azure_storage_account ($resource) {
    foreach($instance in $resource.instances) {

        $nameStorage     = $instance.attributes.name
        $storageLocation = $instance.attributes.location
        $storageRg       = $instance.attributes.resource_group_name
        # $storageSku      = $instance.attributes.account_type # this was the case for Azure Provider 1.x, but omitted in 2.x
        $storageSkuTier  = $instance.attributes.account_tier
        $storageSkuRep   = $instance.attributes.account_replication_type
        $storageSku      = $storageSkuTier + "_" +$storageSkuRep
        $storage         = Get-AzStorageAccount -Name $nameStorage -ResourceGroupName $storageRg

        It "$nameStorage should be provisioned" {
            $storage.EnableHttpsTrafficOnly | Should -Be $true
            $storage.Location               | Should -Be $storageLocation
            $storage.ProvisioningState      | Should -Be "Succeeded"
            $storage.Sku.Name               | Should -Be $storageSku
        }
    }
}



function check_tf_azure_subnet ($resource) {
    foreach ($instance in $resource.instances) {

        $nameSubnet     = $instance.attributes.name
        $subnetAddress  = $instance.attributes.address_prefix
        $subnetNsg      = $instance.attributes.network_security_group_id
        $subnetRouteTb  = $instance.attributes.route_table_id
        $subnetVnet     = $instance.attributes.virtual_network_name
        $subnet         = Get-AzVirtualNetwork  -Name $subnetVnet | Get-AzVirtualNetworkSubnetConfig | Where-Object {$_.Name -eq $nameSubnet}

        It "$nameSubnet should be provisioned" {
            $subnet.AddressPrefix               | Should -Be $subnetAddress
            $subnet.ProvisioningState           | Should -Be "Succeeded"
            if ($subnetNsg -gt 0) {
                $subnet.NetworkSecurityGroup.Id | Should -Be $subnetNsg
            }
            if ($subnetRouteTb -gt 0) {
                if ($null -eq $subnet.RouteTable.Id) {
                    $testString = ""
                } else {
                    $testString = $subnet.RouteTable.Id
                }
                $testString | Should -Be $subnetRouteTb
            }
        }
    }
}



function check_tf_azure_nsg_subnet_association ($resource) {
    foreach($instance in $resource.instances) {

        $nsgId         = $instance.attributes.network_security_group_id
        $nameNsg       = $nsgId.split("/")[-1]
        $nsgSubnet     = $instance.attributes.subnet_id
        $nsgSubnetName = $nsgSubnet.split("/")[-1]
        $nsg           = Get-AzNetworkSecurityGroup -Name $nameNsg

        It "$nameNsg should be linked to `"$nsgSubnetName`"" {
            ($nsg.Subnets | ConvertTo-Json).contains($nsgSubnet) | Should -Be $true
        }
    }
}



function check_tf_azure_virtual_machine ($resource) {
    foreach($instance in $resource.instances) {

        $nameVM     = $instance.attributes.name
        $vmLocation = $instance.attributes.location
        $vmNic      = $instance.attributes.network_interface_ids
        $vmRg       = $instance.attributes.resource_group_name
        $vm         = Get-AzVM -Name $nameVM

        It "$nameVM should be provisioned" {
            $vm.Location          | Should -Be $vmLocation
            $vm.ProvisioningState | Should -Be "Succeeded"
            $vm.ResourceGroupName | Should -Be $vmRg
            foreach($nic in $vmNic) {
                ($vm.NetworkProfile | ConvertTo-Json).contains($nic) | Should -Be $true
            }
        }
    }
}



function check_tf_azure_virtual_machine_scale_set ($resource) {
    foreach($instance in $resource.instances) {

        $nameVM       = $instance.attributes.name
        $vmImage      = $instance.attributes.storage_profile_image_reference[0].id
        $vmLocation   = $instance.attributes.location
        $vmRg         = $instance.attributes.resource_group_name
        if ($instance.attributes.network_profile.ip_configuration.count -eq 1) {
            $vmSubnet = $instance.attributes.network_profile.ip_configuration[0].subnet_id
        }
        $vmss         = Get-AzVmss -VMScaleSetName $nameVM

        It "$nameVM should be provisioned" {
            $vmss.Location                                               | Should -Be $vmLocation
            $vmss.ProvisioningState                                      | Should -Be "Succeeded"
            $vmss.ResourceGroupName                                      | Should -Be $vmRg
            $vmss.VirtualMachineProfile.StorageProfile.ImageReference.Id | Should -Be $vmImage
            if ($vmSubnet) {
                $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations.IpConfigurations.Subnet.Id | Should -Be $vmSubnet
            }
        }

        if ($instance.attributes.identity.count -gt 0) {
            foreach($identity in $instance.attributes.identity) {
                foreach($ids in $indentity.identity_ids) {
                    ($vmss.Identity.UserAssignedIdentities | ConvertTo-Json).contains($ids) | Should -Be $true
                }
            }
        }
    }
}



function check_tf_azure_virtual_machine_ext ($resource) {
    foreach($instance in $resource.instances) {

        $nameExt = $instance.attributes.name
        $extVm   = $instance.attributes.virtual_machine_name
        $extRg   = $instance.attributes.resource_group_name
        $ext     = Get-AzVMExtension -Name $nameExt -VMName $extVm -ResourceGroupName $extRg

        It "$nameExt should be provisioned" {
            $ext.ProvisioningState | Should -Be "Succeeded"
        }
    }
}



function check_tf_azure_virtual_network ($resource) {
    foreach($instance in $resource.instances) {

        $nameVnet     = $instance.attributes.name
        $vnetLocation = $instance.attributes.location
        $vnetAddress  = $instance.attributes.address_space | Sort-Object
        $vnetDNS      = $instance.attributes.dns_servers | Sort-Object
        $vnet         = Get-AzVirtualNetwork -Name $nameVnet

        It "$nameVnet should be provisioned" {
            $vnet.AddressSpace.AddressPrefixes | Sort-Object | Should -be $vnetAddress
            $vnet.DhcpOptions.DnsServers       | Sort-Object | Should -be $vnetDNS
            $vnet.Location                     | Should -Be $vnetLocation
            $vnet.Name                         | Should -Be $nameVnet
            $vnet.ProvisioningState            | Should -Be "Succeeded"
        }

        foreach($subnet in $instance.attributes.subnet) {

            $nameSubnet          = $subnet.name
            $subnetAddressPrefix = $subnet.address_prefix
            $subnetNsg           = $subnet.security_group
            $subnet              = $vnet.Subnets | Where-Object {$_.Name -eq $nameSubnet}

            It "$nameSubnet should be provisioned" {
                $subnet.AddressPrefix     | Should -Be $subnetAddressPrefix
                $subnet.ProvisioningState | Should -Be "Succeeded"
                if ($subnetNsg) {
                    $subnet.NetworkSecurityGroup.id | Should -Be $subnetNsg
                }
            }
        }
    }
}



function check_tf_azure_virtual_network_peering ($resource) {
    foreach($instance in $resource.instances) {

        $namePeer       = $instance.attributes.name
        $peerFwTraffic  = $instance.attributes.allow_forwarded_traffic
        $peerGw         = $instance.attributes.use_remote_gateways
        $peerGwTransit  = $instance.attributes.allow_gateway_transit
        $peerRg         = $instance.attributes.resource_group_name
        $peerVnet       = $instance.attributes.virtual_network_name
        $peerVnetAccess = $instance.attributes.allow_virtual_network_access
        $peerVnetRemote = $instance.attributes.remote_virtual_network_id
        $peer           = Get-AzVirtualNetworkPeering -Name $namePeer -ResourceGroupName $peerRg -VirtualNetworkName $peerVnet

        It "$namePeer should be provisioned" {
            $peer.AllowForwardedTraffic     | Should -Be $peerFwTraffic
            $peer.AllowGatewayTransit       | Should -Be $peerGwTransit
            $peer.AllowVirtualNetworkAccess | Should -Be $peerVnetAccess
            $peer.PeeringState              | Should -Be "Connected"
            $peer.ProvisioningState         | Should -Be "Succeeded"
            $peer.RemoteVirtualNetwork.Id   | Should -Be $peerVnetRemote
            $peer.ResourceGroupName         | Should -Be $peerRg
            $peer.UseRemoteGateways         | Should -Be $peerGw
            $peer.VirtualNetworkName        | Should -Be $peerVnet
        }
    }
}
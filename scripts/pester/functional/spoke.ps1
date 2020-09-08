[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string]$environment,
    [ValidateNotNullOrEmpty()]
    [string]$location,
    [ValidateNotNullOrEmpty()]
    [string]$subscription
)

$namingReqs = @{
    environment  = $environment
    location     = $location
    subscription = $subscription
}

Describe "Network"{
    Context "Basic Azure Functions" {
        It "Keyvault should be writeable" {
            keyvault                                   | Should -Be $true
        }
    }

    Context "DNS" {
        It "Artifactory NPD can be resolved" {
            artifactory_np_response_spoke              | Should -Be $true
        }
        It "Artifactory PRD can be resolved" {
            artifactory_pr_response_spoke              | Should -Be $true
        }
        if ($environment.ToLower() -eq "prd") {
            It "Bind PRD server should be functioning" {
                bind_response_prd                      | Should -Be $true
            }
        }
        if ($environment.ToLower() -ne "prd") {
            It "Bind NPD server should be functioning" {
                bind_response_npd                      | Should -Be $true
            }
        }
        It "Bind should be resolving external URLs" {
            bind_resolve_ext                           | Should -Be $true
        }
        It "Private DNS should be auto registering" {
            private_dns_resolve_spoke($namingReqs)     | Should -Be $true
        }
    }

    Context "Egress" {
        It "Blacklist sites should be blocked" {
            web_egress_blacklist                       | Should -Be $true
        }
        It "Whitelist sites should be accessible" {
            web_egress_whitelist                       | Should -Be $true
        }
        It "Egress should not be slow" {
            web_egress_whitelist_speed                 | Should -Be $true
        }
    }
}
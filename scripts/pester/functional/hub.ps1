[CmdletBinding()]
param (
    [string]$azdopat,
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

Describe "Connections"{
    Context "Basic Azure Functions" {
        It "Azure DevOps personal access token should still be working" {
            azdo_pat($azdopat)                           | Should -Be $true
        }
        It "Keyvault should be writeable" {
            keyvault                                     | Should -Be $true
        }
    }

    Context "DNS" {
        if ($environment.ToLower() -eq "prd") {
            It "Artifactory PRD can be resolved" {
                artifactory_pr_response_dns($namingReqs) | Should -Be $true
                artifactory_pr_response_ip($namingReqs)  | Should -Be $true
            }
            It "Bind PRD server should be functioning" {
                bind_response_prd                        | Should -Be $true
            }
        }
        if ($environment.ToLower() -ne "prd") {
            It "Bind NPD server should be functioning" {
                bind_response_npd                        | Should -Be $true
            }
        }
        It "Bind should be resolving external URLs" {
            bind_resolve_ext                             | Should -Be $true
        }
    }

    Context "Egress" {
        It "Blacklist sites should be blocked" {
            web_egress_blacklist                         | Should -Be $true
        }
        It "Whitelist sites should be accessible" {
            web_egress_whitelist                         | Should -Be $true
        }
        It "Egress should not be slow" {
            web_egress_whitelist_speed                   | Should -Be $true
        }
    }
}
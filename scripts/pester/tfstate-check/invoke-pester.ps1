[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string]$clientId,
    [ValidateNotNullOrEmpty()]
    [string]$environment,
    [ValidateNotNullOrEmpty()]
    [string]$location,
    [ValidateNotNullOrEmpty()]
    [string]$storageAccount,
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionName,
    [ValidateNotNullOrEmpty()]
    [string]$tenantId,
    [string]$list
)

$PSVersionTable
$ErrorActionPreference = "stop"
Get-Location

Install-Module -Name Az -AllowClobber -Confirm:$false -scope CurrentUser -Force
Install-Module -Name Az.Security -Confirm:$false -Force
Install-Module -Name Pester -RequiredVersion 4.6.0 -Force

Import-Module -Name Az
Import-Module -Name Az.Security
Import-Module -Name Pester

Write-Host "Suppress Az.Security warning message"
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

$storageKey          = $env:TERRAFORMBACKENDACCESSKEY
$passwd              = ConvertTo-SecureString "$env:ARMCLIENTSECRET" -AsPlainText -Force
$pscredential        = New-Object System.Management.Automation.PSCredential($clientId, $passwd)

Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId -Subscription $subscriptionName
$subId              = (Get-AzSubscription | Where-Object {$_.Name -eq "$subscriptionName"}).SubscriptionId
Get-AzSubscription


Write-Host "Load functions into memory"
. ../namingStd.ps1
. ./functions.ps1

Write-Host "Invoking Pester"
Invoke-Pester -Script @{
    Path             = "./tfstate-check.ps1"
    Parameters       = @{
        environment  = "$environment"
        location     = "$location"
        subscription = "$subId"
    }
} `
-OutputFile ./Infra-Pester-$subscriptionName.XML `
-OutputFormat NUnitXML


Write-Host "Listing output files"
Get-ChildItem -Path .

Write-Output "Clearing Azure credentials"
Clear-AzContext -Force
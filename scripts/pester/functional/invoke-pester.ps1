[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string]$clientId,
    [ValidateNotNullOrEmpty()]
    [string]$environment,
    [ValidateNotNullOrEmpty()]
    [string]$hubOrSpoke,
    [ValidateNotNullOrEmpty()]
    [string]$location,
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionName,
    [ValidateNotNullOrEmpty()]
    [string]$tenantId
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

$passwd           = ConvertTo-SecureString "$env:ARMCLIENTSECRET" -AsPlainText -Force
$pscredential     = New-Object System.Management.Automation.PSCredential($clientId, $passwd)

Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId -Subscription $subscriptionName
$subId            = (Get-AzSubscription | Where-Object {$_.Name -eq "$subscriptionName"}).SubscriptionId
Get-AzSubscription

Write-Host "Load functions into memory"
. ../namingStd.ps1
. ./int-func-tests.ps1

# added this line below for basic tests demo; else line 49 would be the same as line 62, and this one removed
$hubOrSpokeFile          = "./" + $hubOrSpoke + "_basic.ps1"

if ($hubOrSpoke -eq "hub") {
    Write-Host "Invoking Pester for hub"
    Invoke-Pester -Script @{
        Path             = "$hubOrSpokeFile"
        Parameters       = @{
            azdopat      = "$env:AZDOPAT"
            environment  = "$environment"
            location     = "$location"
            subscription = "$subId"
            }
        } `
        -OutputFile ./IntFunc-Pester-$subscriptionName.XML `
        -OutputFormat NUnitXML
} else {
    Write-Host "Invoking Pester for spoke"
    Invoke-Pester -Script @{
        Path             = "./$hubOrSpoke.ps1"
        Parameters       = @{
            # spoke does not need to check AzDO PAT
            environment  = "$environment"
            location     = "$location"
            subscription = "$subId"
            }
        } `
        -OutputFile ./IntFunc-Pester-$subscriptionName.XML `
        -OutputFormat NUnitXML
}

Write-Host "Listing output files"
Get-ChildItem -Path .

Write-Output "Clearing Azure credentials"
Clear-AzContext -Force
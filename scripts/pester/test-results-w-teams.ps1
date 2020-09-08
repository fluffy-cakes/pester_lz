[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string]$clientId,
    [ValidateNotNullOrEmpty()]
    [string]$environment,
    [ValidateNotNullOrEmpty()]
    [string]$location,
    [ValidateNotNullOrEmpty()]
    $pat,
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionName,
    [ValidateNotNullOrEmpty()]
    [string]$tenantId
)


$PSVersionTable
$ErrorActionPreference      = "stop"
Get-Location

# Install Azure modules
Install-Module -Name Az -AllowClobber -Confirm:$false -scope CurrentUser -Force
Import-Module -Name Az

# Log into Azure subscription
Write-Host "Logging into Azure"
$passwd                     = ConvertTo-SecureString "$env:ARMCLIENTSECRET" -AsPlainText -Force
$pscredential               = New-Object System.Management.Automation.PSCredential($clientId, $passwd)
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId -Subscription $subscriptionName
$subId                      = (Get-AzSubscription | Where-Object {$_.Name -eq "$subscriptionName"}).SubscriptionId
Get-AzSubscription

# Create parameter hash table for the Naming Standard
$namingReqs                 = @{
    environment             = $environment
    location                = $location
    subscription            = $subId
}

Write-Host "Load Naming Standard into memory"
. ./namingStd.ps1

# Build API headers
$pat                        = $pat + ":"
$b                          = [System.Text.Encoding]::UTF8.GetBytes($pat)
$authToken                  = [System.Convert]::ToBase64String($b)
$headers                    = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Basic $authToken")

# Get the pipeline ID of Pester Testing
$response                   = Invoke-WebRequest 'https://dev.azure.com/fluffypaulmackinnon/pester/_apis/pipelines?api-version=6.0-preview.1' -Method 'GET' -Headers $headers -Body $body
$pesterPipe                 = ($response.Content | ConvertFrom-Json).value | Where-Object name -eq "Pester Testing"
$pesterPipeId               = $pesterPipe        | Select-Object -ExpandProperty id

# Get the last run ID of the Pester pipeline
Write-Host "Getting the ID of the last Pester run"
$methodurl                  = "https://dev.azure.com/fluffypaulmackinnon/pester/_apis/pipelines/" + "$pesterPipeId" + "/runs?api-version=6.0-preview.1"
$response                   = Invoke-WebRequest $methodurl -Method 'GET' -Headers $headers -Body $body
$latestId                   = ($response.Content | ConvertFrom-Json).value[0].id

# Build dates to filter by; equals the last 24hrs
$dateCurrent                = (Get-Date -Format "yyyy-MM-dd")
$dateAddDay                 = (Get-Date).AddDays(1)
$dateAdd                    = Get-Date $dateAddDay -Format "yyyy-MM-dd"

# Get a list of test runs in the last 24hrs
Write-Host "Getting list of test runs"
$methodurl                  = "https://dev.azure.com/fluffypaulmackinnon/pester/_apis/test/runs?minLastUpdatedDate=" + "$dateCurrent" + "&maxLastUpdatedDate=" + "$dateAdd" + "&api-version=5.0"
$response                   = Invoke-WebRequest $methodurl -Method 'GET' -Headers $headers -Body $body

# Exit if no runs in the last 24hrs
$responseCount              = ($response.Content | ConvertFrom-Json).count
if ($responseCount -eq 0) {
    Write-Host "No runs in the last 24hrs. Exiting"
    exit 0
}

# Convert the results to PowerShell objects, and only those with the last run ID
$convert                    = ($response.Content | ConvertFrom-Json).value
$filtered                   = $convert           | Where-Object { $_.pipelineReference.pipelineId -eq $latestId }


# TEAMS POST bonus points
# TEAMS: Create the array block to paste into the body
$teamsMain_array = @()
$objMain                    = New-Object -TypeName PSObject -Property @{
    "type"                  = "TextBlock"
    "text"                  = "OMG! Pester just ran and here are the results for build ID [$latestId](https://dev.azure.com/fluffypaulmackinnon/pester/_build/results?buildId=$latestId&view=ms.vss-test-web.build-test-results-tab)"
    "wrap"                  = [bool]"true"
}
# TEAMS: Add title block to main array
$teamsMain_array            += $objMain
# TEAMS: end


# Create blank array to capture output for Event Hub
$result_array               = @()

# For each of the test subscription environment test runs, get the overall result and list all the failed tests
Write-Host "Getting results of Pester"
foreach ($test in $filtered) {
    # Build a PowerShell object to capture the results, and format accordingly
    $objTest                = New-Object -TypeName PSObject -Property @{
        Name                = "Pester Results"
        Env                 = $test.name
        BuildID             = $latestId
        Date                = $test.completedDate
    }


    # TEAMS: Create Factset object to nest each subscription result
    $obj                    = New-Object -TypeName PSObject -Property @{
        "type"              = "FactSet"
    }
    # TEAMS: Build a PowerShell object to capture the results for Teams post
    $objTeams_array         = @()
    $objTeams1 = New-Object -TypeName PSObject -Property @{
        "title"             = "Subscription"
        "value"             = [string]$test.name
    }
    $objTeams_array         += $objTeams1
    # TEAMS: end


    # Each test run has Pass/Fail statistics, grab the output of each one, add to the current test object
    foreach ($output in $test.runStatistics) {
        foreach ($result in $output) {
            $objTest  | Add-Member -NotePropertyName $result.outcome -NotePropertyValue $result.count


            # TEAMS: Add each pass/fail to Teams object
            $objTeams2      = New-Object -TypeName PSObject -Property @{
                "title"     = [string]$result.outcome
                "value"     = [string]$result.count
            }
            $objTeams_array +=$objTeams2
            # TEAMS: end
        }
    }


    # TEAMS: Add each result to Facset object as a list of results along with the title of the Subscription
    $obj | Add-Member -NotePropertyName "facts" -NotePropertyValue $objTeams_array
    # TEAMS: Add results to Teams array
    $teamsMain_array        += $obj
    # TEAMS: end


    # Create blank array to capture only the individual failed tests
    $fail_array             = @()
    $id                     = $test.id
    $methodurl              = "https://dev.azure.com/fluffypaulmackinnon/pester/_apis/test/Runs/" + "$id" + "/results?api-version=5.0"
    $response               = Invoke-WebRequest $methodurl -Method 'GET' -Headers $headers -Body $body
    $convert                = ($response.Content | ConvertFrom-Json).value
    $failed                 = $convert           | Where-Object { $_.outcome -ne "Passed" }

    # For each failed test, create a new PowerShell object with its name and when it has been failing since, then add to the array
    foreach($fail in $failed) {
        $objFail            = New-Object -TypeName PSObject -Property @{
            "Test Name"     = $fail.testCaseTitle
            "Failing Since" = $fail.failingSince.date
        }
        $fail_array         += $objFail
    }

    # Add the list of the failed tests to the test object, as an object itself (nested)
    $objTest | Add-Member -NotePropertyName Fails -NotePropertyValue $fail_array

    # Add each subscription test to the main array to accumulate all the results
    $result_array           += $objTest
}

# Create a JSON object with a depth of 3 to allow expansion of all objects
$edit                       = $result_array | ConvertTo-Json -Depth 3
Write-Host "The results from Pester are:"
$result_array


# Get the access key for the Event Hub
Write-Host "Getting access key for Event Hub"
[Reflection.Assembly]::LoadWithPartialName("System.Web")| out-null
$eventHubNamespace          = (namingStd @namingReqs -reference "event-hub-namespace") + "-diag-logs"
$eventHubResourceGroup      = (namingStd @namingReqs -reference "resource-group") + "-logging-event-hub"
$eventHub                   = (namingStd @namingReqs -reference "event-hub") + "-diag-logs"
$URI                        = "$eventHubNamespace.servicebus.windows.net/$eventHub"
$Access_Policy_Name         = "RootManageSharedAccessKey"
$Access_Policy_Key          = (Get-AzEventHubKey -ResourceGroupName "$eventHubResourceGroup" -NamespaceName "$eventHubNamespace" -AuthorizationRuleName $Access_Policy_Name).PrimaryKey

# Generate a SAS token to POST to Event Hub, token expires now +300 seconds
Write-Host "Generating Event Hub SAS token"
$Expires                    = ([DateTimeOffset]::Now.ToUnixTimeSeconds())+300
$SignatureString            = [System.Web.HttpUtility]::UrlEncode($URI)+ "`n" + [string]$Expires
$HMAC                       = New-Object System.Security.Cryptography.HMACSHA256
$HMAC.key                   = [Text.Encoding]::ASCII.GetBytes($Access_Policy_Key)
$Signature                  = $HMAC.ComputeHash([Text.Encoding]::ASCII.GetBytes($SignatureString))
$Signature                  = [Convert]::ToBase64String($Signature)
$SASToken                   = "SharedAccessSignature sr=" + [System.Web.HttpUtility]::UrlEncode($URI) + "&sig=" + [System.Web.HttpUtility]::UrlEncode($Signature) + "&se=" + $Expires + "&skn=" + $Access_Policy_Name

# Build API headers
$headers                    = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Host", "$eventHubNamespace.servicebus.windows.net")
$headers.Add("Authorization", "$SASToken")

# Generate the body to POST to Event Hub with the results from Pester
$body                       = "{ `"records`": $edit }"

# POST!
Write-Host "POSTing Pester results to Event Hub: $eventHub"
$methodurl                  = "https://" +"$URI" + "/messages?timeout=60&api-version=2014-01"
$response                   = Invoke-RestMethod $methodurl -Method 'POST' -Headers $headers -Body $body

# Event Hub does not return a result, basic test for success
if ($? -ne $true) {
    exit 1
}

Write-Output "Clearing Azure credentials"
Clear-AzContext -Force




####################
# BONUS TEAMS POST #
####################

# Add resulting JSON into final Teams post JSON with a depth of 16 to allow expansion of all objects
$teamsJson                  = Get-Content ./pester_card_input.json | ConvertFrom-Json
$teamsJson.attachments[0].content.body[1]                          | Add-Member -Name "items" -Value $teamsMain_array -MemberType NoteProperty
$editPost                   = $teamsJson                           | ConvertTo-Json -Depth 15

Write-Host "The full JSON payload is"
$editPost

$headers                    = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

# Finally, POST the output to Teams chat
$response                   = Invoke-RestMethod 'https://outlook.office.com/webhook/my-super-webhook-url' -Method 'POST' -Headers $headers -Body $editPost
$response | ConvertTo-Json
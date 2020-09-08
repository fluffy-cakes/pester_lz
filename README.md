# Running Pester Against Terraform State

For those that don't know, Pester is an extremely simple and useful PowerShell testing tool that can easily be adapted to test if Terraform has actually deployed your resources correctly by using basic assertions; which is a whole lot easier than eyeballing each one yourself. Not only can it test what you have just deployed is correct, but it can also run on a schedule to ensure that nothing has drifted away from what the Terraform state file determines as correct. On some projects I have worked with, we have run Pester on a morning schedule and POST'ed the results to both Event Hub (for which Elastic Cloud consumes) and to Microsoft Teams, so that we keep track of any resources that might have been altered outside of how we normally deploy resources.

I am basing the examples below of Pester using Azure DevOps for the pipeline runs, and that the state files for Terraform are kept in Azure storage account in a container called `tfstate`; however these practices could be altered and applied anywhere.

Before we get started, there is one important thing to note. Pester is a PowerShell module, but that doesn’t mean you can only run PowerShell commands, or that the script has to run on a Windows box. For all of my Pester testing I have run this on either an Ubuntu or RedHat machine with PowerShell 7.x installed, using Azure DevOps tasks to initiate it. In previous roles I have even used commands from Docker, JQ, and even SSH’d onto another box to run a command, grab the resulting output of that command, and use Pester to assert the result. Basically, if you’re on a Linux box, in PowerShell, and can type a command of any sort and get a result, then Pester can assert against it.

Here’s an example snapshot of just that:

<img src=".\docs\images\azure\06.png" style="zoom:50%;" />

## Azure DevOps Setup

To demonstrate Pester functioning, I have built a mini-landing zone which you can clone from this repo: asdf

You will need to:

1. Create a service connection linking to your subscription, using the naming convention `sub-<last-12-digits-of-sub-id>`. As shown [here](https://github.com/fluffy-cakes/pester_lz/tree/master/docs/images/azdo_setup/01.png)
2. Create an Agent pool called `myPool`. As shown [link](https://github.com/fluffy-cakes/pester_lz/tree/master/docs/images/azdo_setup/03.png)
   1. Create a Personal Access Token that has the following rights; `Agent Pools (Read & manage)`
3. Create a backend storage account and key vault to store the state files and subscription credential secrets. As shown [here](https://github.com/fluffy-cakes/pester_lz/tree/master/docs/images/azure/01.png), [here](https://github.com/fluffy-cakes/pester_lz/tree/master/docs/images/azure/02.png), [here](https://github.com/fluffy-cakes/pester_lz/tree/master/docs/images/azure/03.png), and [here](https://github.com/fluffy-cakes/pester_lz/tree/master/docs/images/azure/04.png).
   1. `ARMCLIENTID` = a service principal ID with contributor rights on the subscription
   2. `ARMCLIENTSECERT` = the SPs secret
   3. `ARMSUBSCRIPTIONID` = the subscription ID being deployed to
   4. `ARMTENANTID` = the tenant ID associated with the subscription
   5. `TERRAFORMBACKENDACCESSKEY` = the storage account access key where the tfstate file is kept
   6. `AZDOPAT` = the personal access token as mentioned above
   7. `AZDOPATAPI` = a personal access token with API rights for when POSTing to Event Hub (discussed further below)
4. Update the configuration YAML file that points to these values. As shown [here](https://github.com/fluffy-cakes/pester_lz/tree/master/docs/images/pipes/22.png). 
   1. Also update the Name of the subscription to the same GUI name that shows in your own subscription. The script works on the Name, not the ID, of the subscription (perhaps I should update/change this).
5. Create Azure DevOps pipelines for the following YAML files:
   If you are unsure how to do this, use the screenshots in this folder as a guide, [here](https://github.com/fluffy-cakes/pester_lz/tree/master/docs/images/pipes)
   1. `.pipelines\00_pipes\deploy_base.yml`
   2. `.pipelines\00_pipes\destroy_base.yml`
   3. `.pipelines\00_pipes\pester_testing.yml`

## Breaking Down the Pester Process

1. Install and import Pester on the running agent
2. Use service principal credentials to log into each subscription
3. Load into memory...
   1. Custom functions that test each type of resource
   2. Any naming standard function used in your Azure environment
4. Invoke Pester
   1. Download your Terraform state files (eg; from an Azure blob container)
   2. Convert each state file from JSON to a PowerShell object
   3. For each state file object
      1. For each resource type found
         1. Run the relevant preloaded function to test the resource
   4. Output the results into NUnit XML
5. Clear all Azure credentials from the running machine
6. POST the results to Azure DevOps (via pipeline tasks)

Using the files found in the following folder; `scripts\pester\tfstate-check\` as examples...

**Initiation**

```powershell
File: scripts\pester\tfstate-check\invoke-pester.ps1
01: [CmdletBinding()]
02: param (
03:     [ValidateNotNullOrEmpty()]
04:     [string]$clientId,
05:     [ValidateNotNullOrEmpty()]
06:     [string]$environment,
07:     [ValidateNotNullOrEmpty()]
08:     [string]$location,
09:     [ValidateNotNullOrEmpty()]
10:     [string]$storageAccount,
11:     [ValidateNotNullOrEmpty()]
12:     [string]$subscriptionName,
13:     [ValidateNotNullOrEmpty()]
14:     [string]$tenantId,
15:     [string]$list
16: )
17:
18: $PSVersionTable
19: $ErrorActionPreference = "stop"
20: Get-Location
```

The required parameters to kick off the script. Do note, that on line `15` the list is not required, but it does allow you to pass in the names of the state files you wish to test against, as opposed to 'everything' inside the Azure blob container. I do like to output as much useful information as possible when running PowerShell scripts in AzDO for debugging; such as the PowerShell version and where the script is running from.

**Install and import Pester on the running agent**

```powershell
File: scripts\pester\tfstate-check\invoke-pester.ps1
22: Install-Module -Name Az -AllowClobber -Confirm:$false -scope CurrentUser -Force
23: Install-Module -Name Az.Security -Confirm:$false -Force
24: Install-Module -Name Pester -RequiredVersion 4.6.0 -Force
25:
26: Import-Module -Name Az
27: Import-Module -Name Az.Security
28: Import-Module -Name Pester
29:
30: Write-Host "Suppress Az.Security warning message"
31: Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
```

Installing and importing on the fly allows this script to be flexible, and run on Microsoft Hosted agents. There are some functions written which use Azure Security, and to prevent verbose info flooding the screen, I have muted this.

```powershell
File: scripts\pester\tfstate-check\invoke-pester.ps1
33: $storageKey          = $env:TERRAFORMBACKENDACCESSKEY
34: $passwd              = ConvertTo-SecureString "$env:ARMCLIENTSECRET" -AsPlainText -Force
35: $pscredential        = New-Object System.Management.Automation.PSCredential($clientId, $passwd)
36:
37: Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId -Subscription $subscriptionName
38: $subId              = (Get-AzSubscription | Where-Object {$_.Name -eq "$subscriptionName"}).SubscriptionId
39: Get-AzSubscription
```

With AzDO, it is much better to pass in secrets as environmental variables (line `33`) so that if the script errors they are not displayed in the logs. Other than that, we are just logging in with the service principal and printing out the subscription information on the screen.

**Load into memory...**

```powershell
File: scripts\pester\tfstate-check\invoke-pester.ps1
42: Write-Host "Load functions into memory"
43: . ../namingStd.ps1
44: . ./functions.ps1
```

If you using the naming standard supplied, or have your own, it might need to be imported. Along with that is the all important set of functions which test against each resource that's deployed.

**Invoke Pester**

```powershell
File: escripts\pester\tfstate-check\invoke-pester.ps1
46: Write-Host "Invoking Pester"
47: Invoke-Pester -Script @{
48:     Path             = "./tfstate-check.ps1"
49:     Parameters       = @{
50:         environment  = "$environment"
51:         location     = "$location"
52:         subscription = "$subId"
53:     }
54: } `
55: -OutputFile ./Infra-Pester-$subscriptionName.XML `
56: -OutputFormat NUnitXML
```

Finally we get to Invoke-Pester. Here I am also passing in the parameters required (lines `49-53`) which I use for the naming standard function. Outputting the file format to NUnitXML is required to easily POST the results to Azure DevOps, which will then output them in a pretty diagram. The stuff managers like to see.

**Clear all Azure credentials from the running machine**

```powershell
File: scripts\pester\tfstate-check\invoke-pester.ps1
59: Write-Host "Listing output files"
60: Get-ChildItem -Path .
61:
62: Write-Output "Clearing Azure credentials"
63: Clear-AzContext -Force
```

Azure credentials are usually kept in a plain text JSON on the running machine; clearing your credentials is essential.

## State File Looping

Now that's only one part of the puzzle sorted, next we are going to look at the PowerShell script which loops through each state file; `scripts\pester\tfstate-check\tfstate-check.ps1`.

```powershell
File: scripts\pester\tfstate-check\tfstate-check.ps1
01: [CmdletBinding()]
02: param (
03:     [ValidateNotNullOrEmpty()]
04:     [string]$environment,
05:     [ValidateNotNullOrEmpty()]
06:     [string]$location,
07:     [ValidateNotNullOrEmpty()]
08:     [string]$subscription
09: )
10:
11: # Required to build out resource names dynamically for the loaded functions
12: $namingReqs           = @{
13:     environment       = $environment
14:     location          = $location
15:     subscription      = $subscription
16: }
17:
18: $blobContainer        = "tfstate"
```

Here we get to use those naming standard parameters passed into the script and build out a hash table containing the values. This will then be used when calling the naming standard function; either when POSTing to Event Hub, or creating specific conditions for the state functions.

```powershell
File: scripts\pester\tfstate-check\tfstate-check.ps1
20: if ($list.length -ge 4) {
21:     $splitList        = @($list.split(","))
22:     $sctx             = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
23:
24:     foreach($item in $splitList) {
25:         try {
26:             $blob     = Get-AzStorageBlob -Context $sctx -Container $blobContainer -Blob "$item"
27:         } catch {
28:             $error
29:             Write-Host "$item not found, skipping"
30:         }
31:
32:         # 'IF' statement required in case value passed in does not exist
33:         if ($blob) {
34:             $destname = $blob.name.split("/")[-1]
35:             Get-AzStorageBlobContent -CloudBlob $blob.ICloudBlob -Context $sctx -Destination "$destname" -Force
36:             Write-Host $destname
37:         }
38:     }
39: } else {
40:     $sctx             = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
41:     $blobs            = Get-AzStorageBlob -Context $sctx -Container $blobContainer -Blob "*"
42:     foreach($blob in $blobs) {
43:         $destname     = $blob.name.split("/")[-1]
44:         Get-AzStorageBlobContent -CloudBlob $blob.ICloudBlob -Context $sctx -Destination "$destname" -Force
45:         Write-Host $destname
46:     }
47: }
48:
49: $fileList             = Get-ChildItem -Path "./" -Filter *.tfstate -File
```

Now we get to download the state files from the blob container. If you have passed in a list of state file names, lines `20-38` will deal with downloading the files (using the `-ge 4` to determine if the list has values), and catch any errors for file names passed in that don't exist. The list needs to be comma separated, as this is how it will split out the file names. Else, if you have not specified a list, lines `40-46` will download **all** state files in the container to loop through.

...and finally, on line `49`, we will only include files that are suffixed with `.tfstate` to loop through. In the following section I won't copy out all the of the code, only including two `IF` statements as an example to use.

```powershell
File: scripts\pester\tfstate-check\tfstate-check.ps1
51: foreach ($file in $filelist) {
52:     $infrastructure   = Get-Content $file.name | ConvertFrom-Json
53:     $filename         = $file.name.split("/")[-1]
54:     Describe "Azure Landing Zone $filename" {
55:         foreach($resource in $infrastructure.resources) {
56:
57:             if(($resource.type -eq "azurerm_eventhub") `
58:                 -and ($resource.mode -ne "data")) {
59:                     Write-Host $resource.type
60:                     check_tf_azure_eventhub($resource)
61:             }
62:
63:             if(($resource.type -eq "azurerm_eventhub_namespace") `
64:                 -and ($resource.mode -ne "data")) {
65:                     Write-Host $resource.type
66:                     check_tf_azure_eventhub_namespace($resource)
67:             }
68:         }
69:     }
70: }
```

Here we finally get to the crucial point of the script, and that's to loop through each state file that has been downloaded, convert it to JSON, and then initiate Pester against each type of resource found. The great thing about Pester being PowerShell, is that you can use native `IF` statements to only include Pester tests on things that actually exist.

**On lines...**

- `52`: we import each file and convert it from JSON to a PowerShell object
- `53`: split out the file name and uses that to display the state file name your running against on the next line
- `54`: Pester always starts off with a Description of the test, and this one being the landing zone of x-state file
- `55`: loops through each resource found in the state file
- `57-61`: if the resource is named `azurerm_eventhub` and is **not** a data lookup, then it will output the type of the resource (handy for debugging) and the initiate the relevant function against that resource (passing in the resource PowerShell object)
- `62-end`: loops through each type of resource that you have created a function for

**Functions!**

Using the Event Hub resource as an example, here we get to break down the function testing against the resource using file `scripts\pester\tfstate-check\functions.ps1`

```powershell
File: scripts\pester\tfstate-check\functions.ps1
01: function check_tf_azure_eventhub ($resource) {
02:     foreach($instance in $resource.instances) {
03:
04:         $nameEvh         = $instance.attributes.name
05:         $evhMsgRetention = $instance.attributes.message_retention
06:         $evhNamespace    = $instance.attributes.namespace_name
07:         $evhPartCount    = $instance.attributes.partition_count
08:         $evhRg           = $instance.attributes.resource_group_name
09:         $evh             = Get-AzEventHub -Name $nameEvh -ResourceGroupName $evhRg -Namespace $evhNamespace
10:
11:         It "$nameEvh should be provisioned" {
12:             $evh.PartitionCount           | Should -Be $evhPartCount
13:             $evh.MessageRetentionInDays   | Should -Be $evhMsgRetention
14:             $evh.Status                   | Should -Be "Active"
15:         }
16:     }
17: }
```

When PowerShell finds a resource there could be more than just one listed in the state file of that resource list, thus we need to run a loop on each one. Then, by simply using an existing state file to compare what is written to state, and what you can test against, we grab the values of those and attaching them to variables on the left. So for example, `$nameEvh` has been given the value of whatever name is shown in the state file by using dot-notation. From experience, the majority of the resources are written in the example above, and from versions 11 to 13 of Terraform, little has changed in how the state file is written. This is handy for us, as it means our PowerShell script is flexible and requires little maintenance once we created a function.

I find it easy to load a state file up on my screen to compare it against, and seeing as though PowerShell objects and JSON are comparable, we can use the same dot-notation to get to the value required. As you can see, it’s easy to understand how the for_each loops and do-notation work when comparing against a state file.

<img src=".\docs\images\azure\05.png" style="zoom:50%;" />

Once you have grabbed all the values you wish to test against (line `04-08`), then we can use basic Azure PowerShell commands to look up the resource we want to test against. On the projects I have worked on we have one service principal per subscription, and thus there is little need for us to define Resource Group or change the scope of the Subscription the service principal is running on to retrieve the information of the resource. You might find that some of the functions do not specify a Resource Group, but if they do need to, you will need to modify it.

Each Pester test runs on an `IT` statement. These statements can be singular and contain only one assertion, and if done like these, the assertion is printed out each time on the screen. To keep things simple I have grouped three assertions into one test in the example above. If anyone one of the assertions fail, that whole test fails. The error will be displayed in the Pester run, directly pointing to the line for which failed, and what the result of the assertion was.

This example is quite simple. I wish to ensure the partition count and message retention are the same as what's deployed, and the actual resource has an active status. Pester test can be as simple as this, or as complicated as you wish it to be.

Here is such an example:

```powershell
File: scripts\pester\tfstate-check\functions.ps1
447: function check_tf_azure_routes ($resource) {
448:     foreach($instance in $resource.instances) {
449: 
450:         $nameRouteTb     = $instance.attributes.name
451:         $routeTbLocation = $instance.attributes.location
452:         $routeTbRg       = $instance.attributes.resource_group_name
453:         $routeTb         = Get-AzRouteTable -Name $nameRouteTb -ResourceGroupName $routeTbRg
454: 
455:         It "$nameRouteTb should be provisioned" {
456:             $routeTb.Location          | Should -Be $routeTbLocation
457:             $routeTb.ProvisioningState | Should -Be "Succeeded"
458:         }
459: 
460:         foreach ($route in $instance.attributes.route) {
461: 
462:             $nameRoute       = $route.name
463:             $routeAddHop     = $route.next_hop_in_ip_address
464:             $routeAddHopType = $route.next_hop_type
465:             $routeAddPfx     = $route.address_prefix
466:             $route           = Get-AzRouteTable -Name $nameRouteTb -ResourceGroupName $routeTbRg | Get-AzRouteConfig -Name $nameRoute
467: 
468:             It "$nameRoute for `"$nameRouteTb`" should be configured" {
469:                 $route.AddressPrefix     | Should -Be $routeAddPfx
470:                 $route.NextHopType       | Should -Be $routeAddHopType
471:                 $route.ProvisioningState | Should -Be "Succeeded"
472:                 if ($null -eq $route.NextHopIpAddress) {
473:                     $testString = ""
474:                 } else {
475:                     $testString = $route.NextHopIpAddress
476:                 }
477:                 $testString | Should -Be $routeAddHop
478:             }
479: 
480:             # Hub Transit main route table should NOT go straight to internet
481:             $mainRouteTableHubTransit       = (namingStd @namingReqs -reference "route-table") + "-asdf"
482:             if (($nameRoute -eq "rt-default") `
483:                 -and ($nameRouteTb -eq $mainRouteTableHubTransit)) {
484: 
485:                 It "$nameRoute for `"$nameRouteTb`" should NOT go straight to the internet for next hop" {
486:                     $route.NextHopType | Should -Not -Be "Internet"
487:                 }
488:             }
489: 
490:             # Spoke main route table should NOT go straight to internet
491:             $mainRouteTableSpoke            = (namingStd @namingReqs -reference "route-table") + "-qwer"
492:             if (($nameRoute -eq "rt-default") `
493:                 -and ($nameRouteTb -eq $mainRouteTableSpoke)) {
494: 
495:                 It "$nameRoute for `"$nameRouteTb`" should NOT go straight to the internet for next hop" {
496:                     $route.NextHopType | Should -Not -Be "Internet"
497:                 }
498:             }
499:         }
500: 
501:         foreach ($subnet in $instance.attributes.subnets) {
502: 
503:             $nameSubnet = $subnet.split("/")[-1]
504: 
505:             It "$nameRoute should be linked to `"$nameSubnet`"" {
506:                 ($routeTb.Subnets.Id |ConvertTo-Json).contains($subnet) | Should -Be $true
507:             }
508:         }
509:     }
510: }
```

Here I'm not only testing the route tables, but also the routes inside each route table, and ensuring they are linked the appropriate subnet. As you can see on lines `481` and `491`, I am using our naming standard to pick out two route tables that should definitely not have the next hop as the internet.

Here's an example snapshot of Pester in action:

<img src=".\docs\images\pipes\15.png" style="zoom:50%;" />

In this snapshot, you can see that Pester is automatically run after the deployment of the landing zone, checking that each resource had successfully deployed. You can also see the two tasks that proceed Pester; one is to publish the NUnitXML as a pipeline artifact, and the second is publish those results to Azure DevOps using a Microsoft Task.

That code can be found here:

```yaml
File: .pipelines\02_jobs\pester_infra.yml
45:   - task: PublishPipelineArtifact@1
46:     displayName: 'Publish Pester Artifact'
47:     inputs:
48:       targetPath: $(System.DefaultWorkingDirectory)/scripts/pester/tfstate-check/Infra-Pester-$(ENVIRONMENT_NAME).XML
49:       artifact: pester_infra_$(ENVIRONMENT_NAME)
50: 
51:   - task: PublishTestResults@2
52:     inputs:
53:       testResultsFormat: 'NUnit'
54:       testResultsFiles: $(System.DefaultWorkingDirectory)/scripts/pester/tfstate-check/Infra-Pester-$(ENVIRONMENT_NAME).XML
55:       testRunTitle: $(ENVIRONMENT_NAME)
56:       publishRunAttachments: true
57:     displayName: "Publish Results"
```

There's nothing hard about outputting the results to Azure DevOps, it can easily be viewed in pretty diagrams by viewing the pipeline run itself:

<img src=".\docs\images\pipes\14.png" style="zoom:50%;" />

By default, Azure DevOps only displays the failed results, but you can view all by ticking `Passed` like in the screenshot above.

## Running the Standalone Pester Pipeline

This pipeline includes the POSTing of Pester results to the deployed Event Hub; useful for outputting to consumer groups such as Elastic. The script itself (`scripts\pester\test-results.ps1`) is commented fairly well, and there shouldn't be anything that needs clarification. If you're not using the naming standard in this repo, then you will need remove the code for it on lines `34-39`, and then update the names on lines `140-142`. This pipeline will also need to have an Azure DevOps Personal Access Token (PAT) that has the following rights; `Build (Read)`; `Release (Read)`; `Test Management (Read)`.

Note: you will also need to change any reference of my Azure DevOps organisation (*fluffypaulmackinnon)* to your own on all of the calling API requests of `scripts\pester\test-results.ps1` and `scripts\pester\test-results-w-teams.ps1`.

Import the pipeline `.pipelines\00_pipes\pester_testing.yml` into Azure DevOps as a new YAML pipeline, and name it `Pester Testing`. The name of this pipeline is required as stated, but if you wish to change the name, then you will need to change the name on line `53` of  `scripts\pester\test-results.ps1` and `scripts\pester\test-results-w-teams.ps1`.

Once imported, you can run either the basic integration testing only, or the infrastructure testing only by checking either box. If neither box is checked, both will run.

<img src=".\docs\images\pipes\21.png" style="zoom:50%;" />

Once Pester has run has successfully run, the last stage is to POST the results to the local Event Hub. If the Landing Zone has been setup as per the code, the subnet for which the Azure DevOps agents sits on should be on the allow list for networks that can securely connect to the Event Hub. You can find the code which reflects this here;

```
File: landing_zone\org\hub\tfvars.tfvars
147: # list of subnets that are allowed to access event hub
148: eventhub_list                                                  = [
149:     "test3"
150: ]
```

...and

```
File: landing_zone\modules\base\logging.tf
60:         virtual_network_rule                                    = [
61:             for subnet in var.eventhub_list: {
62:                 subnet_id                                       = lookup(
63:                     local.subnet_map,
64:                     "${module.names.standard["subnet"]}-${subnet}",
65:                     null
66:                 )
67:                 ignore_missing_virtual_network_service_endpoint = false
68:             }
69:         ]
```

For each subscription and test that is run, a new PowerShell object is created with the details of the test; including passes, fails and details of the failing test. Once that object is built, the output is converted to JSON and pushed to the Event Hub using a short lived self generated SAS token (and clearing the Azure SP credentials at the end).

<img src=".\docs\images\event_hub\01.png" style="zoom:50%;" />

If you were to temporarily lift the restriction on the Event Hub networking access (or add your IP to the allow list), you could browse to the database and view the resulting Pester POST results.

<img src=".\docs\images\event_hub\02.png" style="zoom:50%;" />

If you would like to also POST the results to Microsoft Teams, then you can update line `80` of `.pipelines\00_pipes\pester_testing.yml` to point to the PowerShell script `scripts\pester\test-results-w-teams.ps1`. This script basically expands upon the idea of building PowerShell objects and adding them to arrays, much like the other script. However, it needs to conform to a JSON payload that suits a Microsoft Teams POST, and thus is built out with additional objects, arrays, strings, etc... to insert itself in `scripts\pester\pester_card_input.json`, after line `61`. When Pester runs, it will show the resulting JSON payload in the output just before it POSTs, which is handy to know if things have been created properly.

The code for POSTing to Microsoft Teams is also fairly well commented, so there shouldn't be much to expand upon. The discussion for this is outside the general scope of those Readme, so I will leave it up to the more advanced PowerShell users to comprehend what's going on.

## What To Do With Errors?

So what happens if Pester has some failed results? How do you go about resolving these? Thankfully Pester not only tells you what failed, but what the output of the test was, what it was expecting, and on which line of the PowerShell script for which the assertion failed. By looking at either the Azure DevOps portal, or the output log of Pester, you can find the failed state file, and compare it to the command for which ran against it. From there you can use your tech know-how to either confirm the fail or to correct your assertion statement and/or function.

<img src=".\docs\images\event_hub\03.png" style="zoom:50%;" />

<img src=".\docs\images\event_hub\04.png" style="zoom:50%;" />

<img src=".\docs\images\event_hub\05.png" style="zoom:50%;" />
function artifactory_np_response_spoke {
    $IPWebResponse = Invoke-WebRequest "https://artifactory-np.something.name.co.uk/artifactory/" -SkipCertificateCheck
    $num           = [int]$IPWebResponse.StatusCode
    $num -in 200..299
}


function artifactory_pr_response_dns ($namingReqs) {
    $ResourceName   = "artifactory"
    $Rg             = (namingStd @namingReqs -reference "resource-group") + "-azure-dns"
    $ZoneName       = "something.name.co.uk"
    $RecordSets     = Get-AzPrivateDnsRecordSet -ResourceGroupName $Rg -ZoneName $ZoneName -RecordType A | Where-Object {$_.Name -eq $ResourceName}

    $DNSresponse    = $RecordSets.Name + "." + $RecordSets.ZoneName
    $DNSWebResponse = Invoke-WebRequest ("https://" + $DNSresponse + "/artifactory/") -SkipCertificateCheck
    $num            = [int]$DNSWebResponse.StatusCode
    $num -in 200..299
}


function artifactory_pr_response_ip ($namingReqs) {
    $ResourceName  = "artifactory"
    $Rg            = (namingStd @namingReqs -reference "resource-group") + "-azure-dns"
    $ZoneName      = "something.name.co.uk"
    $RecordSets    = Get-AzPrivateDnsRecordSet -ResourceGroupName $Rg -ZoneName $ZoneName -RecordType A | Where-Object {$_.Name -eq $ResourceName}

    $IPresponse    = $RecordSets.Records.Ipv4Address
    $IPWebResponse = Invoke-WebRequest ("https://" + $IPresponse + "/artifactory/") -SkipCertificateCheck
    $num           = [int]$IPWebResponse.StatusCode
    $num -in 200..299
}


function artifactory_pr_response_spoke {
    $IPWebResponse = Invoke-WebRequest "https://artifactory.something.name.co.uk/artifactory/" -SkipCertificateCheck
    $num           = [int]$IPWebResponse.StatusCode
    $num -in 200..299
}


function azdo_pat ($azdopat) {
    $pat       = $azdopat + ":"
    $b         = [System.Text.Encoding]::UTF8.GetBytes($pat)
    $authToken = [System.Convert]::ToBase64String($b)
    $headers   = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Basic $authToken")

    $response  = Invoke-WebRequest 'https://dev.azure.com/fluffypaulmackinnon/_apis/distributedtask/pools?api-version=6.0-preview.1' -Method 'GET' -Headers $headers -Body $body
    $num       = [int]$response.StatusCode
    $num -in 200..299
}


function bind_response_npd {
    $test = Start-Process -PassThru -Wait 'dig' -ArgumentList '@10.1.1.2 something.name.co.uk'
    if ($test.ExitCode -eq 0) {
        return $true
    } else {
        return $false
    }
}


function bind_response_prd {
    $test = Start-Process -PassThru -Wait 'dig' -ArgumentList '@10.1.1.1 something.name.co.uk'
    if ($test.ExitCode -eq 0) {
        return $true
    } else {
        return $false
    }
}


function bind_resolve_ext {
    $url = "www.github.com"
    $dns = [System.Net.Dns]::GetHostEntry($url)
    if ($dns) {
        return $true
    } else {
        return $false
    }
}


function bind_resolve_int {
    $ResourceName  = "artifactory"
    $Rg            = (namingStd @namingReqs -reference "resource-group") + "-azure-dns"
    $ZoneName      = "artifactory.something.name.co.uk"
    $RecordSets    = Get-AzPrivateDnsRecordSet -ResourceGroupName $Rg -ZoneName $ZoneName -RecordType A | Where-Object {$_.Name -eq $ResourceName}
    $IpArtifactory = $RecordSets.Records.Ipv4Address

    $url           = $ResourceName + "." + $ZoneName
    $ArtifactoryIp = [System.Net.Dns]::GetHostEntry($url).AddressList.IPAddressToString

    if ($ArtifactoryIp -eq $IpArtifactory) {
        return $true
    } else {
        return $false
    }
}


function keyvault {
    $VaultName = (namingStd @namingReqs -reference "key-vault") + "-ss"
    $Secret    = ConvertTo-SecureString -String "password" -AsPlainText -Force
    $SecretAdd = Set-AzKeyVaultSecret -VaultName $VaultName -Name "ITSecret" -SecretValue $Secret
    if ($SecretAdd) {
        Remove-AzKeyVaultSecret -VaultName $VaultName -Name "ITSecret" -Force
        if ($?) {
            return $true
        } else {
            return $false
        }
    } else {
        return $false
    }
}


function private_dns_resolve_spoke ($namingReqs) {
    $Rg           = namingStd @namingReqs -reference "resource-group"
    $zoneSpoke    = (Get-AzSubscription | Where-Object {$_.SubscriptionId -eq $namingReqs["subscription"]}).Name.Remove(0,4).ToLower()
    $zoneRoot     = "something.name.co.uk"
    $zoneName     = $zoneSpoke + "." + $zoneRoot

    $hostName     = hostname
    $hostSettings = [System.Net.Dns]::GetHostAddresses($hostName) | Where-Object {$_.AddressFamily -eq "InterNetwork"}
    $hostNameIp   = $hostSettings.IPAddressToString

    $privDns      = Get-AzPrivateDnsRecordSet -ResourceGroupName "$Rg-azure-dns" -ZoneName $ZoneName -RecordType A | Where-Object {$_.Name -eq $hostName}
    $privHostIp   = $privDns.Records.Ipv4Address

    if ($hostNameIp -eq $privHostIp) {
        return $true
    } else {
        return $false
    }
}


function web_egress_blacklist {
    try {
        Invoke-WebRequest "google.com"
        # if the command was successful (the website was allowed), the return of that would be $true
        if ($? -eq $true) {
            return $false
        }
    } catch {
        # return true because the command failed (the website was blocked), and catch caught the fail
        return $true
    }
}


function web_egress_whitelist {
    $WebResponse = Invoke-WebRequest "github.com"
    $num         = [int]$WebResponse.StatusCode
    $num -in 200..299
}


function web_egress_whitelist_speed {
    $url       = "github.com"
    $timeArray = @()

    for ($i=0; $i -le 10; $i++) {
        $timeTaken = Measure-Command -Expression {
            Invoke-WebRequest -Uri $url
        }
        $milliseconds = $timeTaken.Milliseconds
        $timeArray += $milliseconds
        Start-Sleep -Seconds 5
    }

    $average        = $timeArray | Measure-Object -Average
    $avMilliseconds = [int]$average.Average
    $avMilliseconds -in 0..5000
}
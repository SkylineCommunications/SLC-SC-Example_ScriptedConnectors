[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$appid = "<azure appid here>"
$cert_thumbprint = "<certificate thumbprint here>"
$tenantid = "<azure tenant id here>"

function getHeader($identifier, $type){
    # Generate required headers
    $headers = @{
        "identifier" = $identifier
        "type" = $type
        "Content-Type" = "application/json"
        "accept" = "application/json"
    }
    return $headers
}

function summarizePerOrg($serverlist, $offlineservers){
    $serversummary = New-Object System.Collections.ArrayList

    # Collect data per organization name (for DAAS)
    $serverlist = $serverlist | Sort-Object orgName
    $orgNames = $($serverlist | Sort-Object orgName -Unique).orgName
    
    # Grab all organizations (tags) that have deallocated servers
    $orgNamesOffline = $($offlineservers | Sort-Object orgName -Unique).orgName

    # Count organization-tags for live servers
    foreach ($orgName in $orgNames){
        $obj_amount = $($serverlist | Where-Object {$_.orgName -eq $orgName})
        if ($obj_amount -is [array]){
            $amount = $obj_amount.Count
        } Else {
            $amount = 1
        }

        if( -not($orgName)){
            $orgName = "No Organization"
        }

        $obj_summary = [PSCustomObject]@{
            orgName = $orgName
            amount = $amount
        }
        [void]$serversummary.Add($obj_summary)
    }

    # Count organisation tags for deallocated servers.
    foreach ($zeroName in $orgNamesOffline){
        foreach ($entry in $serversummary){if($entry.orgName -eq $zeroName){Continue}}
        $obj_summary = [PSCustomObject]@{
            orgName = $zeroName
            amount = 0
        }
        [void]$serversummary.Add($obj_summary)
    }

    return $serversummary
}

function summarizePerVMSku($serverlist){
    $serversummary = New-Object System.Collections.ArrayList

    # Collect data per SKU
    $serverlist = $serverlist | Sort-Object vmsku
    $vmskus = $($serverlist | Sort-Object vmsku -Unique).vmsku
    
    # Count skus
    foreach ($vmsku in $vmskus){
        $numberofreservations = $($reservations | Where-Object {$_.SkuName -eq $vmsku}).Quantity
        if (-not ($numberofreservations)){$numberofreservations = 0}
        $obj_amount = $($serverlist | Where-Object {$_.vmsku -eq $vmsku})
        if ($obj_amount -is [array]){
            $amount = $obj_amount.Count
        } Else {
            $amount = 1
        }

        $obj_summary = [PSCustomObject]@{
            vmsku = $vmsku
            amount = $amount
            reservations = $numberofreservations
        }
        [void]$serversummary.Add($obj_summary)
    }
    return $serversummary
}

$server2022VMsList = New-Object System.Collections.ArrayList
$OfflineVMsList = New-Object System.Collections.ArrayList

# Sign in to your Azure account using the certificate
Connect-AzAccount -ServicePrincipal -Tenant $tenantid -ApplicationId $appid -CertificateThumbprint $cert_thumbprint

# Get a list of all active subscriptions
$subscriptions = Get-AzSubscription | where {$_.State -eq "Enabled"}
# Get a list of all reservations
$reservations = Get-AzReservation

# Iterate through each subscription
foreach ($subscription in $subscriptions) {
    
    Set-AzContext -Subscription $subscription -Tenant $tenantid | Out-Null
    $subscriptionName = $subscription.Name

    # Get a list of all virtual machines in the subscription and also explicitly grab the status
    $virtualMachines = Get-AzVM -Status

    # Grab running Windows VM's
    $server2022VMs = $virtualMachines | Where-Object { ($_.StorageProfile.OSDisk.OSType -eq "Windows") -and ($_.PowerState -eq "VM Running") -and ($_.OsName -Like "Windows Server*") } #-and ($_.LicenseType -eq "Windows_Server")
    
    # Grab deallocated Windows VM's
    $OfflineVMs = $virtualMachines | Where-Object { ($_.StorageProfile.OSDisk.OSType -eq "Windows") -and ($_.PowerState -eq "VM deallocated") }

    Write-Host "Found $($server2022VMs.Count) running and $($OfflineVMs.Count) deallocated Windows VM's in $subscriptionName"

    # Create arraylist with details for running vms
    $server2022VMs | ForEach-Object {
        $vmDetails = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name
        if ($_.LicenseType -eq "Windows_Server"){
            $hybrid = $True
        } Else {
            $hybrid = $False
        }
        $vmData = [PSCustomObject]@{
            Subscription = $subscriptionName
            ResourceGroupName = $_.ResourceGroupName
            Name = $_.Name
            Location = $_.Location
            OS = $_.OsName
            orgName = $($vmDetails.Tags.orgName)
            vmsku = $_.HardwareProfile.VmSize
            HybridLicense = $hybrid
        }
        [void]$server2022VMsList.Add($vmData)
    }

    # Create arraylist with details for deallocated vms
    $OfflineVMs | ForEach-Object {
        $vmDetails = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name
        if ($_.LicenseType -eq "Windows_Server"){
            $hybrid = $True
        } Else {
            $hybrid = $False
        }
        $vmData = [PSCustomObject]@{
            Subscription = $subscriptionName
            ResourceGroupName = $_.ResourceGroupName
            Name = $_.Name
            Location = $_.Location
            OS = $_.OsName
            orgName = $($vmDetails.Tags.orgName)
            vmsku = $_.HardwareProfile.VmSize
            HybridLicense = $hybrid
        }
        if ($vmDetails.Tags.orgName){
            [void]$OfflineVMsList.Add($vmData)
        }
    }
}

# Sign out from your Azure account
Disconnect-AzAccount

# Display summary info
$summaryPerOrg = summarizePerOrg -serverlist $server2022VMsList -offlineservers $OfflineVMsList
Write-Host "Summary per Organization:"
Write-Host "----------------------------"
foreach ($entry in $summaryPerOrg){
    if ($entry.orgName){
        Write-Host "$($entry.orgName): $($entry.amount)"
    } Else {
        Write-Host "No Organization: $($entry.amount)"
    }
}
Write-Host ""

$summaryPerVMSku = summarizePerVMSku -serverlist $server2022VMsList
Write-Host "Summary per VM Sku:"
Write-Host "----------------------------"
foreach ($entry in $summaryPerVMSku){
   Write-Host "$($entry.vmsku): $($entry.amount)"
}


# Wrap the data, so DataMiner can read it
$header = getHeader -identifier "Azure Data v2" -type "Azure Data v2"
$wrappedData = @{
    "All VMs" = $server2022VMsList | ForEach-Object { 
        @{
            Subscription = $_.Subscription
            ResourceGroupName = $_.ResourceGroupName
            ID = $_.Name
            Location = $_.Location
            OS = $_.OS
            orgName = $_.orgName
            vmsku = $_.vmsku
            HybridLicense = $_.HybridLicense
        }
    }
    "VMs per Organization" = $summaryPerOrg | ForEach-Object { 
        @{
            ID = $_.OrgName
            Amount = $_.amount
        }
    }    
    "VMs per SKU" = $summaryPerVMSku | ForEach-Object { 
        @{
            ID = $_.vmsku
            Amount = $_.amount
            Reservation = $_.reservations
        }
    }
}

$body = $wrappedData | ConvertTo-Json
$uri = "http://localhost:34567/api/data/parameters"
$response = Invoke-RestMethod -Uri $uri -Method Put -Headers $header -Body $body
echo $response | ConvertTo-Json

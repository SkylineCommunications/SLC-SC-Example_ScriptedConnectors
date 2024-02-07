[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$appid = "<appid_here>"
$cert_thumbprint = "<cert_thumbprint_here>"
$tenantid = "<tenantid_here>"

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

    # Check if there are any Organizations that only have deallocated servers and set their amount to zero, 
    # this is needed to workaround the fact that DataMiner will hold on to stale data.
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

function summarizePerOS($serverlist){
    $serversummary = New-Object System.Collections.ArrayList

    # Collect all OS's
    $serverlist = $serverlist | Sort-Object OS
    $oslist = $($serverlist | Sort-Object OS -Unique).OS

    # Grab number of vm's that have a hybrid-license:
    $obj_amount = $($serverlist | Where-Object {$_.HybridLicense -eq $True})
    if ($obj_amount -is [array]){
        $hybrid_amount = $obj_amount.Count
    } Else {
        $hybrid_amount = 1
    }

    foreach ($os in $oslist){
        # Grab number of vm's running per OS:
        $obj_amount = $($serverlist | Where-Object {$_.OS -eq $os})
        if ($obj_amount -is [array]){
            $amount = $obj_amount.Count
        } Else {
            $amount = 1
        }

        if ($os -like "Windows Server*"){
            $obj_summary = [PSCustomObject]@{
                OS = $os
                Amount = $amount
                HybridLicensed = $hybrid_amount
            }
        } Else{
            $obj_summary = [PSCustomObject]@{
                OS = $os
                Amount = $amount
                HybridLicensed = 0
            }
        }
        [void]$serversummary.Add($obj_summary)
    }
    return $serversummary
}

function summarizePerVMSku($serverlist, $reservations, $offlineservers){
    $serversummary = New-Object System.Collections.ArrayList

    # Collect all sku's
    $serverlist = $serverlist | Sort-Object vmsku
    $vmskus = $($serverlist | Sort-Object vmsku -Unique).vmsku
    
     # Grab all skus that have deallocated servers
    $skusoffline = $($offlineservers | Sort-Object vmsku -Unique).vmsku

    foreach ($vmsku in $vmskus){
        # Grab reservations cumulated per sku
        $numberofreservations = 0
        $reservationsforsku = $($reservations | Where-Object {$_.SkuName -eq $vmsku}) 
        if ($reservationsforsku -is [array]){
            foreach ($reservationforsku in $reservationsforsku){
                $numberofreservations += $reservationforsku.Quantity
            }
        } Else {
            $numberofreservations = $reservationsforsku.Quantity
        }
        if (-not ($numberofreservations)){$numberofreservations = 0}

        # Grab number of vm's per sku
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

    # Check if there are any skus that only have deallocated servers and set their amount to zero, 
    # this is needed to workaround the fact that DataMiner will hold on to stale data.
    foreach ($offlinesku in $skusoffline){
        if (-not $vmskus.Contains($offlinesku)){
            $reservationsforsku = $($reservations | Where-Object {$_.SkuName -eq $offlinesku}) 
            if ($reservationsforsku -is [array]){
                foreach ($reservationforsku in $reservationsforsku){
                    $numberofreservations += $reservationforsku.Quantity
                }
            } Else {
                $numberofreservations = $reservationsforsku.Quantity
            }
            if (-not ($numberofreservations)){$numberofreservations = 0}

            $obj_summary = [PSCustomObject]@{
                vmsku = $vmsku
                amount = 0
                reservations = $numberofreservations
            }
            [void]$serversummary.Add($obj_summary)
        }
    }
    return $serversummary
}

$WindowsVMs = New-Object System.Collections.ArrayList
$AllVMs = New-Object System.Collections.ArrayList
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

    Write-Host "Checking VMs in $subscriptionName"

    # Get all scale-sets and extract vms from it.
    $allVMSS = Get-AzVmss
    foreach ($vmss in $allVMSS){
        $numberofinstances = $vmss.Sku.Capacity
        if ($vmss.VirtualMachineProfile.StorageProfile.ImageReference.id -like "*Ubuntu*"){
            $os = "Ubuntu"
        }
        for ($i=0; $i -lt $numberofinstances; $i++){
            $vmData = [PSCustomObject]@{
                Subscription = $subscriptionName
                ResourceGroupName = $vmss.ResourceGroupName
                Name = "$($vmss.Name)_$i"
                Location = $vmss.Location
                OS = $os
                orgName = ""
                vmsku = $vmss.Sku.Name
                HybridLicense = $False
            }
            [void]$AllVMs.Add($vmData)
        }
    }

    # Get a list of all virtual machines in the subscription and also explicitly grab the status
    $virtualMachines = Get-AzVM -Status

    # Grab all VM's
    $AllServers = $virtualMachines | Where-Object { ($_.PowerState -eq "VM Running") } #-and ($_.LicenseType -eq "Windows_Server")

    # Grab running Windows VM's
    $WindowsServers = $virtualMachines | Where-Object { ($_.StorageProfile.OSDisk.OSType -eq "Windows") -and ($_.PowerState -eq "VM Running") -and ($_.OsName -Like "Windows Server*") } #-and ($_.LicenseType -eq "Windows_Server")

    # Grab deallocated Windows VM's
    $OfflineVMs = $virtualMachines | Where-Object { ($_.StorageProfile.OSDisk.OSType -eq "Windows") -and ($_.PowerState -eq "VM deallocated") }

    Write-Host "Found $($AllServers.Count) VMs running and $($OfflineVMs.Count) VMs deallocated in $subscriptionName"

    # Arraylist with all Running VMs
    $AllServers | ForEach-Object {
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
        if (-not ($_.OsName)){
            Write-Host "OSName parameter empty, this is an Azure-bug" -ForegroundColor Red
        }
        [void]$AllVMs.Add($vmData)
    }

    # Arraylist with Running Windows VMs
    $WindowsServers | ForEach-Object {
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
        [void]$WindowsVMs.Add($vmData)
    }

    # Arraylist with Deallocated VMs
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

# Summarize per org-tag, here we only need the Windows VM's and Deallocated VM's
$summaryPerOrg = summarizePerOrg -serverlist $WindowsVMs -offlineservers $OfflineVMsList
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

# Summarize per SKU, here we'll need all VM's, regardless of OS or vmss-instance and offline VMs to workaround the stale-data issue
$summaryPerVMSku = summarizePerVMSku -serverlist $AllVMs -reservations $reservations -offlineservers $OfflineVMsList
Write-Host "Summary per VM Sku:"
Write-Host "----------------------------"
foreach ($entry in $summaryPerVMSku){
   Write-Host "$($entry.vmsku): $($entry.amount)"
}
Write-Host ""

# Summarize per SKU, here we'll need all VM's, regardless of OS or vmss-instance
$summaryPerOS = summarizePerOS -serverlist $AllVMs
Write-Host "Summary per VM OS:"
Write-Host "----------------------------"
foreach ($entry in $summaryPerOS){
   Write-Host "$($entry.OS): $($entry.amount) (Hybrid Active: $($entry.HybridLicensed))"
}

# Wrap the data, so DataMiner can read it
$header = getHeader -identifier "Azure Data v2" -type "Azure Data v2"
$wrappedData = @{
    "All VMs" = $AllVMs | ForEach-Object { 
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
    "VMs per OS" = $summaryPerOS | ForEach-Object { 
        @{
            ID = $_.OS
            Amount = $_.amount
            HybridLicensed = $_.HybridLicensed
        }
    }
}

$body = $wrappedData | ConvertTo-Json
$uri = "http://localhost:34567/api/data/parameters"
$response = Invoke-RestMethod -Uri $uri -Method Put -Headers $header -Body $body
echo $response | ConvertTo-Json

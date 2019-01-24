# Ensure that the source VM is powered down (Stopped-Deallocated) or else we will not be able to generate SAS for its disks

Param(

[Parameter(Mandatory=$true)]
[string]$SourceVMName,

[Parameter(Mandatory=$true)]
[string]$SourceResourceGroup,

[Parameter(Mandatory=$true)]
[string]$DestLocations

)

$dataDiskNames = New-Object System.Collections.ArrayList
$dataDiskSASes = New-Object System.Collections.ArrayList

$containerName = "azcopy"
$templateURI = "https://raw.githubusercontent.com/richardspitz/imagefactory/master/azuredeploy.json"

$adminPassword = Get-AutomationVariable -Name "adminPassword"
$varWebhook = Get-AutomationVariable -Name "webhookURI"
$webhookURI = $varWebhook.ToString()

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

# Get Source VM object to access disk info
$VM = Get-AzureRmVM -ResourceGroupName $SourceResourceGroup -Name $SourceVMName -Verbose
$osDiskName = $VM.StorageProfile.OsDisk.Name

# Get OS Disk SAS
$osDiskSAS = (Grant-AzureRmDiskAccess -Access Read -DiskName $osDiskName -ResourceGroupName $SourceResourceGroup -DurationInSecond 36000 -Verbose).AccessSAS

# Get all data disk SAS
foreach($dataDisk in $VM.StorageProfile.DataDisks)
{
    $dataDiskNames.Add($dataDisk.Name) | Out-Null
    #$destDataDiskNames.Add($($storAccount.PrimaryEndpoints.Blob + $containerName + "/" + $dataDisk.Name + ".vhd")) | Out-Null

}

foreach($dataDiskName in $dataDiskNames)
{
    $dataDiskSASes.Add((Grant-AzureRmDiskAccess -Access Read -DiskName $dataDiskName -ResourceGroupName $SourceResourceGroup -DurationInSecond 36000 -Verbose).AccessSAS) | Out-Null
}

# Split and then loop for each destination region specified
$arrDestLocations = $DestLocations.Split(",")

foreach($DestLocation in $arrDestLocations)
{
$destDataDiskNames = New-Object System.Collections.ArrayList

# Generate Random String to create names
$randStr = Get-Random -Maximum 1000000000000000 -Minimum 100000000000000
$rgName = "AzCopy" + $randStr + "-RG"
$rgNameStor = "ImgFac" + $randStr + "-RG"
$storAccountName = "imgfac" + $randStr

# Create Resource Groups for the AzCopy VM and Destination Storage Account
$RG = New-AzureRmResourceGroup -Name $rgName -Location $DestLocation -Verbose
$RGStor = New-AzureRmResourceGroup -Name $rgNameStor -Location $DestLocation -Verbose

# Create Storage Account and get Storage Account Key
$storAccount = New-AzureRmStorageAccount -ResourceGroupName $RGStor.ResourceGroupName -Name $storAccountName -SkuName Standard_LRS -Location $DestLocation -Verbose
$storAccount | New-AzureRmStorageContainer -Name $containerName -Verbose
$storAccountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $RGStor.ResourceGroupName -Name $storAccount.StorageAccountName -Verbose


# Create destination disk names from original disk names
$destOsDiskName = $storAccount.PrimaryEndpoints.Blob + $containerName + "/" + $osDiskName + ".vhd"
foreach($dataDisk in $VM.StorageProfile.DataDisks)
{
    $destDataDiskNames.Add($($storAccount.PrimaryEndpoints.Blob + $containerName + "/" + $dataDisk.Name + ".vhd")) | Out-Null
}

# Create Bash script to be run on AzCopy VM that does the copy and then calls the cleanup runbook
$bashScript = @"
#!/bin/bash

wget -O azcopy.tar.gz https://aka.ms/downloadazcopylinux64 >> /var/log/azcopy.log
tar -xf azcopy.tar.gz >> /var/log/azcopy.log
sudo ./install.sh >> /var/log/azcopy.log
echo "Copy Start:" >> /var/log/azcopytiming.log
date >> /var/log/azcopytiming.log
azcopy --source "$($osDiskSAS)" --destination "$($destOsDiskName)" --dest-key "$($storAccountKey.value[0])" --sync-copy --resume /dev/shm/osdiskresume >> /var/log/azcopy-osdisk.log &

"@

for($i = 0;$i -lt $dataDiskNames.Capacity;$i++)
{

$bashScript += @"
azcopy --source "$($dataDiskSASes[$i])" --destination "$($destDataDiskNames[$i])" --dest-key "$($storAccountKey.value[0])" --sync-copy --resume /dev/shm/dataresume$($i + 1) >> /var/log/azcopy-datadisk$($i + 1).log &

"@

}

$bashScript += @"
wait
echo "Copy Finished:" >> /var/log/azcopytiming.log
date >> /var/log/azcopytiming.log
azcopy --source /var/log/azcopytiming.log --destination "$($storAccount.PrimaryEndpoints.Blob)$($containerName)/azcopytiming.log" --dest-key "$($storAccountKey.value[0])"
echo "[{'Name': '$($RG.ResourceGroupName)'}]" > body.json
curl -X POST -H "message:ImageCopy" -d @body.json $($webhookURI)

"@

# Replace Windows newline characters with Linux ones
$bashScript = $bashScript.Replace("`r`n","`n")

# Encode script as base64 string
$Bytes = [System.Text.Encoding]::utf8.GetBytes($bashScript)
$encodedBashScript =[Convert]::ToBase64String($Bytes)

# Create Param Hash Table
# Move password to Azure Automation credential asset after testing
$paramObj = @{'adminPassword' = $adminPassword.ToString(); 'bashScript' = $encodedBashScript}

# Run AzCopy VM Deployment
New-AzureRmResourceGroupDeployment -ResourceGroupName $RG.ResourceGroupName -TemplateParameterObject $paramObj -TemplateUri $templateURI -AsJob

# Remove variables 
Remove-Variable -Name destDataDiskNames
Remove-Variable -Name destOsDiskName
Remove-Variable -Name RG
Remove-Variable -Name RGStor
Remove-Variable -Name storAccount
Remove-Variable -Name storAccountKey
Remove-Variable -Name bashScript
Remove-Variable -Name Bytes
Remove-Variable -Name encodedBashScript
Remove-Variable -Name paramObj

}
# Automated Inter-Region VHD Copy using AzCopy --sync-copy

Synchronously copy all managed disks of an Azure Virtual Machine to an Azure Storage Account in any Azure region. 

1. Create an Azure Automation Account with a Run As account.
2. Create and publish a PowerShell runbook each for ImageCopy.ps1 and Cleanup.ps1.
3. Create a webhook on Cleanup.ps1 with sufficient validity (eg. 1 year) and save the URL for use in step 5.
4. Create an encrypted Azure Automation Variable named 'adminPassword' with the password for the AzCopy VM the runbook will create. 
5. Create another encrypted Azure Automation Variable named 'webhookURI' with the URL from step 3. 
6. Note the expiry of the webhook and Azure Automation Run As account for renewal

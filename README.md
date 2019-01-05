# Automated Inter-Region VHD Copy using AzCopy --sync-copy

Synchronously copy all managed disks of an Azure Virtual Machine to an Azure Storage Account in any Azure region. 

1. Create an Azure Automation Account with a Run As account.
2. [Important] Update Azure modules
3. Create and publish a PowerShell runbook each for ImageCopy.ps1 and Cleanup.ps1.
4. Create a webhook on Cleanup.ps1 with sufficient validity (eg. 1 year) and save the URL for use in step 6.
5. Create an encrypted Azure Automation Variable named 'adminPassword' with the password for the AzCopy VM the runbook will create. 
6. Create another encrypted Azure Automation Variable named 'webhookURI' with the URL from step 4. 
7. Note the expiry of the webhook and Azure Automation Run As account for renewal.
8. Start the ImageCopy runbook.

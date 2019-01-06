# Automated Inter-Region VHD Copy using AzCopy --sync-copy

Synchronously copy all managed disks of an Azure Virtual Machine to an Azure Storage Account in any Azure region. 

1. Create an Azure Automation Account with a Run As account.
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/AutoAccCreate.JPG)
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/AutoAccount.JPG)

2. ***Important*** Update Azure modules.
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/UpdateAzureModules.JPG)
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/UpdateAzureModules1.JPG)
3. Create and publish a PowerShell runbook each for ImageCopy.ps1 (named PageBlobCopy) and Cleanup.ps1 (named Cleanup). Copy the code from these files into the browser-based editor for each of these runbooks.
(The steps below are for the first runbook. Repeat these for the second runbook as well)
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/Runbook.JPG)
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/Runbook1.JPG)
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/Runbook2.JPG)

4. Create a webhook on the Cleanup.ps1 runbook with sufficient validity (eg. 1 year) and save the URL for use in step 5.
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/Webhook0.JPG)
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/Webhook01.JPG)
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/Webhook1.JPG)
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/Webhook2.JPG)
5. Create two encrypted Azure Automation Variables - one named 'adminPassword' with the password for the AzCopy VM the runbook will create and a second named 'webhookURI' with the URL from step 4. 
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/Variables.JPG)
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/Variables1.JPG)
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/Variables2.JPG)
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/Variables3.JPG)
6. Start the PageBlobCopy runbook.
![alt text](https://github.com/richardspitz/imagefactory/raw/master/images/StartRunbook.JPG)
7. Locate the destination Azure Storage Account resource group, use any one of these options: 

  a. Search your resource groups with the prefix "ImgFac"
  b. Review the output of the PageBlobCopy job 
  c. Review the Activity Log  

Note:
Record the expiry of the webhook URI and Azure Automation Run As accounts for renewal.

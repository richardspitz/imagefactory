# Automated Inter-Region VHD Copy using AzCopy --sync-copy


Synchronously copy all managed disks of a _powered-off_ Azure Virtual Machine to Azure Storage Accounts in one or more Azure regions using a temporary Azure Virtual Machine spun up for the copy and then torn down after the copy completes. 

_***Important***:_

_The Virtual Machine must be powered off for the disk SAS (Shared Access Signature) to be created._

_Start only one instance of the runbook for a particular source Virtual Machine. Starting multiple instances for the same source Virtual Machine will result in new SAS being generated for its disks and this will cause any ongoing copy operations to be terminated._

## Solution Flow

For each destination location specified:

1. Creates two resource groups - one for the temporary Azure Virtual Machine and the second for the Azure Storage Account in the destination

2. Creates the destination Azure Storage Account with the "azcopy" container, that will contain the copied disks.

3. Gets source Azure Virtual Machine managed disk Shared Access Signatures (SAS).

    _Note: The source Azure Virtual Machine must be in the Stopped-Deallocated state._

4. Creates a Bash script to run AzCopy using the disks SAS and then clean up temporary resources.

5. Creates a temporary Linux Azure Virtual Machine and injects the Bash script.

6. Copies managed disks using AzCopy --sync-copy and the temporary Azure Virtual Machine bandwidth and memory.

7. Deletes the resource group containing the temporary Azure Virtual Machine.

## Steps

1. Create an Azure Automation Account with a Run As account.

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/AutoAccCreate.JPG)

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/AutoAccount.JPG)

2. ***Important*** Update Azure modules, and wait till the operation completes.

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/UpdateAzureModules.JPG)
    
    ![](https://github.com/richardspitz/imagefactory/raw/master/images/UpdateAzureModules1.JPG)
    
3. Create a PowerShell runbook each for ImageCopy.ps1 (named PageBlobCopy) and Cleanup.ps1 (named Cleanup). Copy the code from these files into the browser-based editor for each of these runbooks. Click "Publish".

    (The steps below are for the first runbook. Repeat these for the second runbook as well)

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/Runbook.JPG)
    
    ![](https://github.com/richardspitz/imagefactory/raw/master/images/Runbook1.JPG)

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/Runbook2.JPG)

4. Create a webhook on the Cleanup.ps1 runbook with sufficient validity (eg. 1 year) and save the URL for use in step 5.

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/Webhook0.JPG)
    
    ![](https://github.com/richardspitz/imagefactory/raw/master/images/Webhook01.JPG)
    
    ![](https://github.com/richardspitz/imagefactory/raw/master/images/Webhook1.JPG)

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/Webhook2.JPG)

5. Create two encrypted Azure Automation Variables - one named 'adminPassword' with the password for the AzCopy VM the runbook will create and a second named 'webhookURI' with the URL from step 4. 

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/Variables.JPG)

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/Variables1.JPG)

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/Variables2.JPG)

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/Variables3.JPG)

6. Start the PageBlobCopy runbook and specify the source VM name, source resource group and one or more comma-separated "destination" Azure Regions. For example:

    Australia East,Southeast Asia,West US 2

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/StartRunbook.JPG)

7. Locate the destination Azure Storage Account resource groups using the output of the PageBlobCopy job.

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/RunbookOutput1.JPG)

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/RunbookOutput2.JPG)

    ![](https://github.com/richardspitz/imagefactory/raw/master/images/RunbookOutput3.JPG)

Navigate to the "azcopy" Blob Container in each of these Azure Storage Accounts. 

About 5 to 6 minutes after the runbook has started, all VHDs should appear here though at this point based on their size, the copy operation is ongoing. 

Hit refresh till you see the "azcopytiming.log" blob, which indicates that the copy operation has completed and the VHDs are now available for use. Review this file if you'd like to see how long the copy took.

![](https://github.com/richardspitz/imagefactory/raw/master/images/CopyComplete.JPG)


Note:
Record the expiry of the webhook URI and Azure Automation Run As accounts to renew before they expire.

## License

This sample code is licensed under the [MIT License](https://github.com/richardspitz/imagefactory/raw/master/LICENSE).

## To do

1. Error handling
2. ARM template deployment of this solution

Questions? rspitz@microsoft.com 

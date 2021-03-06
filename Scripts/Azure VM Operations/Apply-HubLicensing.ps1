﻿PARAM
(
    #the script input variables
    [Parameter(Mandatory = $True)]
    [Alias('Path')]
	[String] $ConfigFilePath = ".\Apply-HubLicensing - Config.csv",

    [Parameter(Mandatory = $True)]
    [Alias('Subscription')]
	[String] $SubscriptionName = "Your-Subscription-Name"
)

#region Functions

function Apply-HubLicensing {
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,
      HelpMessage='name of the Virtual Machine')]
    [Alias('vm')]
    [string]$virtualMachineName,
[Parameter(Mandatory=$True,
      HelpMessage='name of the Resource Group of the Virtual Machine')]
    [Alias('rg')]
    [string]$ResourceGroupName
  )
    
    Write-Verbose "Applying HUB licensing on VM $virtualMachineName."
    $currentVm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $virtualMachineName -ErrorAction Stop
    
    if($currentVm.storageprofile.osdisk.ostype.ToString().ToLower() -eq "windows")
    {
        Write-Host "Verified that the VM $virtualMachineName is a Windows VM."

        if(($currentVm.LicenseType -ne $null) -and ($currentVm.LicenseType.ToLower() -eq "windows_server"))
        {
            Write-Host "VM $virtualMachineName already has HUB license applied to it."
        }
        else
        {
            Write-Host "Verified that the VM $virtualMachineName does not have the HUB license applied to it."
            
            Write-Host "Setting the License Type for Hub Licensing"
            $currentVm.LicenseType = "Windows_Server"

            Write-Host "Updating the VM"
            Update-AzureRmVM -VM $currentVm -ResourceGroupName $ResourceGroupName
        }
    }
    else
    {
        Write-Host -ForegroundColor Red "Hub Licensing is not applicable for non-windows OS VM $virtualMachineName"
    }
    
}

function Test-FileExists
{
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$SourceFile
	)
	
	try
	{
		if (Test-Path $SourceFile)
		{
			Write-Debug "   Located: $SourceFile. "
			
			return $true
		}
		else
		{
			Write-Debug "   Could not locate: $SourceFile. "
			return $false
		}
	}
	catch [system.exception]
	{
		Write-Verbose "Error in Test-FileExists(): $($_.Exception.Message) "
        Write-Host "Error in Test-FileExists(): $($_.Exception.Message) "
        Write-Verbose "Error Details are: "
        Write-Verbose $Error[0].ToString()
		Stop-Transcript
		Exit $ERRORLEVEL
	}
}

#endregion


Start-Transcript $ScriptLog
Write-Verbose "======================================================================"
Write-Verbose "Script Started."

    try
    {
        #region Login into the Azure Subscription
        #TODO - If you want to make script fully automated, you can change this line to use a Service Principal (i.e. An App Registration) for Loging into Azure
        Add-AzureRmAccount

        Select-AzureRmSubscription -SubscriptionName $SubscriptionName

        #endregion

        if(Test-FileExists -SourceFile $ConfigFilePath)
        {
            $configSettings = Import-Csv -Path $ConfigFilePath
            
            foreach($configSetting in $configSettings)
            {
                Apply-HubLicensing -virtualMachineName $configSetting.Computer -ResourceGroupName $configSetting.ResourceGroupName
                #TODO - Any Additional Code can come here
            }
        }
        else
        {
            Write-Host "Configuration File not found."
        }
    }
    catch [system.exception]
	{
		Write-Verbose "Script Error: $($_.Exception.Message) "
        Write-Verbose "Error Details are: "
        Write-Verbose $Error[0].ToString()
		Stop-Transcript
	}

Write-Verbose "Script Completed. "
Write-Verbose "======================================================================"
Stop-Transcript
#endregion
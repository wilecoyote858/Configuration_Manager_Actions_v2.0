<#
.SYNOPSIS
    Trigger/Discovery The SCCM Actions On Local & Remote Machines.

.DESCRIPTION
    - Ensures script is run as Adminiistrator.
	- Request for remote computer's Hostname.
	- SCCM Actions determinied per network poilicies.

.NOTES
    Run this script as Administrator.
#>

# Ensure script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`nThis script must be run as Administrator.`n" -ForegroundColor DarkGray
    exit 1
}

# Get the local or remoter computer name.
Write-Output ""
$computer = Read-Host "Enter the Computer Name"
Write-Output ""

# Run Configuration Manager Actions
$Polices = {
	$SCCMActions = @( 
	[PSCustomObject]@{guid = "{00000000-0000-0000-0000-000000000121}"; schedule = "01_Application_Deployment_Evaluation_Cycle"},
	[PSCustomObject]@{guid = "{00000000-0000-0000-0000-000000000003}"; schedule = "02_Discovery_Data_Collection_Cycle"},
	[PSCustomObject]@{guid = "{00000000-0000-0000-0000-000000000001}"; schedule = "03_Hardware_Inventory_Cycle"},
	[PSCustomObject]@{guid = "{00000000-0000-0000-0000-000000000011}"; schedule = "04_ID_MIF_Collection_Cycle"},
	[PSCustomObject]@{guid = "{00000000-0000-0000-0000-000000000021}"; schedule = "05_Machine_Policy_Retreival_&_Evaluation_Cycle"},
	[PSCustomObject]@{guid = "{00000000-0000-0000-0000-000000000031}"; schedule = "06_Software_Metering_Usage_report_Cycle"},
	[PSCustomObject]@{guid = "{00000000-0000-0000-0000-000000000114}"; schedule = "07_Software_Updates_Deployment_Evaluation_Cycle"},
	[PSCustomObject]@{guid = "{00000000-0000-0000-0000-000000000113}"; schedule = "08_Software_Updates_Scan_Cycle"},
	[PSCustomObject]@{guid = "{00000000-0000-0000-0000-000000000022}"; schedule = "09_User_Policy_Retervial_&_Evaluation_Cycle"},
	[PSCustomObject]@{guid = "{00000000-0000-0000-0000-000000000032}"; schedule = "10_Windows_Installer_Source_List_Update_Cycle"}
	)

# $SCCMActions.schedule
# $SCCMActions.guid
# $SCCMActions

# Invoke-WMIMethod -Computername $computer -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule $SCCMActions.guid

	foreach ($action in $SCCMActions)
		{                       
			Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule $action.guid 2>$Null | Out-Null
				if ($?) {
					Write-Host -ForeGroundColor Green "SUCCESS" -NoNewline
					Write-Host " : $($action.schedule)"
				} else {
					Write-Host -ForeGroundColor Red " ERROR " -NoNewline
					Write-Host " : $($action.schedule)"
				}
		}
}

foreach ($hostName in $computer)
	{
		Invoke-Command -ScriptBlock $Polices -ComputerName $hostName
	}



# Update Group Policies
while ($true) {
	$response = $(Write-Host "`nWould you like to update Group Policies? (Y|N)" -ForeGroundColor Blue; Read-Host)
	$response = $response.Trim().ToUpper()

		# Validate Response
		if ($response -eq 'Y') {
			Write-Host "`nUpdating Group Policies..."
			Invoke-Command -ComputerName $computer -ScriptBlock { gpupdate /force }
			exit 1
		} elseif ($response -eq 'N') {
			Write-Host "`nGroup Policies have NOT been updated.`n"
			exit 1
		} else {
			Write-Host "`nInvalid input. Please enter Yes or No."
		}
}

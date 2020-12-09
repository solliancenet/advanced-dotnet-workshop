Param (
  [Parameter(Mandatory = $true)]
  [string]
  $azureUsername,

  [string]
  $azurePassword,

  [string]
  $azureTenantID,

  [string]
  $azureSubscriptionID,

  [string]
  $odlId,
    
  [string]
  $deploymentId
)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append

[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

mkdir c:\labfiles -ea silentlycontinue;

#download the solliance pacakage
$WebClient = New-Object System.Net.WebClient;
$WebClient.DownloadFile("https://raw.githubusercontent.com/solliancenet/common-workshop/main/scripts/common.ps1","C:\LabFiles\common.ps1")

#run the solliance package
. C:\LabFiles\Common.ps1

Set-Executionpolicy unrestricted -force

CreateLabFilesDirectory

cd "c:\labfiles";

CreateCredFile $azureUsername $azurePassword $azureTenantID $azureSubscriptionID $deploymentId $odlId

. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName                # READ FROM FILE
$global:password = $AzurePassword                # READ FROM FILE
$clientId = $TokenGeneratorClientId       # READ FROM FILE
$global:localusername = "wsuser"

InitSetup

DisableInternetExplorerESC

EnableIEFileDownload

InstallChocolaty;

InstallNotepadPP;

InstallDotNetCore "3.1"

InstallDotNet5;

InstallGit;

InstallFiddler;

InstallPostman;

InstallPutty;

InstallAzureCli;

InstallPorter;

InstallChrome

InstallAzPowerShellModule

InstallWSL

InstallWSL2

InstallDockerDesktop

InstallUbuntu

$ext = @("ms-vscode.azurecli")
InstallVisualStudioCode $ext

$vsVersion = "enterprise";

InstallVisualStudio $vsVersion;

$vsVersion = "preview";
InstallVisualStudio $vsVersion;

#UpdateVisualStudio $vsVersion;

#AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Workload.Azure" ;
#AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Workload.NetCoreTools" ;
#AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Workload.NetWeb" ;
#AddVisualStudioWorkload $vsVersion "Component.GitHub.VisualStudio" ;
#AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Component.Git" ;

$scriptPath = "C:\LabFiles\advanced-dotnet-workshop\artifacts\environment-setup\automation\spektra\post-install-script02.ps1"
CreateRebootTask "Setup WSL" $scriptPath $null "SYSTEM" $null;

Uninstall-AzureRm

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null
         
#install sql server cmdlets
powershell.exe -c "`$user='$username'; `$pass='$password'; try { Invoke-Command -ScriptBlock { Install-Module -Name SqlServer -force } -ComputerName localhost -Credential (New-Object System.Management.Automation.PSCredential `$user,(ConvertTo-SecureString `$pass -AsPlainText -Force)) } catch { echo `$_.Exception.Message }" 

cd "c:\labfiles";

git clone https://github.com/solliancenet/advanced-dotnet-workshop

sleep 20

Stop-Transcript

Finalize;

Restart-Computer -Force

return 0;
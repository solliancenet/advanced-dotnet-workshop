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

function InstallPorter()
{
  iwr "https://cdn.porter.sh/latest/install-windows.ps1" -UseBasicParsing | iex
}

function InstallGit()
{
  #download and install git...		
  $output = "$env:TEMP\git.exe";
  Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.27.0.windows.1/Git-2.27.0-64-bit.exe -OutFile $output; 

  $productPath = "$env:TEMP";
  $productExec = "git.exe"	
  $argList = "/SILENT"
  start-process "$productPath\$productExec" -ArgumentList $argList -wait

}

function InstallAzureCli()
{
  #install azure cli
  Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; 
  Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; 
  rm .\AzureCLI.msi
}

function InstallChocolaty()
{
  $env:chocolateyUseWindowsCompression = 'true'
  Set-ExecutionPolicy Bypass -Scope Process -Force; 
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

  choco feature enable -n allowGlobalConfirmation
}

function InstallFiddler()
{
  InstallChocolaty;

  choco install fiddler
}

function InstallPostman()
{
  InstallChocolaty;

  choco install postman
}

function InstallSmtp4Dev()
{
  InstallChocolaty;

  choco install smtp4dev
}

function InstallDocker()
{
    Install-Module -Name DockerMsftProvider -Repository PSGallery -Force;
    Install-Package -Name docker -ProviderName DockerMsftProvider;
}

function InstallDotNet5()
{
  $url = "https://download.visualstudio.microsoft.com/download/pr/21511476-7a5b-4bfe-b96e-3d9ebc1f01ab/f2cf00c22fcd52e96dfee7d18e47c343/dotnet-sdk-5.0.100-preview.7.20366.6-win-x64.exe";
  $output = "$env:TEMP\dotnet.exe";
  Invoke-WebRequest -Uri $url -OutFile $output; 

  $productPath = "$env:TEMP";
  $productExec = "dotnet.exe"	
  $argList = "/SILENT"
  start-process "$productPath\$productExec" -ArgumentList $argList -wait
}

function InstallDotNetCore($version)
{
    try
    {
        Invoke-WebRequest 'https://dot.net/v1/dotnet-install.ps1' -OutFile 'dotnet-install.ps1';
        ./dotnet-install.ps1 -Channel $version;
    }
    catch
    {
        write-host $_.exception.message;
    }
}

function InstallVisualStudioCode($AdditionalExtensions)
{
  $Architecture = "64-bit";
  $BuildEdition = "Stable";

  switch ($Architecture) 
  {
    "64-bit" {
        if ((Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture -eq "64-bit") {
            $codePath = $env:ProgramFiles
            $bitVersion = "win32-x64"
        }
        else {
            $codePath = $env:ProgramFiles
            $bitVersion = "win32"
            $Architecture = "32-bit"
        }
        break;
    }
    "32-bit" {
        if ((Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture -eq "32-bit"){
            $codePath = $env:ProgramFiles
            $bitVersion = "win32"
        }
        else {
            $codePath = ${env:ProgramFiles(x86)}
            $bitVersion = "win32"
        }
        break;
    }
}

switch ($BuildEdition) {
    "Stable" {
        $codeCmdPath = "$codePath\Microsoft VS Code\bin\code.cmd"
        $appName = "Visual Studio Code ($($Architecture))"
        break;
    }
    "Insider" {
        $codeCmdPath = "$codePath\Microsoft VS Code Insiders\bin\code-insiders.cmd"
        $appName = "Visual Studio Code - Insiders Edition ($($Architecture))"
        break;
    }
}

  if (!(Test-Path $codeCmdPath)) 
  {
    Remove-Item -Force "$env:TEMP\vscode-$($BuildEdition).exe" -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri "https://vscode-update.azurewebsites.net/latest/$($bitVersion)/$($BuildEdition)" -OutFile "$env:TEMP\vscode-$($BuildEdition).exe"

    Start-Process -Wait "$env:TEMP\vscode-$($BuildEdition).exe" -ArgumentList /silent, /mergetasks=!runcode
  }
  else {
      Write-Host "`n$appName is already installed." -ForegroundColor Yellow
  }

  $extensions = @("ms-vscode.PowerShell") + $AdditionalExtensions

  foreach ($extension in $extensions) {
      Write-Host "`nInstalling extension $extension..." -ForegroundColor Yellow
      & $codeCmdPath --install-extension $extension
  }
}

function InstallNotepadPP()
{
	#check for executables...
	$item = get-item "C:\Program Files (x86)\Notepad++\notepad++.exe" -ea silentlycontinue;
	
	if (!$item)
	{
		$downloadNotePad = "https://notepad-plus-plus.org/repository/7.x/7.5.4/npp.7.5.4.Installer.exe";

        mkdir c:\temp
		
		#download it...		
		Start-BitsTransfer -Source $DownloadNotePad -DisplayName Notepad -Destination "c:\temp\npp.exe"
		
		#install it...
		$productPath = "c:\temp";				
		$productExec = "npp.exe"	
		$argList = "/S"
		start-process "$productPath\$productExec" -ArgumentList $argList -wait
	}
}

#Disable-InternetExplorerESC
function DisableInternetExplorerESC
{
  $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
  $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
  Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force -ErrorAction SilentlyContinue -Verbose
  Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force -ErrorAction SilentlyContinue -Verbose
  Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green -Verbose
}

#Enable-InternetExplorer File Download
function EnableIEFileDownload
{
  $HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
  $HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
  Set-ItemProperty -Path $HKLM -Name "1803" -Value 0 -ErrorAction SilentlyContinue -Verbose
  Set-ItemProperty -Path $HKCU -Name "1803" -Value 0 -ErrorAction SilentlyContinue -Verbose
  Set-ItemProperty -Path $HKLM -Name "1604" -Value 0 -ErrorAction SilentlyContinue -Verbose
  Set-ItemProperty -Path $HKCU -Name "1604" -Value 0 -ErrorAction SilentlyContinue -Verbose
}

#Create InstallAzPowerShellModule
function InstallAzPowerShellModule
{
  Install-PackageProvider NuGet -Force
  Set-PSRepository PSGallery -InstallationPolicy Trusted
  Install-Module Az -Repository PSGallery -Force -AllowClobber
}

#Create-LabFilesDirectory
function CreateLabFilesDirectory
{
  New-Item -ItemType directory -Path C:\LabFiles -force
}

#Create Azure Credential File on Desktop
function CreateCredFile($azureUsername, $azurePassword, $azureTenantID, $azureSubscriptionID, $deploymentId)
{
  $WebClient = New-Object System.Net.WebClient
  $WebClient.DownloadFile("https://raw.githubusercontent.com/solliancenet/workshop-template/master/artifacts/environment-setup/automation/spektra/AzureCreds.txt","C:\LabFiles\AzureCreds.txt")
  $WebClient.DownloadFile("https://raw.githubusercontent.com/solliancenet/workshop-template/master/artifacts/environment-setup/automation/spektra/AzureCreds.ps1","C:\LabFiles\AzureCreds.ps1")

  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "ClientIdValue", ""} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureUserNameValue", "$azureUsername"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzurePasswordValue", "$azurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureSQLPasswordValue", "$azurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureTenantIDValue", "$azureTenantID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureSubscriptionIDValue", "$azureSubscriptionID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "DeploymentIDValue", "$deploymentId"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"               
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "ODLIDValue", "$odlId"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"  
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "ClientIdValue", ""} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureUserNameValue", "$azureUsername"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzurePasswordValue", "$azurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureSQLPasswordValue", "$azurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureTenantIDValue", "$azureTenantID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureSubscriptionIDValue", "$azureSubscriptionID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "DeploymentIDValue", "$deploymentId"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "ODLIDValue", "$odlId"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  Copy-Item "C:\LabFiles\AzureCreds.txt" -Destination "C:\Users\Public\Desktop"
}

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append

[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

DisableInternetExplorerESC

EnableIEFileDownload

InstallAzPowerShellModule

InstallNotepadPP

$ext = @("ms-vscode.azurecli")
InstallVisualStudioCode $ext

InstallDotNetCore "3.1"

InstallDotNet5;

InstallGit;

InstallChocolaty

InstallFiddler;

InstallPostman;

InstallAzureCli;

InstallPorter;

CreateLabFilesDirectory

cd "c:\labfiles";

CreateCredFile $azureUsername $azurePassword $azureTenantID $azureSubscriptionID $deploymentId $odlId

. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName                # READ FROM FILE
$password = $AzurePassword                # READ FROM FILE
$clientId = $TokenGeneratorClientId       # READ FROM FILE

Uninstall-AzureRm

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null
         
#install sql server cmdlets
Install-Module -Name SqlServer

git clone https://github.com/solliancenet/advanced-dotnet-workshop

sleep 20

Stop-Transcript

Restart-Computer -Force

return 0;
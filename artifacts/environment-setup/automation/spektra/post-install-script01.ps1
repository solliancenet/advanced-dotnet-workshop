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

function CreateRebootTask($name, $scriptPath)
{
    $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -file $scriptPath"
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $taskname = $name;
    
    $params = @{
      Action  = $action
      Trigger = $trigger
      TaskName = $taskname
      User = $global:localusername
      Password = $global:password
  }
    
    if(Get-ScheduledTask -TaskName $params.TaskName -EA SilentlyContinue) { 
        Set-ScheduledTask @params
        }
    else {
        Register-ScheduledTask @params
    }
}

function InstallPutty()
{
    write-host "Installing Putty";

    #check for executables...
	$item = get-item "C:\Program Files\Putty\putty.exe" -ea silentlycontinue;
	
	if (!$item)
	{
		$downloadNotePad = "https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.74-installer.msi";

        mkdir c:\temp -ea silentlycontinue 
		
		#download it...		
		Start-BitsTransfer -Source $DownloadNotePad -DisplayName Notepad -Destination "c:\temp\putty.msi"
        
        msiexec.exe /I c:\temp\Putty.msi /quiet
	}
}

function InstallPorter()
{
  write-host "Installing Porter";

  iwr "https://cdn.porter.sh/latest/install-windows.ps1" -UseBasicParsing | iex
}

function InstallGit()
{
  write-host "Installing Git";

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
  write-host "Installing Azure CLI";

  #install azure cli
  Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; 
  Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; 
  rm .\AzureCLI.msi
}

function InstallChocolaty()
{
  write-host "Installing Chocolaty";

  $env:chocolateyUseWindowsCompression = 'true'
  Set-ExecutionPolicy Bypass -Scope Process -Force; 
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

  choco feature enable -n allowGlobalConfirmation
}

function InstallFiddler()
{
  write-host "Installing Fiddler";

  InstallChocolaty;

  choco install fiddler --ignoredetectedreboot
}

function InstallPostman()
{
  write-host "Installing Postman";

  InstallChocolaty;

  choco install postman --ignoredetectedreboot
}

function InstallSmtp4Dev()
{
  write-host "Installing Smtp4Dev";

  InstallChocolaty;

  choco install smtp4dev --ignoredetectedreboot
}

function InstallDocker()
{
  write-host "Installing Docker";

  Install-Module -Name DockerMsftProvider -Repository PSGallery -Force;
  Install-Package -Name docker -ProviderName DockerMsftProvider;
}

function InstallDotNet5()
{
  write-host "Installing DotNet5";

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
  write-host "Installing Dot Core $version";

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
  write-host "Installing Visual Studio Code";

  choco install vscode --ignoredetectedreboot

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

    #latest release
    $url = "https://vscode-update.azurewebsites.net/latest/$($bitVersion)/$($BuildEdition)";

    Invoke-WebRequest -Uri $url -OutFile "C:\temp\vscode-$($BuildEdition).exe"

    Start-Process -Wait "C:\temp\vscode-$($BuildEdition).exe" -ArgumentList /silent, /mergetasks=!runcode
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
	write-host "Installing Notepad++";
    
    #check for executables...
	$item = get-item "C:\Program Files (x86)\Notepad++\notepad++.exe" -ea silentlycontinue;
	
	if (!$item)
	{
        $downloadNotePad = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.9.1/npp.7.9.1.Installer.exe";
        
        #https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.9.1/npp.7.9.1.Installer.exe

        mkdir c:\temp -ea silentlycontinue   
		
		#download it...		
        #Start-BitsTransfer -Source $DownloadNotePad -DisplayName Notepad -Destination "c:\temp\npp.exe"
        
        Invoke-WebRequest $downloadNotePad -OutFile "c:\temp\npp.exe"
		
		#install it...
		$productPath = "c:\temp";				
		$productExec = "npp.exe"	
		$argList = "/S"
		start-process "$productPath\$productExec" -ArgumentList $argList -wait
	}
}

function InstallUbuntu()
{
    write-host "Installing Ubuntu";

    winrm quickconfig -force

    $Path = "c:/temp";
    Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1604 -OutFile "$path/Ubuntu1604.appx" -UseBasicParsing

    powershell.exe -c "`$user='$localusername'; `$pass='$password'; try { Invoke-Command -ScriptBlock { Add-AppxPackage `"$path\Ubuntu1604.appx`" } -ComputerName localhost -Credential (New-Object System.Management.Automation.PSCredential `$user,(ConvertTo-SecureString `$pass -AsPlainText -Force)) } catch { echo `$_.Exception.Message }" 

    Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile "$path/Ubuntu1804.appx" -UseBasicParsing

    powershell.exe -c "`$user='$localusername'; `$pass='$password'; try { Invoke-Command -ScriptBlock { Add-AppxPackage `"$path\Ubuntu1804.appx`" } -ComputerName localhost -Credential (New-Object System.Management.Automation.PSCredential `$user,(ConvertTo-SecureString `$pass -AsPlainText -Force)) } catch { echo `$_.Exception.Message }" 

    Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-2004 -OutFile "$path/Ubuntu2004.appx" -UseBasicParsing

    powershell.exe -c "`$user='$localusername'; `$pass='$password'; try { Invoke-Command -ScriptBlock { Add-AppxPackage `"$path\Ubuntu2004.appx`" } -ComputerName localhost -Credential (New-Object System.Management.Automation.PSCredential `$user,(ConvertTo-SecureString `$pass -AsPlainText -Force)) } catch { echo `$_.Exception.Message }" 
}

function InstallChrome()
{
    write-host "Installing Chrome";

    $Path = "c:\temp"; 
    $Installer = "chrome_installer.exe"; 
    Invoke-WebRequest "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile $Path\$Installer; 
    Start-Process -FilePath $Path\$Installer -Args "/silent /install" -Verb RunAs -Wait; 
    Remove-Item $Path\$Installer
}

function InstallDockerDesktop()
{
    write-host "Installing Docker Desktop";

    <#
    mkdir c:\temp -ea silentlycontinue
    #Docker%20Desktop%20Installer.exe install --quiet

    $downloadNotePad = "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe";

    #download it...		
    Start-BitsTransfer -Source $DownloadNotePad -DisplayName Notepad -Destination "c:\temp\dockerdesktop.exe"
    
    #install it...
    $productPath = "c:\temp";				
    $productExec = "dockerdesktop.exe"	
    $argList = "install --quiet"

    $credentials = New-Object System.Management.Automation.PSCredential -ArgumentList @($localusername,(ConvertTo-SecureString -String $password -AsPlainText -Force))

    start-process "$productPath\$productExec" -ArgumentList $argList -wait -Credential $credentials
    start-process "$productPath\$productExec" -ArgumentList $argList -wait
    #>

    choco install docker-desktop --pre --ignoredetectedreboot

    Add-LocalGroupMember -Group "docker-users" -Member $localusername;

    #enable kubernets mode
    <#
    $file = "C:\Users\adminfabmedical\AppData\Roaming\Docker\settings.json";
    $data = get-content $file -raw;
    $json = ConvertFrom-Json $data;
    $json.kubernetesEnabled = $true;
    set-content $file $json;
    #>
}

function InstallWSL2
{
    write-host "Installing WSL2";

    mkdir c:\temp -ea silentlycontinue
    cd c:\temp
    
    $downloadNotePad = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi";

    #download it...		
    Start-BitsTransfer -Source $DownloadNotePad -DisplayName Notepad -Destination "wsl_update_x64.msi"

    #$credentials = New-Object System.Management.Automation.PSCredential -ArgumentList @($global:localusername,(ConvertTo-SecureString -String $global:password -AsPlainText -Force))

    #Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\wsl_update_x64.msi /quiet' -Credential $credentials
    Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\wsl_update_x64.msi /quiet'

    <#
    wsl --set-default-version 2
    wsl --set-version Ubuntu 2
    wsl --list -v
    #>
}

function InstallVisualStudio($edition)
{
    write-host "Installing Visual Studio";

    # Install Chocolatey
    if (!(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))}
        
        # Install Visual Studio 2019 Community version
        #choco install visualstudio2019community -y

        # Install Visual Studio 2019 Enterprise version
        choco install visualstudio2019enterprise -y --ignoredetectedreboot
}

function InstallVisualStudioPreview()
{
    write-host "Installing Visual Studio Preview";

    # Install Chocolatey
    if (!(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))}
        
    # Install Visual Studio 2019 Community version
    #choco install visualstudio2019community -y

    # Install Visual Studio 2019 Enterprise version
    choco install visualstudio2019enterprise-preview -pre -y --ignoredetectedreboot
}

function InstallWSL()
{
  write-host "Installing WSL";

  $script = "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"

  #& $script

  powershell.exe -c "`$user='$localusername'; `$pass='$password'; try { Invoke-Command -ScriptBlock { & $script } -ComputerName localhost -Credential (New-Object System.Management.Automation.PSCredential `$user,(ConvertTo-SecureString `$pass -AsPlainText -Force)) } catch { echo `$_.Exception.Message }" 
  
  $script = "dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"

  #& $script

  powershell.exe -c "`$user='$localusername'; `$pass='$password'; try { Invoke-Command -ScriptBlock { & $script } -ComputerName localhost -Credential (New-Object System.Management.Automation.PSCredential `$user,(ConvertTo-SecureString `$pass -AsPlainText -Force)) } catch { echo `$_.Exception.Message }" 

  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}

function UpdateVisualStudio($edition)
{
    mkdir c:\temp -ea silentlycontinue
    cd c:\temp
    
    Write-Host "Update Visual Studio." -ForegroundColor Yellow

    $Edition = 'Enterprise';
    $Channel = 'Release';
    $channelUri = "https://aka.ms/vs/16/release";
    $responseFileName = "vs";
 
    $intermedateDir = "c:\temp";
    $bootstrapper = "$intermedateDir\vs_$edition.exe"
    #$responseFile = "$PSScriptRoot\$responseFileName.json"
    #$channelId = (Get-Content $responseFile | ConvertFrom-Json).channelId
    
    $bootstrapperUri = "$channelUri/vs_$($Edition.ToLowerInvariant()).exe"
    Write-Host "Downloading Visual Studio 2019 $Edition ($Channel) bootstrapper from $bootstrapperUri"

    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($bootstrapperUri,$bootstrapper)

    #& $bootstrapper update --quiet

    Start-Process $bootstrapper -Wait -ArgumentList 'update --quiet'

    #update visual studio installer
    #& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" update --quiet

    #update visual studio
    #& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" update  --quiet --norestart --installPath 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise'

    #& $bootstrapper update  --quiet --norestart --installPath 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise'

    Start-Process $bootstrapper -Wait -ArgumentList "update --quiet --norestart --installPath 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise'"
}

function AddVisualStudioWorkload($edition, $workloadName, $isPreview)
{
    mkdir c:\temp -ea silentlycontinue
    cd c:\temp
    
    Write-Host "Adding Visual Studio workload [$workloadName]."

    if ($isPreview)
    {
        $bootstrapper = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer";
        $installPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Preview"
        Start-Process $bootstrapper -Wait -ArgumentList "modify --add $workloadName --passive --quiet --norestart --installPath `"$installPath`""   
    }
    else
    {
      $intermedateDir = "c:\temp";
      $bootstrapper = "$intermedateDir\vs_$edition.exe"
      Start-Process $bootstrapper -Wait -ArgumentList "--add $workloadName --passive --quiet --norestart"
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

Set-Executionpolicy unrestricted -force

CreateLabFilesDirectory

cd "c:\labfiles";

CreateCredFile $azureUsername $azurePassword $azureTenantID $azureSubscriptionID $deploymentId $odlId

. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName                # READ FROM FILE
$global:password = $AzurePassword                # READ FROM FILE
$clientId = $TokenGeneratorClientId       # READ FROM FILE
$global:localusername = "wsuser"

DisableInternetExplorerESC

EnableIEFileDownload

InstallNotepadPP;

InstallDotNetCore "3.1"

InstallDotNet5;

InstallGit;

InstallChocolaty;

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

#InstallVisualStudio $vsVersion
InstallVisualStudioPreview $vsVersion

#UpdateVisualStudio $vsVersion

AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Workload.Azure" $true;
AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Workload.NetCoreTools" $true;
AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Workload.NetWeb" $true;
AddVisualStudioWorkload $vsVersion "Component.GitHub.VisualStudio" $true;
AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Component.Git" $true;

reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v HideFileExt /t REG_DWORD /d 0 /f

wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true

$scriptPath = "C:\LabFiles\advanced-dotnet-workshop\artifacts\environment-setup\automation\WSLSetup.ps1"
CreateRebootTask "Setup WSL" $scriptPath

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

Restart-Computer -Force

return 0;
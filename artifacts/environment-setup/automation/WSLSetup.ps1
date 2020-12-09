<#
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
#>

function SetupWSL()
{
    wsl --set-default-version 2
    wsl --set-version Ubuntu-18.04 2
    #wsl --set-version Ubuntu-18.04 2
    wsl --list -v
}

function InstallWSL2
{
    write-host "Installing WSL2";

    mkdir c:\temp -ea silentlycontinue
    cd c:\temp
    
    $downloadNotePad = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi";

    #download it...		
    Start-BitsTransfer -Source $DownloadNotePad -DisplayName Notepad -Destination "wsl_update_x64.msi"

    $credentials = New-Object System.Management.Automation.PSCredential -ArgumentList @($localusername,(ConvertTo-SecureString -String $password -AsPlainText -Force))

    #Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\wsl_update_x64.msi /quiet' -Credential $credentials
    Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\wsl_update_x64.msi /quiet'

    <#
    wsl --set-default-version 2
    wsl --set-version Ubuntu 2
    wsl --list -v
    #>
}

function InstallUbuntu()
{
    write-host "Installing Ubuntu (1604)";
    Add-AppxProvisionedPackage -Online -PackagePath C:\temp\Ubuntu1604.appx -skiplicense

    cd 'C:\Program Files\WindowsApps\'
    $installCommand = (Get-ChildItem -Path ".\" -Recurse ubuntu1604.exe)[0].Directory.FullName
    $installCommand += "\Ubuntu1604.exe"
    start-process $installCommand;

    write-host "Installing Ubuntu (1804)";
    Add-AppxProvisionedPackage -Online -PackagePath C:\temp\Ubuntu1804.appx -skiplicense

    $installCommand = (Get-ChildItem -Path ".\" -Recurse ubuntu1804.exe)[0].Directory.FullName + "\Ubuntu1804.exe"
    start-process $installCommand;

    write-host "Installing Ubuntu (2004)";
    Add-AppxProvisionedPackage -Online -PackagePath C:\temp\Ubuntu2004.appx -skiplicense

    $installCommand = (Get-ChildItem -Path ".\" -Recurse ubuntu2004.exe)[0].Directory.FullName + "\Ubuntu2004.exe"
    start-process $installCommand;

    start-sleep 30
}

#run the solliance package
. C:\LabFiles\Common.ps1

InstallWSL2

InstallUbuntu

SetupWSL

$vsVersion = "enterprise";
AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Workload.NetCoreTools" ;
AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Workload.NetWeb" ;
AddVisualStudioWorkload $vsVersion "Component.GitHub.VisualStudio" ;
AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Component.Git" ;
AddVisualStudioWorkload $vsVersion "Microsoft.VisualStudio.Workload.Azure" ;

#diable the task
Disable-ScheduledTask -TaskName "Setup WSL"
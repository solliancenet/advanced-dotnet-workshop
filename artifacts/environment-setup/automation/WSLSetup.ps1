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
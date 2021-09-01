#######################
# Script Approvazione Automatica Update
# Dario Bonini
# Versione 2.0.0
# Data 01-09-2021
#######################


###########  importante - percorso predefinito di download ed esecuzione script ##########
# impostare la folder
$plvdb_scriptfolder = "C:\_\ddgsms4update"
Set-Location -Path $plvdb_scriptfolder
###################################


########### revisioni
#
# 2.0.0  > Riscrittura e ottimizzazioni
#          La procedura di approvazione è automatica 
#          le patche vengono approvate per tutti i computer (in questa versione non è possibile scegliere il gruppo di applicazione)
#          Vegono apporvate tutte le patch richieste e non soppresse per tutti i sistemi tranne:
#                2008r2 e precedenti > tutte le patch richieste compreso le sosotuite
###########


$dataodierna = Get-Date -Format "yyyyMMdd-HHmm"
$transcriptlogfile = $plvdb_scriptfolder+"\_persistent_\log\ApproveLog-"+$dataodierna+".txt"
Start-Transcript -Path $transcriptlogfile -IncludeInvocationHeader


### carico Variabili e componenti necessari
. .\bin\function.ps1
. .\bin\variable.ps1




# Load .NET assembly
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")

write-host "Connetto al server "$NomeHostWsusServer" sulla porta numero "$portNumber"  
se questi parametri non sono corretti modificare C:\_\ddgsms4update\bin\variable.ps1 " 
$UpdateServer = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($NomeHostWsusServer,$useSecureConnection,$portNumber)
sleep 1

write-host "Creo Scope"
$Updatescope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
sleep 1

write-host "Genero elenco patch via API"
if ($global:GGTempElencoPatchAPI -eq $null){$global:GGTempElencoPatchAPI = $UpdateServer.GetUpdates($updatescope)}
$ElencoPatch = $global:GGTempElencoPatchAPI
sleep 1

write-host "Creo parametro server PS"
$WSUSserverPS = Get-WsusServer -Name $NomeHostWsusServer -PortNumber $portNumber 
sleep 1

write-host "rifuito update Preview"
$countpreview=0
foreach ($Patch in $ElencoPatch){
#	if ($u1.IsSuperseded -eq 'True')
	if ($Patch.Title -like '*Preview*')	{
		write-host Preview Update : $Patch.Title
		$Patch.Decline()
		$countpreview=$countpreview + 1
	}
}
sleep 1

write-host "approvo le licenze"
$countlicense = 0
foreach ($Patch in $ElencoPatch){
	if ($Patch.RequiresLicenseAgreementAcceptance)	{
		write-host Needs License Agreement Acceptance : $Patch.Title
		$Patch.AcceptLicenseAgreement()
		$countlicense=$countlicense + 1
	}
}
write-host Total License Agreement Accepted: $countlicense
sleep 1
















Write-Host "

I Log e le attività eseguite in questo script sono salvate in  " $transcriptlogfile
Stop-Transcript
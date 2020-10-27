###########  importante - percorso predefinito di download ed esecuzione script ##########
# impostare la folder
[String]$PercorsoScript = "C:\_\ddgsms4update"     # percorso in cui si trovano gli script
Set-Location -Path $PercorsoScript  -PassThru
sleep 1
###################################


. .\Function.ps1
. .\Variable.ps1


# Load .NET assembly
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")

write-host "Connetto al server"
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

write-host "rifuito update scaduti"
DeclinaPatchPrewiew
sleep 1

write-host "approvo le licenze"
ApprovaLicenze
sleep 1

#$updatesneeded = Get-WsusUpdate -UpdateServer $WSUSserverPS -Approval AnyExceptDeclined -Status needed | Where-Object  {($_.UpdatesSupersedingThisUpdate -EQ 'None') -and ($_.Classification -ne "Upgrades") -and ($_.Classification -ne "Drivers") -and  ($_.Classification -ne "Updates")}
#write-host "Verifico Update Cache File"
#VerificaAggiornaCacheFile
if ($global:GGTempElencoPatchPS -eq $null){
write-host "attendere - sto caricando la lista update - potrebbe essere necessario qualche minuto"
$global:GGTempElencoPatchPS = Get-WsusUpdate -UpdateServer $WSUSserverPS -Approval AnyExceptDeclined -Status needed |  
# filtro originale
# Where-Object  {($_.UpdatesSupersedingThisUpdate -EQ 'None') -and ($_.Classification -ne "Upgrades") -and ($_.Classification -ne "Drivers") -and  ($_.Classification -ne "Updates")}}
#
# filtro per includere i 2008 anche se sono soppressi
Where-Object  {( ($_.Classification -ne "Upgrades") -and ($_.Classification -ne "Drivers") -and  ($_.Classification -ne "Updates")  )} | 
Where-Object  {((($_.UpdatesSupersedingThisUpdate -EQ 'None'))  -or (($_.Products -like 'Windows Server 2008*')))}
}
sleep 1

write-host "Importo update cache"
#[array]$updatesneeded = Import-Clixml  -Path $updatecachefullpath
$updatesneeded = $global:GGTempElencoPatchPS
sleep 1




[string]$VarUpdateMenu = $null
#[array]$elencogruppidamostrare = CreaElencoGruppiWsus
CreaElencoGruppiWsus
do {

[array]$VarShoweMenu = ShoweMenu
Write-Host "

hai digitato:  $VarShoweMenu 

"

if (($VarShoweMenu -ne $null) -and ($VarShoweMenu -notlike "*notvalid*") -and ($VarShoweMenu -notin (991,992,993,990))){ ApprovaUpdatePerGruppi -elencogruppi $VarShoweMenu.name }


#sleep 4
} until ($VarShoweMenu -eq $null)





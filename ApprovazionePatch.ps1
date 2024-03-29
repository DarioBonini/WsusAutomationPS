﻿#######################
# Script Approvazione Automatica Update
# Dario Bonini
# Versione (vedi sotto ultima revisione)
# Data 22-09-2021
#######################


########### revisioni ##########
#
# 2.0.0  > Riscrittura e ottimizzazioni
#          La procedura di approvazione è automatica 
#          le patche vengono approvate per tutti i computer (in questa versione non è possibile scegliere il gruppo di applicazione)
#          Vegono approvate tutte le patch richieste e non soppresse per tutti i sistemi tranne:
#                2008r2 e precedenti > tutte le patch richieste compreso le sostituite
#          NOTA: con questa versione eventuali upgrade build Win 10 devono essere approvati a mano - non gestiti dallo script
# 2.1.0  > Aggiunto lingua italiana al filtro selezione patch
# 2.1.1  > Minor Fix
###########


###########  importante - percorso predefinito di download ed esecuzione script ##########
# impostare la folder
$plvdb_scriptfolder = "C:\_\ddgsms4update"
Set-Location -Path $plvdb_scriptfolder
###################################

$dataodierna = Get-Date -Format "yyyyMMdd-HHmm"
$transcriptlogfile = $plvdb_scriptfolder+"\_persistent_\log\ApproveLog-"+$dataodierna+".txt"
Start-Transcript -Path $transcriptlogfile -IncludeInvocationHeader


### carico Variabili e componenti necessari
. .\bin\function.ps1
. .\bin\variable.ps1

cls
write-host "!!!   Attenzione   !!!

Il presente script deve essere lanciato con privilegi amministrativi.
In caso di errorei accertarsi che ISE o PS siano aperti come admin.
Verificare anche impostazioni UAC (impostazioni corrette = default = livello 3 )
" -ForegroundColor DarkYellow
sleep 2



# Load .NET assembly
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")

write-host "
Connetto al server "$NomeHostWsusServer" sulla porta numero "$portNumber"  
se questi parametri non sono corretti modificare C:\_\ddgsms4update\bin\variable.ps1 " 
$UpdateServer = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($NomeHostWsusServer,$useSecureConnection,$portNumber)
$UpdateServer
sleep 1

write-host "
Creo Scope"
$Updatescope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$Updatescope
sleep 1

write-host "
Genero elenco patch via API"
$ElencoPatch = $UpdateServer.GetUpdates($updatescope)
Write-Host "Di seguito un elenco di 10 patch al solo scopo di verifica e debug
elenco completo consultabile con la variabile `$elencopatch" 
$ElencoPatch | Select-Object -First 10 |ft Title,MsrcSeverity,UpdateClassificationTitle,IsApproved,IsDeclined
sleep 1

write-host "
Creo parametro server PS"
$WSUSserverPS = Get-WsusServer -Name $NomeHostWsusServer -PortNumber $portNumber 
$WSUSserverPS
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
write-host Total Update preview rifiutati : $countpreview
write-host ""
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
write-host ""
sleep 1



write-host "attendere - sto caricando la lista update via PowerShell - potrebbe essere necessario qualche minuto
"

$ElencoPatchPSneeded = Get-WsusUpdate -UpdateServer $WSUSserverPS -Approval AnyExceptDeclined -Status needed
Write-Host "####
totale patch needed e non declined" 
$ElencoPatchPSneeded.count
Write-Host "####"
$ElencoPatchPSneeded | Select-Object -First 5 | ft


$ElencoPatchPS = $ElencoPatchPSneeded |
# filtro originale
# Where-Object  {($_.UpdatesSupersedingThisUpdate -EQ 'None') -and ($_.Classification -ne "Upgrades") -and ($_.Classification -ne "Drivers") -and  ($_.Classification -ne "Updates")}}
# Where-Object  {( ($_.Classification -ne "Upgrades") -and ($_.Classification -ne "Drivers") -and  ($_.Classification -ne "Updates")  )} |

#si passa per sicurezza ad un filtro basato su inclusioni > vedi sotto 
Where-Object  {( (
$_.Classification -eq "Critical Updates") -or ($_.Classification -eq "Aggiornamenti critici") -or (
$_.Classification -eq "Definition Updates") -or  ($_.Classification -eq "Aggiornamenti delle definizioni") -or  (
$_.Classification -eq "Security Updates")  -or  ($_.Classification -eq "Aggiornamenti della protezione")  -or  (
$_.Classification -eq "Update Rollups")  -or  ($_.Classification -eq "Raccolta completa di aggiornamenti")  -or  (
$_.Classification -eq "Service Packs") -or ($_.Classification -eq "Service Packs")
# -and  (
# filtro basato su esclusioni - a volte se la lingua non coincide tra WSUS e S.O. vengono inclusi update che non ci devono essere
# viene quindi usato il precedente filtro basato su INCLUSIONI
#$_.Classification -ne "Updates") -and  (
#$_.Classification -ne "Upgrades") -and  (
#$_.Classification -ne "Drivers")  -and  (
#$_.Classification -ne "Feature Packs")  -and  (
#$_.Classification -ne "Tools") 
)} |
#
#
# filtro per includere i 2008 anche se sono soppressi
Where-Object  {((($_.UpdatesSupersedingThisUpdate -EQ 'None'))  -or (($_.Products -like 'Windows Server 2008*')))}

## debug manuale raccolta patch via PS
if (! $ElencoPatchPS) {write-host "Attenzione!  l'elenco patch non è stato caricato
se si tratta del primo utilizzo dello script, eseguire le seguenti verifiche:
1° aprire Update Services (aka pannello patch WSUS) e verificare che l'eleco patch sia visibile
2° riavviare il server Wsus
3° eseguire WSUS Server cleanup wizard
4° lanciare questo script via ISE (come amministratore) e al termine lanciare il seguente comando nella stessa console in cui ha girato lo script e attendere il completamento

     Get-WsusUpdate -UpdateServer `$WSUSserverPS -Approval AnyExceptDeclined -Status needed

4.1° potrebbe essere necessario lanciare lo script piu volte (dipende dalle performance del server)
           " -ForegroundColor Red}
    
        else {  #$ElencoPatchPS | Select-Object -First 5 | ft
Write-host "
Numero patch filtrate in base ai criteri"
$ElencoPatchPS.count
               }

sleep 1

# Eseguo approvazione delle patch 
# eseguo approvazione per tutte le patch anche quelle gia approvate in precedenza > questo risolve evntuali problemi di patche che sono state approvate manualemnte per gruppi ristretti di computer
#
$i = 0 
$total = $ElencoPatchPS.Count 
$GroupToApprove =  "All Computers"
        foreach ($update in $ElencoPatchPS)  
        {  
            Write-Progress -Activity "Approving needed updates..." -Status $($update.Update.Title) -PercentComplete (($i/$total) * 100) 
            Approve-WsusUpdate -Update $update -Action Install -TargetGroupName $GroupToApprove 
            $i++ 
            Write-Host "Updates approved per il gruppo $Group : " $update.Update.Title -ForegroundColor Yellow 
        } # end ciclo foreach update

Write-Host "####"
Write-Host "Patch necessarie"
$ElencoPatchPS.Count 

Write-Host  "

Patch approvate"
$i 
Write-Host "####"






Write-Host "

I Log e le attività eseguite in questo script sono salvate in  " $transcriptlogfile
Stop-Transcript
pause
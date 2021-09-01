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
$transcriptlogfile = $plvdb_scriptfolder+"\ApproveLog"+$dataodierna+".txt"
Start-Transcript -Path $transcriptlogfile -IncludeInvocationHeader


### carico Variabili e componenti necessari
. .\bin\function.ps1
. .\bin\variable.ps1


















Write-Host "I Log e le attività eseguite in questo script sono salvate in  "
Stop-Transcript
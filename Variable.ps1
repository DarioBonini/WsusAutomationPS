############## Variabili predefiniti funzione download da github
[string]$UserPreset="DarioBonini"
[string]$TokenPreset="fb28793262c58d5682497245eab769bc138f08d3"  # Read-only Token
[string]$OwnerPreset=$UserPreset
[string]$RepositoryPreset="WsusAutomationPS"

############## Variabili usate in 000-UpdateScript
[string]$localexecutionfolder = get-location
[string]$FolderVersionCompare = "$localexecutionfolder" +"\_tmp_VersionCheckFolder"
[string]$FileVersioneAttuale=".\version.txt"
[string]$FileVersioneDisponibile= $FolderVersionCompare +"\version.txt"
[int]$VersioneAttuale = 0
[int]$VersioneDisponibile = 0

#####################################################################
#####################################################################
# variabili usati nei rimanenti script

# DryRun
#[Boolean]$dryrun = $False
[Boolean]$dryrun = $true


# [String]$NomeHostWsusServer = "WSUS2019"      # impostare il nome del server WSUS;
[String]$NomeHostWsusServer = hostname              # impostare il nome del server WSUS;
[Boolean]$useSecureConnection = $False				# ipostare se utilizza una connessione sicura;	
[Int32]$portNumber = 8530                           # numero di porta utilizzato per la connessione;	
[String]$ColonnaUpdate = "ddgUpdate"                # indica il TAG da ricercare nel file CSV (esportato con RVtolls) che indica come gestire la VM
[String]$defAutoUpdate = "auto"                     # Definisce la stringa di gestione VM in AutoUpdate
[String]$defManualUpdate = "manual"                 # Definisce la stringa di gestione VM in Manual Update
[String]$defPilotUpdate = "pilot"                   # Definisce la stringa di gestione VM in Pilot
[String]$gruppoADManualUpdate =  "DDG_Sms4Update_ServerManual"	# Indica il nome del gruppo AD utilizzato per gli update Manuali (VM Manual update)
[String]$gruppoADAutoUpdate = "DDG_Sms4Update_ServerAuto"	    # Indica il nome del gruppo AD utilizzato per gli update Auto (VM Auto update)
[String]$gruppoADPilotUpdate = "DDG_Sms4Update_ServerPilot"	    # Indica il nome del gruppo AD utilizzato per gli update Pilot (VM Pilot update)
[String]$gruppoADAutoUpdateGruppoA = "DDG_Sms4Update_ServerAuto-GruppoA"
[String]$gruppoADAutoUpdateGruppoB = "DDG_Sms4Update_ServerAuto-GruppoB"
[String]$updatecahepath = ".\_tmp_updatecache\"
[String]$updatecachefile = "updatecache.xml"
[String]$updatecachefileAPI = "updatecacheAPI.xml"
[string]$updatecachefullpath = $updatecahepath+$updatecachefile
        $DateOdierna = Get-Date
        $DataValiditaCache = $DateOdierna.AddHours(-48)




############################################
#
#
#
#
###########################################



############## Variabili predefiniti funzione download da github
[string]$UserPreset="DarioBonini"
[string]$TokenPreset="fb28793262c58d5682497245eab769bc138f08d3"  # Read-only Token
[string]$OwnerPreset=$UserPreset
[string]$RepositoryPreset="WsusAutomationPS"


########### variabili connessione server WSUS
[String]$NomeHostWsusServer = hostname              # impostare il nome del server WSUS;
[Boolean]$useSecureConnection = $False				# ipostare se utilizza una connessione sicura;	
[Int32]$portNumber = 8530                           # numero di porta utilizzato per la connessione;	
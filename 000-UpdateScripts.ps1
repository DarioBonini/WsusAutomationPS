###########  importante - percorso predefinito di download ed esecuzione script ##########
# impostare la folder
Set-Location -Path "C:\_\ddgsms4update"
###################################

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
cls

#pulisco file FileVersioneDisponibile
remove-item $FileVersioneDisponibile -Force




function DownloadFilesFromRepo {
	
	<#
	.SYNOPSIS
		This function retrieves the specified repository on GitHub to a local directory with authentication.

	.DESCRIPTION
		This function retrieves the specified repository on GitHub to a local directory with authentication, being a single file, a complete folder, or the entire repository.

	.PARAMETER User
		Your GitHub username, for using the Authenticated Service. Providing 5000 requests per hour.
		Without this you will be limited to 60 requests per hour.
		See for more information: https://developer.github.com/v3/auth/

	.PARAMETER Token
		The parameter Token is the generated token for authenticated users.
		Create one here (after logging in on your account): https://github.com/settings/tokens

	.PARAMETER Owner
		Owner of the repository you want to download from.

	.PARAMETER Repository
		The repository name you want to download from.

	.PARAMETER Path
		The path inside the repository you want to download from.
		If empty, the function will iterate the whole repository.
		Alternatively you can specify a single file.

	.PARAMETER DestinationPath
		The local folder you want to download the repository to.

	.EXAMPLE
		PS C:\> DownloadFilesFromRepo -User "MyUsername" -Token "My40CharactersLongToken" -Owner "GitHubDeveloper" -Repository "RepositoryName" -Path "InternalFolder" -DestinationPath "C:/MyDownloadedRepository"
		
	.NOTES
		Author: chrisbrownie | https://gist.github.com/chrisbrownie/f20cb4508975fb7fb5da145d3d38024a
		Modified: zeroTAG | https://gist.github.com/zerotag/78207737bafba0792c98663e81f211bf
		Last Edit: 2019-06-15
		Version 1.0 - initial release of DownloadFilesFromRepo
	#>

	Param(
		[Parameter(Mandatory=$True)]
		[string]$User,

		[Parameter(Mandatory=$True)]
		[string]$Token,

		[Parameter(Mandatory=$True)]
		[string]$Owner,

		[Parameter(Mandatory=$True)]
		[string]$Repository,

		[Parameter(Mandatory=$True)]
		[AllowEmptyString()]
		[string]$Path,

		[Parameter(Mandatory=$True)]
		[string]$DestinationPath
	)

	# Authentication
	$authPair = "$($User):$($Token)";
	$encAuth = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($authPair));
	$headers = @{ Authorization = "Basic $encAuth" };
	
	# REST Building
	$baseUri = "https://api.github.com";
	$argsUri = "repos/$Owner/$Repository/contents/$Path";
	$wr = Invoke-WebRequest -Uri ("$baseUri/$argsUri") -Headers $headers;

	# Data Handler
	$objects = $wr.Content | ConvertFrom-Json
	$files = $objects | where {$_.type -eq "file"} | Select -exp download_url
	$directories = $objects | where {$_.type -eq "dir"}
	
	# Iterate Directory
	$directories | ForEach-Object { 
		DownloadFilesFromRepo -User $User -Token $Token -Owner $Owner -Repository $Repository -Path $_.path -DestinationPath "$($DestinationPath)/$($_.name)"
	}

	# Destination Handler
	if (-not (Test-Path $DestinationPath)) {
		try {
			New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop;
		} catch {
			throw "Could not create path '$DestinationPath'!";
		}
	}

	# Iterate Files
	foreach ($file in $files) {
		$fileDestination = Join-Path $DestinationPath (Split-Path $file -Leaf)
		$outputFilename = $fileDestination.Replace("%20", " ");
		try {
			Invoke-WebRequest -Uri "$file" -OutFile "$outputFilename" -ErrorAction Stop -Verbose
			"Grabbed '$($file)' to '$outputFilename'";
		} catch {
			throw "Unable to download '$($file)'";
		}
	}
}



function FullDownloadScript {

DownloadFilesFromRepo -owner $OwnerPreset -Repository $RepositoryPreset -DestinationPath "$localexecutionfolder"  -User $UserPreset  -Path "" -Token $TokenPreset
}


### scarico il file di versione dal sito

DownloadFilesFromRepo -owner $OwnerPreset -Repository $RepositoryPreset -DestinationPath "$FolderVersionCompare"  -User $UserPreset  -Path "/Version.txt" -Token $TokenPreset

sleep 1





if (Test-Path $fileversioneattuale) {
$VersioneAttuale=Get-Content $FileVersioneAttuale
    Write-Host "
    file di versione presente!
    Versione Attuale Rilevata =  $VersioneAttuale
    "}

else {
    Write-Host "file di versione NON valido
    "
# esegui download full - da implementare
$VersioneAttuale = 0
}

$VersioneDisponibile = Get-Content $FileVersioneDisponibile
if ($VersioneAttuale -lt $VersioneDisponibile){
    FullDownloadScript
    Write-Host "
    Versione piu nuova disponibile : $VersioneDisponibile
    eseguito download di nuova versione in: $localexecutionfolder
    "
    }
if ($VersioneAttuale -ge $VersioneDisponibile){write-host "

    
    versione aggiorata o (piu nuova??)
    aggiornameto non necessario"
    }

function AggiornaVersioneRepo{
[int]$VersioneAttuale=Get-Content $FileVersioneAttuale
$VersioneAttuale++
$VersioneAttuale | Out-File $FileVersioneAttuale

}

function DeclinaPatchPrewiew{
$count = 0

foreach ($Patch in $ElencoPatch){
#	if ($u1.IsSuperseded -eq 'True')
	if ($Patch.Title -like '*Preview*')	{
		write-host Preview Update : $Patch.Title
		$Patch.Decline()
		$count=$count + 1
	}
}

write-host Total Preview Updates Declined: $count
trap

    {
    write-host "Error Occurred"
    write-host "Exception Message: "
    write-host $_.Exception.Message
    write-host $_.Exception.StackTrace
    exit
    }

}

Function ApprovaLicenze{

$count = 0

foreach ($Patch in $ElencoPatch){
	if ($Patch.RequiresLicenseAgreementAcceptance)	{
		write-host Needs License Agreement Acceptance : $Patch.Title
		$Patch.AcceptLicenseAgreement()
		$count=$count + 1
	}
}

write-host Total License Agreement Accepted: $count
    trap

    {
    write-host "Error Occurred"
    write-host "Exception Message: "
    write-host $_.Exception.Message
    write-host $_.Exception.StackTrace
    exit
    }
}

Function ShoweMenu {


#$GruppiTotali = @()
Write-Host "a seguire l'elengo dei gruppi disponibili:

Selezione            Nome Gruppo"
$elencogruppidamostrareindex = 0 
foreach  ($elencogruppidamostrarelist in $script:elencogruppidamostrare)   {
                $elencogruppidamostrareindex ++
                write-host "$elencogruppidamostrareindex   ------------->   "$elencogruppidamostrarelist.name
                # [$elencogruppidamostrareindex].Name"
                }
[int]$RichiediGruppo = Read-Host -Prompt '
Inserisci il numero del gruppo su cui applicare gli update - oppure:

- lasciare vuoto o digitare "0" per interrompere lo script
- digitare 991 per tutti i gruppi pilot
- digitare 992 per tutti i gruppi auto
- digitare 993 per tutti i gruppi manual 
- digitare 990 per generare nuovamente l eleco di gruppi'

# $GruppiTotali = "$Gruppoinserito"   #questo gruppo viene usato nella funzione "ApprovaGliUpdate"

if (($RichiediGruppo -eq $null) -or ($RichiediGruppo -eq "") -or (!$RichiediGruppo)) {
    #cls
    Write-Host "Inserito valore fine scrip: esco" -foreground yellow
    return
    }

if ($RichiediGruppo -in (990,991,992,993)) {
    #cls
    if ($RichiediGruppo -in (990)) {CreaElencoGruppiWsus
                                    return $RichiediGruppo}
    if ($RichiediGruppo -in (991)) {$RichiediGruppoArray = $script:elencogruppidamostrare | Where-Object {$_.name -like "*pilot*"}}
    if ($RichiediGruppo -in (992)) {$RichiediGruppoArray = $script:elencogruppidamostrare | Where-Object {$_.name -like "*auto*"}}
    if ($RichiediGruppo -in (993)) {$RichiediGruppoArray = $script:elencogruppidamostrare | Where-Object {$_.name -like "*manua*"}}
    write-host "Fubzione non implementata: selezionare altro gruppo" -foreground green
    return $RichiediGruppoArray
    }
if ($RichiediGruppo -gt $elencogruppidamostrareindex){
    Write-Host "gruppo non riconosciuto" -foreground red
    #cls
    return "$RichiediGruppo   - >  notvalidgroup"
    #ShoweMenu
    }
$script:elencogruppidamostrare[$RichiediGruppo-1]
}

Function CreaElencoGruppiWsus{
 [array]$script:elencogruppidamostrare =  $WSUSserverPS.GetComputerTargetGroups() | Sort-Object Name | Select-Object Name
    }

Function ApprovaUpdatePerGruppi {
 Param(
        [Parameter()][array]$elencogruppi	  
       )


# Approva le update filtrate nella variabile ""$updatesneeded = $global:GGTempElencoPatchPS""
#$updatesneeded = Get-WsusUpdate -UpdateServer $WSUSserver -Approval AnyExceptDeclined <# -Approval Unapproved >>> modifica per ri-apporvare aggiornamenti gia approvati #> -Status needed | Where-Object  {($_.UpdatesSupersedingThisUpdate -EQ 'None') -and ($_.Classification -ne "Upgrades") -and ($_.Classification -ne "Drivers") -and  ($_.Classification -ne "Updates")}
<#
$update2 = $updatesneeded | Where-Object -Property UpdatesSupersedingThisUpdate -EQ -Value 'None'
$update2 = $updatesneeded | Where-Object  {($_.UpdatesSupersedingThisUpdate -EQ 'None') -and ($_.Classification -EQ "Upgrades")} 
$update2
#>
foreach ($Group in $elencogruppi){

        $i = 0 
        $total = $updatesneeded.Count 
        foreach ($update in $updatesneeded)  
        {  
            Write-Progress -Activity "Approving needed updates..." -Status $($update.Update.Title) -PercentComplete (($i/$total) * 100) 
            Approve-WsusUpdate -Update $update -Action Install -TargetGroupName $Group 
            $i++ 
            Write-Host "Updates approved per il gruppo $Group : " $update.Update.Title -ForegroundColor Yellow 
        } # end ciclo foreach update
        Write-Host "

        Total Updates approved per il gruppo" $Group"  : "$total -ForegroundColor Yellow 
        Write-Host " 

        Approvazione aggiornamnti completata per il gruppo:  "$Group
        Write-Host ""

        pause

        #----------------------
        } # end ciclo foreach sui gruppi

Write-Host "aggiornamenti approvati sui seguenti grppi" $elencogruppi

}

function VerificaAggiornaCacheFile {
# verifico se esiste la folder e la creo
if (!(Test-Path -PathType Container $updatecahepath)) {New-Item -ItemType Directory -Force -Path $updatecahepath  >> $null}
        #verifico se esiste la cache e se è valida
        if (Test-Path  $updatecachefullpath){$filedegliupdate = get-childitem $updatecachefullpath
                        if ($filedegliupdate.LastWriteTime -gt $DataValiditaCache) {
                        Write-Host "la cache update è valida"
                        $cachevalid = 1}
                        else {write-host "cache scaduta"
                        $cachevalid = 0}
                        }
else {
write-host "file cache non presente"
$cachevalid = 0}

if ($cachevalid -eq "0"){
        write-host "attendere - sto caricando la lista update - potrebbe essere necessario qualche minuto"
        $tmpupdatelist = Get-WsusUpdate -UpdateServer $WSUSserverPS -Approval AnyExceptDeclined -Status needed |   Where-Object  {($_.UpdatesSupersedingThisUpdate -EQ 'None') -and ($_.Classification -ne "Upgrades") -and ($_.Classification -ne "Drivers") -and  ($_.Classification -ne "Updates")}
        # -Approval Unapproved >>> modifica per ri-apporvare aggiornamenti gia approvati per altri gruppi altrimenti ignorati
        $tmpupdatelist | Export-Clixml -Path $updatecachefullpath}    
 }

 function Import-Xls { 
 
<# 
.SYNOPSIS 
Import an Excel file. 
 
.DESCRIPTION 
Import an excel file. Since Excel files can have multiple worksheets, you can specify the worksheet you want to import. You can specify it by number (1, 2, 3) or by name (Sheet1, Sheet2, Sheet3). Imports Worksheet 1 by default. 
 
.PARAMETER Path 
Specifies the path to the Excel file to import. You can also pipe a path to Import-Xls. 
 
.PARAMETER Worksheet 
Specifies the worksheet to import in the Excel file. You can specify it by name or by number. The default is 1. 
Note: Charts don't count as worksheets, so they don't affect the Worksheet numbers. 
 
.INPUTS 
System.String 
 
.OUTPUTS 
Object 
 
.EXAMPLE 
".\employees.xlsx" | Import-Xls -Worksheet 1 
Import Worksheet 1 from employees.xlsx 
 
.EXAMPLE 
".\employees.xlsx" | Import-Xls -Worksheet "Sheet2" 
Import Worksheet "Sheet2" from employees.xlsx 
 
.EXAMPLE 
".\deptA.xslx", ".\deptB.xlsx" | Import-Xls -Worksheet 3 
Import Worksheet 3 from deptA.xlsx and deptB.xlsx. 
Make sure that the worksheets have the same headers, or have some headers in common, or that it works the way you expect. 
 
.EXAMPLE 
Get-ChildItem *.xlsx | Import-Xls -Worksheet "Employees" 
Import Worksheet "Employees" from all .xlsx files in the current directory. 
Make sure that the worksheets have the same headers, or have some headers in common, or that it works the way you expect. 
 
.LINK 
Import-Xls 
http://gallery.technet.microsoft.com/scriptcenter/17bcabe7-322a-43d3-9a27-f3f96618c74b 
Export-Xls 
http://gallery.technet.microsoft.com/scriptcenter/d41565f1-37ef-43cb-9462-a08cd5a610e2 
Import-Csv 
Export-Csv 
 
.NOTES 
Author: Francis de la Cerna 
Created: 2011-03-27 
Modified: 2011-04-09 
#Requires –Version 2.0 
#> 
 
    [CmdletBinding(SupportsShouldProcess=$true)] 
     
    Param( 
        [parameter( 
            mandatory=$true,  
            position=1,  
            ValueFromPipeline=$true,  
            ValueFromPipelineByPropertyName=$true)] 
        [String[]] 
        $Path, 
     
        [parameter(mandatory=$false)] 
        $Worksheet = 1, 
         
        [parameter(mandatory=$false)] 
        [switch] 
        $Force 
    ) 
 
    Begin 
    { 
        function GetTempFileName($extension) 
        { 
            $temp = [io.path]::GetTempFileName(); 
            $params = @{ 
                Path = $temp; 
                Destination = $temp + $extension; 
                Confirm = $false; 
                Verbose = $VerbosePreference; 
            } 
            Move-Item @params; 
            $temp += $extension; 
            return $temp; 
        } 
             
        # since an extension like .xls can have multiple formats, this 
        # will need to be changed 
        # 
        $xlFileFormats = @{ 
            # single worksheet formats 
            '.csv'  = 6;        # 6, 22, 23, 24 
            '.dbf'  = 11;       # 7, 8, 11 
            '.dif'  = 9;        #  
            '.prn'  = 36;       #  
            '.slk'  = 2;        # 2, 10 
            '.wk1'  = 31;       # 5, 30, 31 
            '.wk3'  = 32;       # 15, 32 
            '.wk4'  = 38;       #  
            '.wks'  = 4;        #  
            '.xlw'  = 35;       #  
             
            # multiple worksheet formats 
            '.xls'  = -4143;    # -4143, 1, 16, 18, 29, 33, 39, 43 
            '.xlsb' = 50;       # 
            '.xlsm' = 52;       # 
            '.xlsx' = 51;       # 
            '.xml'  = 46;       # 
            '.ods'  = 60;       # 
        } 
         
        $xl = New-Object -ComObject Excel.Application; 
        $xl.DisplayAlerts = $false; 
        $xl.Visible = $false; 
    } 
 
    Process 
    { 
        $Path | ForEach-Object { 
             
            if ($Force -or $psCmdlet.ShouldProcess($_)) { 
             
                $fileExist = Test-Path $_ 
 
                if (-not $fileExist) { 
                    Write-Error "Error: $_ does not exist" -Category ResourceUnavailable;             
                } else { 
                    # create temporary .csv file from excel file and import .csv 
                    # 
                    $_ = (Resolve-Path $_).toString(); 
                    $wb = $xl.Workbooks.Add($_); 
                    if ($?) { 
                        $csvTemp = GetTempFileName(".csv"); 
                        $ws = $wb.Worksheets.Item($Worksheet); 
                        $ws.SaveAs($csvTemp, $xlFileFormats[".csv"]); 
                        $wb.Close($false); 
                        Remove-Variable -Name ('ws', 'wb') -Confirm:$false; 
                        Import-Csv $csvTemp; 
                        Remove-Item $csvTemp -Confirm:$false -Verbose:$VerbosePreference; 
                    } 
                } 
            } 
        } 
    } 
    
    End 
    { 
        $xl.Quit(); 
        Remove-Variable -name xl -Confirm:$false; 
        [gc]::Collect(); 
    } 
} 

function CleanWsusCacheRemote {
 Param( 
        [parameter( 
            mandatory=$true,  
            position=1,  
            ValueFromPipeline=$true,  
            ValueFromPipelineByPropertyName=$true)] 
        [String[]] 
        $RemoteComputerName
    ) 

Invoke-Command -ComputerName $RemoteComputerName -ScriptBlock {
stop-service ddgmonAgent -force
stop-service wuauserv -force
stop-service bits -force
sleep 15
stop-service ddgmonAgent -force
stop-service wuauserv -force
stop-service bits -force
sleep 5

Remove-Item -Path c:\windows\SoftwareDistribution -Recurse -Force
Remove-Item -Path c:\windows\WindowsUpdate.log -Force

start-service bits
start-service wuauserv
start-service ddgmonAgent

sleep 5

klist -lh 0 -li 0x3e7 purge
wuauclt.exe /resetauthorization /detectnow
wuauclt.exe /detectnow
wuauclt.exe /reportnow

Restart-Computer -force
}




}


function verificavisualeelencovm {
 Param(
        [Parameter( 
            mandatory=$true,  
            position=1,  
            ValueFromPipeline=$true,  
            ValueFromPipelineByPropertyName=$true)]
            [array]$elencovmbyxls,

            [parameter( 
            mandatory=$true,  
            position=2,  
            ValueFromPipeline=$true,  
            ValueFromPipelineByPropertyName=$true)] 
        [String[]] 
        $nomegruppoupdate  
       )


cls
Write-Host ""
Write-Host "verificare che le seguenti VM debbano realmente essere inserite nel gruppo " 
write-host "$nomegruppoupdate" -ForegroundColor Red
Write-Host "se vi sono incongruenze chiudere la finestra dello script"
Write-Host ""
Write-Host "premere RETURN / INVIO per continuare"
Write-Host ""
$elencovmbyxls | sort-object "DNS Name"  | ft "DNS Name",ddgUpdate,ddgUpdateWindow
pause

}

Function AggiungePcAlGruppoAD {Param(
        [Parameter( 
            mandatory=$true,  
            position=1 
            #ValueFromPipeline=$true,  
            #ValueFromPipelineByPropertyName=$true
            )]
            [array]$ElencoVmDaAggiungereAlGruppo,

            [parameter( 
            mandatory=$true,  
            position=2 
            #ValueFromPipeline=$true,  
            #ValueFromPipelineByPropertyName=$true
            )] 
        [String[]] 
        $GruppoDaPopolare
       )

#example: AggiungePcAlGruppoAD -ElencoVmDaAggiungereAlGruppo $ElencoVm -GruppoDaPololare $nomegruppo

#verifico che sia stato caricato elenco pc da AD
if ($elencodituttiicomputer -eq $null) {
Write-Host "elenco vuoto"
return
}

#pulisco il gruppo AD
Get-ADGroupMember $GruppoDaPopolare | ForEach-Object {Remove-ADGroupMember -Identity (Get-ADGroup $GruppoDaPopolare) -Members $_ -Confirm:$False -WhatIf:$dryrun}


ForEach ($vm in $ElencoVmDaAggiungereAlGruppo) {
$VMdaAggiungere += $elencodituttiicomputer | Where-Object {$_.DNSHostName -eq $VM."DNS Name" }
# ok funziona!  $pcdaaggiungeralgruppo += Get-ADComputer -Filter * | Where-Object {$_.DNSHostName -eq $computervmdaelenco."DNS Name" }
}
cls
write-host "i seguenti pc verranno aggiunti al gruppo gruppoADAutoUpdateGruppoA - " $GruppoDaPopolare
$pcdaaggiungeralgruppoautoA.SamAccountName 
sleep 2
# write-host "report gruppo Pilot - " $GruppoDaPololare
add-ADGroupMember $GruppoDaPopolare $VMdaAggiungere -WhatIf:$dryrun
sleep 10
Get-ADGroupMember $GruppoDaPopolare | ft
pause




}


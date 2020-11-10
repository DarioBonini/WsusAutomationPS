echo originale da sito MS
echo sqlcmd -S np:\\.\pipe\MSSQL$MICROSOFT##SSEE\sql\query –i <scriptLocation>\WsusDBMaintenance.sql
echo modifca trovata in rete
echo "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\sqlcmd" -I -S \.\pipe\MICROSOFT##WID\tsql\query -i C:\Scripts\WSUSDBMaintenance.sql

echo non funziona - sqlcmd -I -S \.\pipe\MICROSOFT##WID\tsql\query -i "C:\_\ddgsms4update\ServerUtil\101-ReindexDB.sql"
sqlcmd -I -S \\.\pipe\MICROSOFT##WID\tsql\query -i "C:\_\ddgsms4update\ServerUtil\101-ReindexDB.sql"

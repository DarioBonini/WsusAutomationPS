echo sqlcmd -S np:\\.\pipe\MSSQL$MICROSOFT##SSEE\sql\query –i <scriptLocation>\WsusDBMaintenance.sql

sqlcmd -S np:\\.\pipe\MSSQL$MICROSOFT##SSEE\sql\query –i "C:\_\ddgsms4update\ServerUtil\101-ReindexDB.sql"
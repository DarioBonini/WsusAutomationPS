klist -lh 0 -li 0x3e7 purge

net stop ddgmonAgent
net stop wuauserv
net stop bits

net start bits
net start wuauserv
net start ddgmonAgent

wuauclt.exe /resetauthorization /detectnow
wuauclt /detectnow
wuauclt /reportnow
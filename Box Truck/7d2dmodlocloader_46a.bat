@echo off

rem Name of the script
set scriptname=7 Days to Die Mod Localization loader
rem Version of the script
set scriptver=v4.6a

title %scriptname% %scriptver%

call :Header
echo.
echo Press any key if you want to continue.
echo Otherwise you may close this window now and no changes will me made.
pause>nul
call :Process
goto :EOP

:Process
cls

setlocal enabledelayedexpansion

rem Set some internal variables:
rem Path to Vanilla Configuration directory
set "vanillacfgpath=%~dp0Data\Config"
set "vanillacfgpath=!vanillacfgpath:\Mods=!"
rem Localization file names
set "loc=Localization.txt"
set "locq=Localization - Quest.txt"
rem Backup exists variable
set /a backupexists=1

rem Backup original Localizations
rem If a previous backup is present, we notify the user and let them decide what to do next
if /I NOT exist "!vanillacfgpath!\!loc!.bak" if /I NOT exist "!vanillacfgpath!\!locq!.bak" set /a backupexists=0
if !backupexists! EQU 1 goto :BackupExists else goto :BackupNow

:BackupNow
cls
echo Creating backups of the original files:
echo.
echo Creating a backup file: !vanillacfgpath!\!loc!.bak
type "!vanillacfgpath!\!loc!" >"!vanillacfgpath!\!loc!.bak"
echo Creating a backup file: !vanillacfgpath!\!locq!.bak
type "!vanillacfgpath!\!locq!" >"!vanillacfgpath!\!locq!.bak"
echo Backups created successfully.
echo.
echo Press any key to continue...
pause>nul
goto :LoadLocalizations

:BackupExists
echo It seems that we already have some backup files.
echo Please note that if you proceed, your backup files will be overwritten.
echo.
echo Press any key if you want to continue.
echo Otherwise you may close this window now and no changes will me made.
pause>nul
goto :BackupNow

:LoadLocalizations
rem Let's make a quick run through all the files that we need to process to give the user
rem an idea about the progress in percentage...
set /a filecount=0
for /R %%f in (*.txt) do (
	set countthis=yes
	if /I NOT "%%~nxf"=="!loc!" if /I NOT "%%~nxf"=="!locq!" set countthis=no
	if !countthis!==yes (
		set /a filecount+=1
	)
)
rem Let's split the progress into individual files that must be processed
rem and define it by percentage, starting at 0%
set /a progress=0
set /a percentincrement=100/%filecount%

call :Progress

rem Append Localizations from all mods into the Vanilla Localizations
for /R %%f in (*.txt) do (
	rem Let's sort the files and pick the ones we want to work with
	set usethis=yes
	if /I NOT "%%~nxf"=="!loc!" if /I NOT "%%~nxf"=="!locq!" set usethis=no
	if !usethis!==yes (
		rem Save Localization file name into a variable !thisloc!
		set "thisloc=%%~nf"
		rem Save the current working path into a variable !thisdir!	
		set "thisdir=%%~dpf"
		set "thisdir=!thisdir:~0,-1!"
		rem Create a temporary localization file from the original, but exclude the header if there is one...
		findstr /I /V "Key,Source,Context,Changes*" "!thisdir!\!thisloc!.txt" >"!thisdir!\!thisloc!_temp.txt"
		rem ...and use valid lines only
		type "!thisdir!\!thisloc!_temp.txt" >"!thisdir!\!thisloc!_temp.txt.old" & del "!thisdir!\!thisloc!_temp.txt"
		findstr /I /R "^.*," "!thisdir!\!thisloc!_temp.txt.old" >"!thisdir!\!thisloc!_temp.txt"
		del "!thisdir!\!thisloc!_temp.txt.old"
		rem Process the temporary localization file line by line
		for /F "usebackq tokens=*" %%l in ("!thisdir!\!thisloc!_temp.txt") do (
			rem Save the line key into a variable !lkey!
			set "lkey="
			for /F "tokens=1 delims=," %%k in ("%%l") do set "lkey=%%k"
			rem If !lkey! exists in vanilla localization, save the line into a variable for replacement
			rem for /F "usebackq tokens=* delims=," %%r in ('findstr /I "!lkey!" "!vanillacfgpath!\!thisloc!.txt"') do set "linetoreplace=%%r"
			set "linetoreplace="
			for /F "tokens=*" %%r in ('findstr /I /B "!lkey!" "!vanillacfgpath!\!thisloc!.txt"') do set "linetoreplace=%%r"
			rem Does the line with the same key exist in vanilla localization? It must be removed, before adding a new one to avoid duplicates
			if NOT "!linetoreplace!"=="" (
				rem We found the line with this key in vanilla localization, let's remove it
				type "!vanillacfgpath!\!thisloc!.txt" >"!vanillacfgpath!\!thisloc!_edit.txt" & del "!vanillacfgpath!\!thisloc!.txt"
				findstr /I /V /B /C:"!lkey!" "!vanillacfgpath!\!thisloc!_edit.txt" > "!vanillacfgpath!\!thisloc!.txt"
				rem find /v "!lkey!" "!vanillacfgpath!\!thisloc!_edit.txt" > "!vanillacfgpath!\!thisloc!.txt"
				del "!vanillacfgpath!\!thisloc!_edit.txt"
			)
		)
	rem Append and clean up...
	echo( >> "!vanillacfgpath!\!thisloc!.txt"
	type "!thisdir!\!thisloc!_temp.txt" >> "!vanillacfgpath!\!thisloc!.txt"
	del "!thisdir!\!thisloc!_temp.txt"
	rem Update progress status
	set /a progress+=percentincrement & call :Progress
	)
)
rem Final clean up - fix garbage and empty lines
type "!vanillacfgpath!\!loc!" >"!vanillacfgpath!\!loc!.old" & del "!vanillacfgpath!\!loc!"
findstr /I /R "^.*," "!vanillacfgpath!\!loc!.old" >"!vanillacfgpath!\!loc!"
del "!vanillacfgpath!\!loc!.old"
type "!vanillacfgpath!\!locq!" >"!vanillacfgpath!\!locq!.old" & del "!vanillacfgpath!\!locq!"
findstr /I /R "^.*," "!vanillacfgpath!\!locq!.old" >"!vanillacfgpath!\!locq!"
del "!vanillacfgpath!\!locq!.old"
rem Update progress status with 100% since we are done at this point
set /a progress=100 & call :Progress
endlocal
exit /b

:Header
echo %scriptname% %scriptver%
echo Coded by mr.devolver
echo.
echo Description:
echo This script is supposed to go through all of your 7 Days to Die mods
echo and automatically load their localization.txt and localization - quest.txt
echo files into the original game localization files.
echo.
echo Before making any changes, this script creates a backup of your original
echo game localization files.
echo.
echo Warning:
echo It does NOT keep track of your changes, so if you want to keep your
echo current backup, you should save it to a special directory somewhere
echo outside of its original location.
echo.
echo Please note that this script must run from your Mods directory.
echo If you're running it from a different location, it will not work.
echo.
echo !!!! USE AT YOUR OWN RISK !!!!
echo This script is provided AS IS. At this point it's a highly experimental
echo alpha version and may damage your game files.
echo.
echo Feel free to improve it and share your improved version with other users!
echo.
echo Thanks! 
exit /b

:Progress
cls
echo Loading localizations, please wait...
echo Progress: !progress!%%
exit /b

:EOP
echo.
echo Finished! Let's hope this works! Good luck, survivor!
echo.
echo Press any key to exit...
pause>nul
exit
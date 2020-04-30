@echo off
title Polo Process #1
color 0A

:: http://patorjk.com/software/taag/#p=display&f=Doom (Doom)
echo.
echo " ______     _        ______                                _  _    __   "
echo " | ___ \   | |       | ___ \                             _| || |_ /  |  "
echo " | |_/ /__ | | ___   | |_/ / __ ___   ___ ___  ___ ___  |_  __  _|`| |  "
echo " |  __/ _ \| |/ _ \  |  __/ '__/ _ \ / __/ _ \/ __/ __|  _| || |_  | |  "
echo " | | | (_) | | (_) | | |  | | | (_) | (_|  __/\__ \__ \ |_  __  _|_| |_ "
echo " \_|  \___/|_|\___/  \_|  |_|  \___/ \___\___||___/___/   |_||_|  \___/ "
echo.

:: Set variables
set DIR=%CD%
set displayMainInformation=false
set displayAllMetadata=false
set displayMetadata=false
set displayFinalData=false
set totalNumberOfSteps=9
set moveImage=true
set copyImage=false

:: Main information
if %displayMainInformation%==true (
	echo Main information
	echo ==========================================
	echo Computer :		%COMPUTERNAME%
	echo OS :			%OS%
	echo Processor :		%PROCESSOR_IDENTIFIER%
	echo User :			%USERNAME%
	echo Date :			%DATE% - %TIME%
	echo Current directory :	%CD%
	echo ==========================================
	echo.
)

echo --- INSTALLATION ---
echo Download exiftool zip, 'Windows Executable', from https://exiftool.org/index.html
echo Unzip it to C:\Windows
echo Rename "exiftool(-k).exe" -^> "exiftool.exe"
echo.

echo --- DISCLAMER ---
echo Le but de ce script est
echo - de recuperer les bonnes metadata de vos photos/videos
echo - de renommer les photos/videos avec la date + le nom du dossier qui les contient
echo - de couper ou coller TOUTES les photos/videos à la racine
echo.
echo Le fichier .bat doit se situer à la racine de votre dossier.
echo.
echo 1 = Continuer
echo 2 = Quitter
set /p question=Etes-vous sur(e) de vouloir lancer ce script ? 
if %question% neq 1 ( exit )
echo.

:: Main function
echo Starting Polo Process #1...
echo Processing folder : %DIR%

cd %DIR%

if %displayAllMetadata%==true (
	echo.
	echo #### Display all metadata
	exiftool -r -a -G1 -s "%DIR%"
)

if %displayMetadata%==true (
	echo.
	echo #### Display metadata
	exiftool -r  -Directory -DateTimeCreated -DateCreated -TimeCreated -DateTimeOriginal -FileCreateDate -FileModifyDate -CreateDate -ModifyDate -GPSDateTime "%DIR%"
)

:: %%f	- original file name (without the extension)
:: %%e	- original file extension (not including the ".")
:: -m          (-ignoreMinorErrors) Ignore minor errors and warnings
:: -r[.]       (-recurse)           Recursively process subdirectories
:: to use caret (^) : double it https://stackoverflow.com/questions/20342828/what-does-symbol-mean-in-batch-script + https://stackoverflow.com/questions/6828751/batch-character-escaping

echo.
echo #### Step 1/%totalNumberOfSteps% - Metadata Process (DateTimeOriginal)
exiftool -m -r -if "(defined $DateTimeOriginal) && ($DateTimeOriginal ne '0000:00:00 00:00:00')"^
				"-GPSDateTime<DateTimeOriginal"^
				"-FileCreateDate<DateTimeOriginal"^
				"-FileModifyDate<DateTimeOriginal"^
				"-CreateDate<DateTimeOriginal"^
				"-ModifyDate<DateTimeOriginal"^
				"-Description<${directory;s(.*/)()}"^
				"-ImageDescription<${directory;s(.*/)()}"^
				"%DIR%"
echo.
echo #### Step 2/%totalNumberOfSteps% - Metadata Process (CreationDate)
exiftool -m -r -if "(defined $CreationDate) && (not defined $DateTimeOriginal or $DateTimeOriginal =~ /(^^\s*$)/)"^
				"-GPSDateTime<CreationDate"^
				"-FileCreateDate<CreationDate)"^
				"-FileModifyDate<CreationDate"^
				"-DateTimeOriginal<CreationDate"^
				"-ModifyDate<CreationDate"^
				"-Description<${directory;s(.*/)()}"^
				"-ImageDescription<${directory;s(.*/)()}"^
				"%DIR%"
echo.
echo #### Step 3/%totalNumberOfSteps% - Metadata Process (CreateDate)
exiftool -m -r -if "(defined $CreateDate) && (not defined $DateTimeOriginal or $DateTimeOriginal =~ /(^^\s*$)/)"^
				"-GPSDateTime<CreateDate"^
				"-FileCreateDate<CreateDate)"^
				"-FileModifyDate<CreateDate"^
				"-DateTimeOriginal<CreateDate"^
				"-ModifyDate<CreateDate"^
				"-Description<${directory;s(.*/)()}"^
				"-ImageDescription<${directory;s(.*/)()}"^
				"%DIR%"
echo.
echo #### Step 4/%totalNumberOfSteps% - Metadata Process (FileModifyDate)
exiftool -m -r -if "(defined $FileModifyDate) && (not defined $CreateDate) && ((not defined $DateTimeOriginal) or ($DateTimeOriginal =~ /(^^\s*$)/)) or ($DateTimeOriginal eq '0000:00:00 00:00:00')"^
				"-GPSDateTime<FileModifyDate"^
				"-FileCreateDate<FileModifyDate"^
				"-CreateDate<FileModifyDate"^
				"-DateTimeOriginal<FileModifyDate"^
				"-ModifyDate<FileModifyDate"^
				"-Description<${directory;s(.*/)()}"^
				"-ImageDescription<${directory;s(.*/)()}"^
				"%DIR%"

:: https://exiftool.org/forum/index.php?topic=8144.0
echo.
echo #### Step 5/%totalNumberOfSteps% - Rename files by date/time (yyyymmdd-##.jpg), ordered by DateTimeOriginal field
:: -d "%%Y/%%Y-%%m-%%d %%H-%%M-%%S"
:: Create a parent folder with Year
exiftool -m -r -d "%%Y-%%m-%%d %%H-%%M-%%S"^
				"-filename < ${DateTimeOriginal} - ${directory;s(.*/)()} $filesequence.%%e"^
				"%DIR%"

echo.
echo #### Step 6/%totalNumberOfSteps% - Removing original
for /r %%x in (*_original) do (
    set di=%%x
::    echo deleting '%%x'...
    del "%%x"
)

echo.
echo #### Step 7/%totalNumberOfSteps% - Removing Thumbs.db
for /r %%x in (*Thumbs.db) do (
    set di=%%x
::    echo deleting '%%x'...
    del "%%x"
)

:: Remove move / copy notifications https://stackoverflow.com/questions/14686330/how-do-i-make-a-windows-batch-script-completely-silent
echo.
if %moveImage%==true (
	echo #### Step 8/%totalNumberOfSteps% - Move all files from subfolders to parent folder
	for /r %%x in (*.*) do (
		move "%%x" "%DIR%" >NUL
	)
)
if %copyImage%==true (
	echo #### Step 8/%totalNumberOfSteps% - Copy all files from subfolders to parent folder
	for /r %%x in (*.*) do (
		copy /Y "%%x" "%DIR%" >NUL
	)
)

:: https://www.winhelponline.com/blog/find-and-delete-empty-folders-windows/
echo.
echo #### Step 9/%totalNumberOfSteps% - Recursively deleting empty directories
for /f "delims=" %%i in ('dir /s /b /ad ^| sort /r') do (
	rd "%%i" 2>NUL
)

if %displayFinalData%==true (
	echo.
	echo #### Print final data
	exiftool -r -DateTimeCreated -DateCreated -TimeCreated -DateTimeOriginal -FileCreateDate -FileModifyDate -CreateDate -ModifyDate -GPSDateTime -Description -ImageDescription "%DIR%"
)

echo.
echo " ______ _       _     _              _   _  "
echo " |  ___(_)     (_)   | |            | | | | "
echo " | |_   _ _ __  _ ___| |__   ___  __| | | | "
echo " |  _| | | '_ \| / __| '_ \ / _ \/ _` | | | "
echo " | |   | | | | | \__ \ | | |  __/ (_| | |_| "
echo " \_|   |_|_| |_|_|___/_| |_|\___|\__,_| (_) "
echo.

pause > nul
@echo off
title Polo Process #1
color 0A

:: http://patorjk.com/software/taag/ (Doom)
echo.
echo " ______     _        ______                                _  _    __   "
echo " | ___ \   | |       | ___ \                             _| || |_ /  |  "
echo " | |_/ /__ | | ___   | |_/ / __ ___   ___ ___  ___ ___  |_  __  _|`| |  "
echo " |  __/ _ \| |/ _ \  |  __/ '__/ _ \ / __/ _ \/ __/ __|  _| || |_  | |  "
echo " | | | (_) | | (_) | | |  | | | (_) | (_|  __/\__ \__ \ |_  __  _|_| |_ "
echo " \_|  \___/|_|\___/  \_|  |_|  \___/ \___\___||___/___/   |_||_|  \___/ "
echo.

:: Main information
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

:: Set variables
set DIR=%CD%
set displayAllMetadata=false
set displayMetadata=false
set displayFinalData=false
set totalNumberOfSteps=10

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
echo #### Step 1/%totalNumberOfSteps% - Add Metadata "Description" to all images/videos on folders/subfolders (Description = folder name)
exiftool -m -r "-Description<${directory;s(.*/)()}"^
				"-ImageDescription<${directory;s(.*/)()}"^
				"%DIR%"

:: Remove move / copy notifications https://stackoverflow.com/questions/14686330/how-do-i-make-a-windows-batch-script-completely-silent
echo.
echo #### Step 2/%totalNumberOfSteps% - Move or Copy all files from subfolders to parent folder
for /r %%x in (*.*) do (
::	move /Y "%%x" "%DIR%"
	copy /Y "%%x" "%DIR%" >NUL
)

echo.
echo #### Step 3/%totalNumberOfSteps% - Metadata Process (DateTimeOriginal)
exiftool -m -if "(defined $DateTimeOriginal) && ($DateTimeOriginal ne '0000:00:00 00:00:00')"^
				"-GPSDateTime<DateTimeOriginal"^
				"-FileCreateDate<DateTimeOriginal"^
				"-FileModifyDate<DateTimeOriginal"^
				"-CreateDate<DateTimeOriginal"^
				"-ModifyDate<DateTimeOriginal"^
				"%DIR%"
echo.
echo #### Step 4/%totalNumberOfSteps% - Metadata Process (CreationDate)
exiftool -m -if "(defined $CreationDate) && (not defined $DateTimeOriginal or $DateTimeOriginal =~ /(^^\s*$)/)"^
				"-GPSDateTime<CreationDate"^
				"-FileCreateDate<CreationDate)"^
				"-FileModifyDate<CreationDate"^
				"-DateTimeOriginal<CreationDate"^
				"-ModifyDate<CreationDate"^
				"%DIR%"
echo.
echo #### Step 5/%totalNumberOfSteps% - Metadata Process (CreateDate)
exiftool -m -if "(defined $CreateDate) && (not defined $DateTimeOriginal or $DateTimeOriginal =~ /(^^\s*$)/)"^
				"-GPSDateTime<CreateDate"^
				"-FileCreateDate<CreateDate)"^
				"-FileModifyDate<CreateDate"^
				"-DateTimeOriginal<CreateDate"^
				"-ModifyDate<CreateDate"^
				"%DIR%"
echo.
echo #### Step 6/%totalNumberOfSteps% - Metadata Process (FileModifyDate)
exiftool -m -if "(defined $FileModifyDate) && (not defined $CreateDate) && ((not defined $DateTimeOriginal) or ($DateTimeOriginal =~ /(^^\s*$)/)) or ($DateTimeOriginal eq '0000:00:00 00:00:00')"^
				"-GPSDateTime<FileModifyDate"^
				"-FileCreateDate<FileModifyDate"^
				"-CreateDate<FileModifyDate"^
				"-DateTimeOriginal<FileModifyDate"^
				"-ModifyDate<FileModifyDate"^
				"%DIR%"

:: https://exiftool.org/forum/index.php?topic=8144.0
echo.
echo #### Step 7/%totalNumberOfSteps% - Rename files by date/time and Description (yyyymmdd - Description.jpg), ordered by DateTimeOriginal field
:: -d "%%Y/%%Y-%%m-%%d %%H-%%M-%%S"
:: Create a parent folder with Year
exiftool -m -d "%%Y-%%m-%%d %%H-%%M-%%S"^
				"-filename < ${DateTimeOriginal} - ${Description} $filesequence.%%e"^
				"%DIR%"

echo.
echo #### Step 8/%totalNumberOfSteps% - Removing original
for /r %%x in (*_original) do (
    set di=%%x
::    echo deleting '%%x'...
    del "%%x"
)

echo.
echo #### Step 9/%totalNumberOfSteps% - Removing Thumbs.db
for /r %%x in (*Thumbs.db) do (
    set di=%%x
::    echo deleting '%%x'...
    del "%%x"
)

:: https://www.winhelponline.com/blog/find-and-delete-empty-folders-windows/
echo.
echo #### Step 10/%totalNumberOfSteps% - Recursively deleting empty directories
for /f "delims=" %%i in ('dir /s /b /ad ^| sort /r') do (
	rd "%%i" 2>NUL
)

if %displayFinalData%==true (
	echo.
	echo #### Print final data
	exiftool -DateTimeCreated -DateCreated -TimeCreated -DateTimeOriginal -FileCreateDate -FileModifyDate -CreateDate -ModifyDate -GPSDateTime -Description -ImageDescription "%DIR%"
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
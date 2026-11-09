@echo off
rem Desfaz as configuracoes alteradas no tablet Hyundai Maestro HDT-7427GH (Android 7.0).
rem Usa o adb ao lado do script (pasta platform-tools) ou o que estiver no PATH.
set ADB=adb
if exist "%~dp0platform-tools\adb.exe" set ADB="%~dp0platform-tools\adb.exe"

%ADB% shell settings put global wifi_scan_always_enabled 1
%ADB% shell settings put global ble_scan_always_enabled 1
%ADB% shell settings put global window_animation_scale 1.0
%ADB% shell settings put global transition_animation_scale 1.0
%ADB% shell settings put global animator_duration_scale 1.0
%ADB% shell settings put secure location_providers_allowed +gps

echo.
echo Configuracoes restauradas.
echo.
echo ATENCAO: os 18 pacotes removidos (lista em removidos-HDT-7427GH.txt) NAO voltam por ADB
echo neste Android 7.0: "pm install-existing" nao existe nesta versao e os APKs de sistema
echo estao em formato odex, entao "pm install -r" falha com "code is missing".
echo Para trazer todos de volta: Configuracoes ^> Backup e redefinicao ^>
echo Redefinir para configuracao original (apaga os dados do tablet).
pause

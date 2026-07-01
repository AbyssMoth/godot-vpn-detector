@echo off
REM Сборка vpn-detector-release.aar на Windows.
REM Требует: Android SDK (ANDROID_HOME), JDK 17-22 (JAVA_HOME), gradle в PATH.
setlocal
cd /d "%~dp0"

if not exist "android_plugin\core\vpndetectorcore\build.gradle" (
    echo Initializing core submodule...
    git submodule update --init --recursive
)

cd android_plugin
call gradle clean :plugin:assembleRelease --no-daemon
if errorlevel 1 (
    echo Build failed.
    exit /b 1
)

if not exist "..\bin" mkdir "..\bin"
copy /y "plugin\build\outputs\aar\plugin-release.aar" "..\bin\vpn-detector-release.aar"
echo Done: bin\vpn-detector-release.aar
endlocal

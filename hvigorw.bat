@echo off
REM HarmonyOS Hvigor Wrapper Script for Windows

setlocal

set DEFAULT_HVIGOR_VERSION=4.0.0
if "%HVIGOR_VERSION%"=="" set HVIGOR_VERSION=%DEFAULT_HVIGOR_VERSION%

set HVIGOR_APP_HOME=%~dp0
set HVIGOR_WRAPPER_DIR=%HVIGOR_APP_HOME%hvigor
set HVIGOR_WRAPPER_JAR=%HVIGOR_WRAPPER_DIR%\hvigor-wrapper.jar

if not exist "%HVIGOR_WRAPPER_JAR%" (
    echo Hvigor wrapper JAR not found. Please run: npm install
    exit /b 1
)

node "%HVIGOR_WRAPPER_DIR%\hvigor-wrapper.js" %*

endlocal

@echo off
rem ============================================================
rem caplib DolphinDB Docker Build - Windows entry point.
rem Delegates to build.ps1 (self-contained, same as build.sh).
rem
rem Usage:
rem   docker\build.bat             build only
rem ============================================================
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*
exit /b %errorlevel%

@echo off
cd %~dp0

rem https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands

if exist "submacros\bloxburg_macro.ahk" (
    if exist "submacros\AutoHotkey64.exe" (
        start "" "%~dp0submacros\AutoHotkey64.exe" "%~dp0submacros\bloxburg_macro.ahk"
        exit
    )
)

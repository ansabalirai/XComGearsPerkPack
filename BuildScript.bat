@echo off
SET "SDKLocation=G:\SteamLibrary\steamapps\common\XCOM 2 War of the Chosen SDK"
SET "GameLocation=G:\SteamLibrary\steamapps\common\XCOM 2\XCom2-WarOfTheChosen"
SET "SRCLocation=D:\Github\XComGearsPerkPack"

powershell.exe -NonInteractive -ExecutionPolicy Unrestricted  -file "D:\Github\XComGearsPerkPack\.scripts\build.ps1" -srcDirectory "%SRCLocation%" -sdkPath "%SDKLocation%" -gamePath "%GameLocation%" -config "debug"

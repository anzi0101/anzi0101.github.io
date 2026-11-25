@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
title 安全清理 - 只清缓存，不动你的文件

echo ================================================
echo   安全清理脚本
echo   只清理临时文件和缓存；不删个人文档、照片、
echo   下载文件；不自动清空回收站。
echo ================================================
echo.

rem ===== 变量校验：TEMP 必须存在且指向用户临时目录 =====
if not defined TEMP goto :unsafe
set "T=%TEMP%"
if not defined T goto :unsafe
if "%T%"=="\" goto :unsafe
if "%T:~1,2%"==":\" goto :unsafe
echo %T% | findstr /i /c:"\AppData\Local\Temp" >nul
if errorlevel 1 goto :unsafe

for /f %%a in ('powershell -NoProfile -Command "[math]::Round((Get-PSDrive C).Free/1GB,2)"') do set BEFORE=%%a
echo   清理前 C 盘可用: %BEFORE% GB
echo.

echo [1/4] 用户临时目录: %T%
del /f /s /q "%T%\*.*" >nul 2>&1
for /d %%d in ("%T%\*") do call :SAFE_RM "%%~fd"
echo        完成
echo.

echo [2/4] 缩略图与图标缓存
if defined LOCALAPPDATA (
  set "TH=%LOCALAPPDATA%\Microsoft\Windows\Explorer"
  if exist "!TH!" (
    for %%f in ("!TH!\thumbcache_*.db") do call :SAFE_DEL "%%~f"
    for %%f in ("!TH!\iconcache_*.db") do call :SAFE_DEL "%%~f"
  )
)
echo        完成
echo.

echo [3/4] 浏览器网页缓存（不影响登录状态和书签）
if defined LOCALAPPDATA (
  set "EU=%LOCALAPPDATA%\Microsoft\Edge\User Data"
  if exist "!EU!" (
    for /d %%p in ("!EU!\*") do (
      call :SAFE_RM "%%~p\Cache"
      call :SAFE_RM "%%~p\Code Cache"
      call :SAFE_RM "%%~p\GPUCache"
    )
  )
  set "CU=%LOCALAPPDATA%\Google\Chrome\User Data"
  if exist "!CU!" (
    for /d %%p in ("!CU!\*") do (
      call :SAFE_RM "%%~p\Cache"
      call :SAFE_RM "%%~p\Code Cache"
      call :SAFE_RM "%%~p\GPUCache"
    )
  )
)
echo        完成（若浏览器正在运行，部分缓存会被占用而跳过）
echo.

echo [4/4] npm 缓存
if defined LOCALAPPDATA if exist "%LOCALAPPDATA%\npm-cache" call :SAFE_RM "%LOCALAPPDATA%\npm-cache"
echo        完成
echo.

echo   回收站体积（本脚本不自动清空）:
powershell -NoProfile -Command "$p='C:\$Recycle.Bin'; $s=(Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum; '        当前占用 ' + [math]::Round($s/1GB,2) + ' GB，确认无需恢复后可右键回收站图标清空'"
echo.

for /f %%a in ('powershell -NoProfile -Command "[math]::Round((Get-PSDrive C).Free/1GB,2)"') do set AFTER=%%a
echo ================================================
echo   清理后 C 盘可用: %AFTER% GB  （清理前 %BEFORE% GB）
echo ================================================
echo.
pause
goto :eof

:unsafe
echo.
echo [已中止] 临时目录变量异常（为空或不是用户临时目录），
echo           为避免误删，脚本不执行任何删除操作。
echo   当前 TEMP = %TEMP%
echo.
pause
goto :eof

:SAFE_RM
set "P=%~1"
if not defined P exit /b 0
if "%P%"=="\" exit /b 0
if "%P:~1,2%"==":\" exit /b 0
if "%P:~1,2%"=="/" exit /b 0
if not exist "%P%" exit /b 0
set "PC=%P%"
if "!PC:~-1!"=="\" set "PC=!PC:~0,-1!"
if "!PC!"=="\" exit /b 0
if "!PC:~1,2!"==":\" exit /b 0
rd /s /q "!PC!" >nul 2>&1
exit /b 0

:SAFE_DEL
set "F=%~1"
if not defined F exit /b 0
if not exist "%F%" exit /b 0
del /f /q "%F%" >nul 2>&1
exit /b 0

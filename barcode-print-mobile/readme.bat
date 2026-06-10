@echo off
chcp 65001 >nul
title 条码打印系统 - 移动端项目速览
color 0b

echo ============================================
echo   条码打印系统 - Flutter 移动端
echo ============================================
echo.
echo  项目路径: %~dp0
echo  源码行数:
echo.

setlocal enabledelayedexpansion
set total=0
for /r "%~dp0lib" %%F in (*.dart) do (
    for /f %%C in ('type "%%F" ^| find /c /v ""') do set /a total+=%%C
)
for /r "%~dp0lib" %%F in (*.dart) do (
    for /f "tokens=*" %%G in ("%%~nxG") do (
        for /f %%C in ('type "%%F" ^| find /c /v ""') do (
            echo   %%G  (%%C 行)
        )
    )
)
echo.
echo  合计: %total% 行
echo.
echo ============================================
echo  快速操作指南
echo ============================================
echo.
echo  搭建环境:  双击 setup.bat
echo  安装依赖:  flutter pub get
echo  构建 APK:   flutter build apk
echo  安装到手机: flutter install
echo  运行调试:  flutter run
echo.
pause

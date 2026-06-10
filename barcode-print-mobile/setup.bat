@echo off
chcp 65001 >nul
title 条码打印系统 - Flutter 环境搭建
color 0b

echo ============================================
echo   条码打印系统 - Flutter 移动端环境搭建
echo ============================================
echo.

:: 检查是否已有 Flutter
where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] 检测到 Flutter 已安装，跳过安装步骤
    echo.
    call :do_pub_get
    goto :end
)

if exist "C:\flutter\bin\flutter.exe" (
    echo [OK] C:\flutter 已存在，跳过安装
    set "PATH=C:\flutter\bin;%PATH%"
    call :do_pub_get
    goto :end
)

:: ======== 选择下载方式 ========
echo 未检测到 Flutter SDK，请选择安装方式:
echo.
echo   [1] 自动下载 (清华镜像, 推荐)
echo   [2] 手动下载（告诉我链接，我自己下）
echo   [3] 我已经下载好了，告诉我放哪
echo.
set /p CHOICE="请输入编号 (1/2/3): "

if "%CHOICE%"=="1" goto :auto_download
if "%CHOICE%"=="2" goto :manual_download
if "%CHOICE%"=="3" goto :manual_install
goto :eof

:auto_download
echo.
echo 正在从清华镜像下载 Flutter SDK (约 1GB)...
echo 下载中请耐心等待，不要关闭窗口...
echo.

set "FLUTTER_ZIP=%TEMP%\flutter_windows.zip"
set "MIRROR=https://mirrors.tuna.tsinghua.edu.cn/flutter/flutter_infra_release/releases/stable/windows/flutter_windows_3.29.2-stable.zip"

:: 先用 curl (Windows 10 1803+ 自带) 下载
curl -L --connect-timeout 30 --retry 3 -o "%FLUTTER_ZIP%" "%MIRROR%"
if %ERRORLEVEL% NEQ 0 (
    echo curl 下载失败，尝试 PowerShell 下载...
    powershell -Command "
        $url = '%MIRROR%';
        $out = '%FLUTTER_ZIP%';
        Write-Host 'PowerShell 下载中...' -ForegroundColor Yellow;
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
        try {
            Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 7200;
            Write-Host '下载完成' -ForegroundColor Green;
        } catch {
            Write-Host '下载失败: ' + $_.Exception.Message -ForegroundColor Red;
            exit 1;
        }
    "
    if %ERRORLEVEL% NEQ 0 (
        goto :download_failed
    )
)

if not exist "%FLUTTER_ZIP%" goto :download_failed
echo 下载完成，大小: 
for %%F in ("%FLUTTER_ZIP%") do echo  %%~zF 字节
goto :extract

:download_failed
echo.
echo [错误] 自动下载失败，可能是网络问题。
echo.
echo 请打开下面链接手动下载:
echo  %MIRROR%
echo.
echo 下载后放到桌面，再运行本脚本选 [3]
pause
exit /b 1

:manual_download
echo.
echo 请用浏览器打开以下链接下载:
echo.
echo  https://mirrors.tuna.tsinghua.edu.cn/flutter/flutter_infra_release/
echo  releases/stable/windows/flutter_windows_3.29.2-stable.zip
echo.
echo 下载完成后放到桌面，再次运行脚本选 [3]
pause
exit /b 1

:manual_install
echo.
echo 请把 Flutter SDK 压缩包解压到 C:\flutter
echo 目录结构应该是: C:\flutter\bin\flutter.exe
echo.
echo 解压完成后按任意键继续...
pause >nul
if not exist "C:\flutter\bin\flutter.exe" (
    echo [错误] 未找到 C:\flutter\bin\flutter.exe
    echo 请确认解压路径正确
    pause
    exit /b 1
)
set "PATH=C:\flutter\bin;%PATH%"
goto :pub_get

:extract
echo.
echo 正在解压到 C:\flutter ...
powershell -Command "
    Write-Host '解压中...' -ForegroundColor Yellow;
    Expand-Archive -Path '%FLUTTER_ZIP%' -DestinationPath 'C:\' -Force;
    Write-Host '解压完成' -ForegroundColor Green;
"
del "%FLUTTER_ZIP%" 2>nul

if not exist "C:\flutter\bin\flutter.exe" (
    echo [错误] 解压失败
    pause
    exit /b 1
)

:: 设置环境变量
echo.
echo 配置环境变量...
set "PATH=C:\flutter\bin;%PATH%"
setx PATH "C:\flutter\bin;%PATH%" >nul 2>&1

:pub_get
echo.
echo 安装项目依赖...
cd /d "%~dp0"
call flutter pub get
if %ERRORLEVEL% EQU 0 (
    echo [OK] 依赖安装完成
) else (
    echo [警告] flutter pub get 失败，稍后手动运行
)

goto :end

:do_pub_get
echo.
echo 安装项目依赖...
cd /d "%~dp0"
call flutter pub get

:end
echo.
echo ============================================
echo  项目已就绪！
echo ============================================
echo.
echo 接下来:
echo.
echo  [1] 安装 Android Studio (必须，用来编译 APK)
echo      下载地址: https://developer.android.com/studio
echo       或国内: https://www.androiddevtools.cn/
echo.
echo  [2] 打开 Android Studio → SDK Manager
echo      安装 Android SDK 34 或 35
echo.
echo  [3] 环境验证
echo      运行: flutter doctor
echo      如果提示 Accept licenses:
echo      运行: flutter doctor --android-licenses
echo.
echo  [4] 构建安装包
echo      flutter build apk  → 生成 APK
echo      或
echo      flutter install    → 直接装到连接的手机上
echo.
echo  [5] APK 位置:
echo      build\app\outputs\flutter-apk\app-release.apk
echo.
echo  [问题排查]
echo  如果 flutter doctor 报错，把输出发给我
echo.
pause

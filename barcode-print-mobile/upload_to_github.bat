@echo off
chcp 65001 >nul
title 条码打印 移动端 - 一键上传 GitHub
color 0b
echo ============================================
echo   条码打印系统 - 移动端 APK 构建助手
echo ============================================
echo.
echo 本工具帮你把项目提交到 GitHub，然后自动编译 APK。
echo 整个过程只需要在浏览器里操作，不需要装任何软件。
echo.
echo ============================================
echo  第一步：注册 GitHub 账号（如果还没有）
echo ============================================
echo.
echo  打开下面链接，点 Sign up，填邮箱设密码就行：
echo.
echo  [36mhttps://github.com/signup[0m
echo.
echo  注册完会发验证邮件到你的邮箱，点链接验证即可。
echo.
pause
echo.
echo ============================================
echo  第二步：创建仓库 + 上传项目
echo ============================================
echo.
echo  打开下面链接：
echo.
echo  [36mhttps://github.com/new[0m
echo.
echo  在页面上：
echo    1. Repository name 填:  barcode-print
echo    2. Private / Public 选:  Public
echo    3. 其他不动，点底部  [32mCreate repository[0m
echo.
echo  创建成功后，你会看到一个上传页面。
echo    4. 拖拽上传：把下面的文件夹拖进去
echo.
echo  [33m  %~dp0[0m
echo.
echo    5. 等上传完成，点底部  [32mCommit changes[0m
echo.
pause
echo.
echo ============================================
echo  第三步：等待自动编译
echo ============================================
echo.
echo  上传完成后，GitHub 会自动开始编译。
echo  点页面顶部的 [36mActions[0m 标签页，可以看到进度。
echo.
echo  编译大约需要 5-10 分钟，完成后 Actions 页面会有
echo  一个绿色勾 ✓，点进去就能下载 APK。
echo.
echo  下载文件名为:  [32mapp-release.apk[0m
echo.
echo  把这个 APK 传到手机上就能安装使用了！
echo.
echo ============================================
echo  遇到问题？
echo ============================================
echo.
echo  如果上传过程遇到问题，把报错截图发给我。
echo  如果不想注册 GitHub，也可以把项目文件夹压缩后
echo  通过 QQ/微信发给我，我这边想办法处理。
echo.
pause

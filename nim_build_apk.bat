@echo off
rem 방과후 님게임 — 분할 APK 빌드 (예약 작업 NIM_V2_APK 가 실행). 로그: Desktop\nim_build_log.txt, 성공 표시 V2_APK_OK
set "LOG=%USERPROFILE%\Desktop\nim_build_log.txt"
set "JAVA_HOME=C:\Users\leeyuseok\jdk-17"
set "ANDROID_SDK_ROOT=C:\Users\leeyuseok\Android\Sdk"
set "PATH=C:\Users\leeyuseok\flutter\bin;%JAVA_HOME%\bin;%PATH%"
cd /d "C:\Users\leeyuseok\Desktop\dev-setup\MATH-GAME\math_game_flutter"
echo BUILD_START %DATE% %TIME% > "%LOG%"
call flutter build apk --release --split-per-abi >> "%LOG%" 2>&1
if errorlevel 1 (
  echo BUILD_FAILED >> "%LOG%"
  exit /b 1
)
echo V2_APK_OK >> "%LOG%"
exit /b 0

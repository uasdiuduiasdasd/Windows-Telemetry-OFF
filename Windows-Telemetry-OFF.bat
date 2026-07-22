@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Windows Telemetry OFF

:: --------------------------------------------------------------
::  Auto-elevation to Administrator
:: --------------------------------------------------------------
if /i "%~1"=="ELEV" goto :after_admin_check

fltmc >nul 2>&1
if not "%errorlevel%"=="0" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList 'ELEV' -Verb RunAs"
    exit /b
)

:after_admin_check
cd /d "%~dp0"

:: --------------------------------------------------------------
::  General Settings
:: --------------------------------------------------------------
set "APP_NAME=Windows Telemetry OFF"
set "LOGFILE=%~dp0Windows_Telemetry_OFF_Log.txt"
set "RESULTFILE=%~dp0Windows_Telemetry_OFF_Result.txt"

set "LANG=EN"
set "MODE_NAME="
set "MODE_ID="
set "WIN_EDITION="

set /a OK_COUNT=0
set /a INFO_COUNT=0
set /a WARN_COUNT=0
set /a ERR_COUNT=0

goto :lang_selection

:: ==============================================================
::  LANGUAGE SELECTION
:: ==============================================================

:lang_selection
cls
echo.
echo    ============================================================
echo    %APP_NAME%
echo    ============================================================
echo.
echo    Select Language / Выберите язык:
echo.
echo    [1] English (Default / По умолчанию)
echo    [2] Русский (Russian)
echo.
set "LANG_CHOICE=1"
set /p "LANG_CHOICE=   Choice / Выбор [1]: "
if "%LANG_CHOICE%"=="2" (
    set "LANG=RU"
) else (
    set "LANG=EN"
)
goto :main_menu

:: ==============================================================
::  BASIC FUNCTIONS
:: ==============================================================

:reset_counters
set /a OK_COUNT=0
set /a INFO_COUNT=0
set /a WARN_COUNT=0
set /a ERR_COUNT=0
exit /b

:header
cls
echo.
echo    ============================================================
echo    %APP_NAME%
echo    ============================================================
echo.
exit /b

:separator
echo.
echo    ------------------------------------------------------------
echo.
exit /b

:pause_here
echo.
if "!LANG!"=="RU" (
    echo    Нажмите любую клавишу, чтобы вернуться в главное меню...
) else (
    echo    Press any key to return to the main menu...
)
pause >nul
exit /b

:write_log_line
set "MSG=%~1"
>>"%LOGFILE%" echo !MSG!
exit /b

:write_log_blank
>>"%LOGFILE%" echo.
exit /b

:write_result_line
set "MSG=%~1"
>>"%RESULTFILE%" echo !MSG!
exit /b

:write_result_blank
>>"%RESULTFILE%" echo.
exit /b

:log_ok
set "MSG=%~1"
echo    [OK] !MSG!
call :write_log_line "[OK] !MSG!"
call :write_result_line "[OK] !MSG!"
set /a OK_COUNT+=1
exit /b

:log_info
set "MSG=%~1"
echo    [INFO] !MSG!
call :write_log_line "[INFO] !MSG!"
call :write_result_line "[INFO] !MSG!"
set /a INFO_COUNT+=1
exit /b

:log_warn
set "MSG=%~1"
echo    [WARN] !MSG!
call :write_log_line "[WARN] !MSG!"
call :write_result_line "[WARN] !MSG!"
set /a WARN_COUNT+=1
exit /b

:log_err
set "MSG=%~1"
echo    [ERR] !MSG!
call :write_log_line "[ERR] !MSG!"
call :write_result_line "[ERR] !MSG!"
set /a ERR_COUNT+=1
exit /b

:init_logs
(
    echo ============================================================
    echo %APP_NAME%
    if "!LANG!"=="RU" (
        echo Дата запуска: %date% %time%
        echo Режим: %MODE_NAME%
    ) else (
        echo Start date: %date% %time%
        echo Mode: %MODE_NAME%
    )
    echo ============================================================
    echo.
) > "%LOGFILE%"

(
    echo ============================================================
    echo %APP_NAME%
    if "!LANG!"=="RU" (
        echo Дата запуска: %date% %time%
        echo Режим: %MODE_NAME%
    ) else (
        echo Start date: %date% %time%
        echo Mode: %MODE_NAME%
    )
    echo ============================================================
    echo.
) > "%RESULTFILE%"
exit /b

:detect_windows_edition
set "WIN_EDITION="
for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID 2^>nul ^| find /i "EditionID"') do (
    set "WIN_EDITION=%%B"
)

if defined WIN_EDITION (
    if "!LANG!"=="RU" (
        call :log_info "Обнаружена редакция Windows: %WIN_EDITION%"
    ) else (
        call :log_info "Detected Windows Edition: %WIN_EDITION%"
    )
) else (
    if "!LANG!"=="RU" (
        call :log_info "Не удалось определить редакцию Windows"
    ) else (
        call :log_info "Failed to detect Windows Edition"
    )
)
exit /b

:: ==============================================================
::  REG / SERVICES / TASKS HELPERS
:: ==============================================================

:apply_reg_dword
set "REG_KEY=%~1"
set "REG_VAL=%~2"
set "REG_DATA=%~3"
set "REG_DESC=%~4"

reg add "%REG_KEY%" /v "%REG_VAL%" /t REG_DWORD /d "%REG_DATA%" /f >nul 2>&1
if "%errorlevel%"=="0" (
    call :log_ok "%REG_DESC%"
) else (
    call :log_err "%REG_DESC%"
)
exit /b

:delete_reg_value
set "REG_KEY=%~1"
set "REG_VAL=%~2"
set "REG_DESC=%~3"

reg query "%REG_KEY%" /v "%REG_VAL%" >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_info "%REG_DESC%: параметр не найден, шаг пропущен"
    ) else (
        call :log_info "%REG_DESC%: value not found, step skipped"
    )
    exit /b
)

reg delete "%REG_KEY%" /v "%REG_VAL%" /f >nul 2>&1
if "%errorlevel%"=="0" (
    call :log_ok "%REG_DESC%"
) else (
    if "!LANG!"=="RU" (
        call :log_warn "%REG_DESC% не удалось удалить"
    ) else (
        call :log_warn "%REG_DESC% failed to delete"
    )
)
exit /b

:restore_reg_dword
set "REG_KEY=%~1"
set "REG_VAL=%~2"
set "REG_DATA=%~3"
set "REG_DESC=%~4"

reg add "%REG_KEY%" /v "%REG_VAL%" /t REG_DWORD /d "%REG_DATA%" /f >nul 2>&1
if "%errorlevel%"=="0" (
    call :log_ok "%REG_DESC%"
) else (
    if "!LANG!"=="RU" (
        call :log_warn "%REG_DESC% не удалось восстановить"
    ) else (
        call :log_warn "%REG_DESC% failed to restore"
    )
)
exit /b

:disable_service
set "SRV_NAME=%~1"
set "SRV_DESC=%~2"

sc query "%SRV_NAME%" >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_info "%SRV_DESC%: служба не найдена, шаг пропущен"
    ) else (
        call :log_info "%SRV_DESC%: service not found, step skipped"
    )
    exit /b
)

sc stop "%SRV_NAME%" >nul 2>&1
sc config "%SRV_NAME%" start= disabled >nul 2>&1

sc qc "%SRV_NAME%" | find /i "DISABLED" >nul 2>&1
if "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_ok "%SRV_DESC% отключена"
    ) else (
        call :log_ok "%SRV_DESC% disabled"
    )
) else (
    if "!LANG!"=="RU" (
        call :log_warn "%SRV_DESC% не удалось полностью отключить"
    ) else (
        call :log_warn "%SRV_DESC% failed to disable completely"
    )
)
exit /b

:enable_service_manual
set "SRV_NAME=%~1"
set "SRV_DESC=%~2"

sc query "%SRV_NAME%" >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_info "%SRV_DESC%: служба не найдена, шаг пропущен"
    ) else (
        call :log_info "%SRV_DESC%: service not found, step skipped"
    )
    exit /b
)

sc config "%SRV_NAME%" start= demand >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_warn "%SRV_DESC% не удалось перевести в ручной запуск"
    ) else (
        call :log_warn "%SRV_DESC% failed to set to manual start"
    )
    exit /b
)

sc qc "%SRV_NAME%" | find /i "DEMAND_START" >nul 2>&1
if "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_ok "%SRV_DESC% переведена в ручной запуск"
    ) else (
        call :log_ok "%SRV_DESC% set to manual start"
    )
) else (
    if "!LANG!"=="RU" (
        call :log_warn "%SRV_DESC% не удалось подтвердить ручной запуск"
    ) else (
        call :log_warn "%SRV_DESC% failed to confirm manual start"
    )
)
exit /b

:disable_task
set "TASK_NAME=%~1"
set "TASK_DESC=%~2"

schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_info "%TASK_DESC%: задача не найдена, шаг пропущен"
    ) else (
        call :log_info "%TASK_DESC%: task not found, step skipped"
    )
    exit /b
)

schtasks /change /tn "%TASK_NAME%" /disable >nul 2>&1
if "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_ok "%TASK_DESC% отключена"
    ) else (
        call :log_ok "%TASK_DESC% disabled"
    )
) else (
    if "!LANG!"=="RU" (
        call :log_warn "%TASK_DESC% не удалось отключить"
    ) else (
        call :log_warn "%TASK_DESC% failed to disable"
    )
)
exit /b

:enable_task
set "TASK_NAME=%~1"
set "TASK_DESC=%~2"

schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_info "%TASK_DESC%: задача не найдена, шаг пропущен"
    ) else (
        call :log_info "%TASK_DESC%: task not found, step skipped"
    )
    exit /b
)

schtasks /change /tn "%TASK_NAME%" /enable >nul 2>&1

schtasks /query /tn "%TASK_NAME%" /fo list /v >"%temp%\wintelemetry_task_restore.tmp" 2>nul
findstr /i "Disabled Отключ" "%temp%\wintelemetry_task_restore.tmp" >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_ok "%TASK_DESC% включена"
    ) else (
        call :log_ok "%TASK_DESC% enabled"
    )
) else (
    if "!LANG!"=="RU" (
        call :log_warn "%TASK_DESC% не удалось включить"
    ) else (
        call :log_warn "%TASK_DESC% failed to enable"
    )
)
del "%temp%\wintelemetry_task_restore.tmp" >nul 2>&1
exit /b

:: ==============================================================
::  STATE CHECK HELPERS
:: ==============================================================

:check_reg_privacy_state
set "CHK_KEY=%~1"
set "CHK_VAL=%~2"
set "CHK_EXPECT=%~3"
set "CHK_DESC=%~4"
set "FOUND_VALUE="

for /f "tokens=3" %%A in ('reg query "%CHK_KEY%" /v "%CHK_VAL%" 2^>nul ^| find /i "%CHK_VAL%"') do (
    set "FOUND_VALUE=%%A"
)

if not defined FOUND_VALUE (
    if "!LANG!"=="RU" (
        call :log_info "%CHK_DESC%: ограничение не активно"
    ) else (
        call :log_info "%CHK_DESC%: restriction not active"
    )
    exit /b
)

if /i "!FOUND_VALUE!"=="%CHK_EXPECT%" (
    if "!LANG!"=="RU" (
        call :log_ok "%CHK_DESC%: ограничение активно"
    ) else (
        call :log_ok "%CHK_DESC%: restriction active"
    )
) else (
    if "!LANG!"=="RU" (
        call :log_warn "%CHK_DESC%: обнаружено нестандартное значение"
    ) else (
        call :log_warn "%CHK_DESC%: non-standard value detected"
    )
)
exit /b

:check_service_neutral
set "CHK_SRV=%~1"
set "CHK_DESC=%~2"

sc query "%CHK_SRV%" >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_info "%CHK_DESC%: служба отсутствует в текущей системе"
    ) else (
        call :log_info "%CHK_DESC%: service missing on current system"
    )
    exit /b
)

sc qc "%CHK_SRV%" | find /i "DISABLED" >nul 2>&1
if "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_ok "%CHK_DESC%: отключена"
    ) else (
        call :log_ok "%CHK_DESC%: disabled"
    )
    exit /b
)

sc qc "%CHK_SRV%" | find /i "DEMAND_START" >nul 2>&1
if "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_info "%CHK_DESC%: работает в стандартном ручном режиме"
    ) else (
        call :log_info "%CHK_DESC%: running in standard manual mode"
    )
    exit /b
)

sc qc "%CHK_SRV%" | find /i "AUTO_START" >nul 2>&1
if "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_info "%CHK_DESC%: работает в автоматическом режиме"
    ) else (
        call :log_info "%CHK_DESC%: running in automatic mode"
    )
    exit /b
)

if "!LANG!"=="RU" (
    call :log_warn "%CHK_DESC%: текущий режим запуска отличается от ожидаемого"
) else (
    call :log_warn "%CHK_DESC%: current start mode differs from expected"
)
exit /b

:check_task_neutral
set "CHK_TASK=%~1"
set "CHK_DESC=%~2"

schtasks /query /tn "%CHK_TASK%" /fo list /v >"%temp%\wintelemetry_task_check.tmp" 2>nul
if not "%errorlevel%"=="0" (
    del "%temp%\wintelemetry_task_check.tmp" >nul 2>&1
    if "!LANG!"=="RU" (
        call :log_info "%CHK_DESC%: задача отсутствует в текущей системе"
    ) else (
        call :log_info "%CHK_DESC%: task missing on current system"
    )
    exit /b
)

findstr /i "Disabled Отключ" "%temp%\wintelemetry_task_check.tmp" >nul 2>&1
if "%errorlevel%"=="0" (
    if "!LANG!"=="RU" (
        call :log_ok "%CHK_DESC%: отключена"
    ) else (
        call :log_ok "%CHK_DESC%: disabled"
    )
) else (
    if "!LANG!"=="RU" (
        call :log_info "%CHK_DESC%: включена"
    ) else (
        call :log_info "%CHK_DESC%: enabled"
    )
)
del "%temp%\wintelemetry_task_check.tmp" >nul 2>&1
exit /b

:check_finish
echo.
echo    ============================================================
if "!LANG!"=="RU" (
    echo    Проверка завершена
) else (
    echo    Verification completed
)
echo    ============================================================
echo.
echo    [OK]   !OK_COUNT!
echo    [INFO] !INFO_COUNT!
echo    [WARN] !WARN_COUNT!
echo.
call :write_log_blank
call :write_result_blank
if "!LANG!"=="RU" (
    call :write_log_line "Сводка проверки:"
    call :write_result_line "Сводка проверки:"
) else (
    call :write_log_line "Verification summary:"
    call :write_result_line "Verification summary:"
)
call :write_log_line "[OK]   !OK_COUNT!"
call :write_result_line "[OK]   !OK_COUNT!"
call :write_log_line "[INFO] !INFO_COUNT!"
call :write_result_line "[INFO] !INFO_COUNT!"
call :write_log_line "[WARN] !WARN_COUNT!"
call :write_result_line "[WARN] !WARN_COUNT!"
call :pause_here
goto :main_menu

:quick_check
if "!LANG!"=="RU" (
    set "MODE_NAME=Быстрая проверка состояния"
) else (
    set "MODE_NAME=Quick Status Audit"
)
call :reset_counters
call :init_logs
call :header

if "!LANG!"=="RU" (
    echo    Выполняется быстрая проверка текущего состояния...
    call :write_log_line "Выполняется быстрая проверка текущего состояния..."
    call :write_result_line "Выполняется быстрая проверка текущего состояния..."
) else (
    echo    Performing quick status audit...
    call :write_log_line "Performing quick status audit..."
    call :write_result_line "Performing quick status audit..."
)
echo.
call :write_log_blank
call :write_result_blank

call :detect_windows_edition
call :separator

if "!LANG!"=="RU" (
    echo    [ПРОВЕРКА] Основные privacy-политики
    call :write_log_line "[ПРОВЕРКА] Основные privacy-политики"
    call :write_result_line "[ПРОВЕРКА] Основные privacy-политики"
) else (
    echo    [AUDIT] Core Privacy Policies
    call :write_log_line "[AUDIT] Core Privacy Policies"
    call :write_result_line "[AUDIT] Core Privacy Policies"
)
echo.

if "!LANG!"=="RU" (
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" "0x0" "Телеметрия"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" "0x0" "История активности"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" "0x0" "Публикация активности"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" "0x0" "Отправка активности в облако"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" "0x1" "Web-поиск в меню Пуск"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" "0x1" "Геолокация"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" "0x1" "Consumer Features"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" "0x0" "Widgets и Feeds"
) else (
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" "0x0" "Telemetry"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" "0x0" "Activity Feed"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" "0x0" "Publish Activities"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" "0x0" "Upload Activities to Cloud"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" "0x1" "Start Menu Web Search"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" "0x1" "Location Services"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" "0x1" "Consumer Features"
    call :check_reg_privacy_state "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" "0x0" "Widgets and Feeds"
)

call :separator

if "!LANG!"=="RU" (
    echo    [ПРОВЕРКА] Системные службы
    call :write_log_line "[ПРОВЕРКА] Системные службы"
    call :write_result_line "[ПРОВЕРКА] Системные службы"
) else (
    echo    [AUDIT] System Services
    call :write_log_line "[AUDIT] System Services"
    call :write_result_line "[AUDIT] System Services"
)
echo.

if "!LANG!"=="RU" (
    call :check_service_neutral "DiagTrack" "Служба DiagTrack"
    call :check_service_neutral "dmwappushservice" "Служба dmwappushservice"
) else (
    call :check_service_neutral "DiagTrack" "DiagTrack Service"
    call :check_service_neutral "dmwappushservice" "dmwappushservice Service"
)

call :separator

if "!LANG!"=="RU" (
    echo    [ПРОВЕРКА] Задачи телеметрии
    call :write_log_line "[ПРОВЕРКА] Задачи телеметрии"
    call :write_result_line "[ПРОВЕРКА] Задачи телеметрии"
) else (
    echo    [AUDIT] Telemetry Tasks
    call :write_log_line "[AUDIT] Telemetry Tasks"
    call :write_result_line "[AUDIT] Telemetry Tasks"
)
echo.

call :check_task_neutral "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" "Compatibility Appraiser"
call :check_task_neutral "\Microsoft\Windows\Application Experience\ProgramDataUpdater" "ProgramDataUpdater"
call :check_task_neutral "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" "CEIP Consolidator"
call :check_task_neutral "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" "CEIP Kernel Task"
call :check_task_neutral "\Microsoft\Windows\Feedback\Siuf\DmClient" "Feedback DmClient"

call :check_finish

:: ==============================================================
::  POST RESTORE CHECK
:: ==============================================================

:post_restore_check
call :reset_counters
call :header

if "!LANG!"=="RU" (
    echo    Проверка восстановления настроек
    echo.
    echo    Утилита проверяет, удалось ли вернуть стандартное поведение Windows.
) else (
    echo    Verification of Restored Settings
    echo.
    echo    Checking if standard Windows default behaviour was successfully restored.
)
echo.
echo    ------------------------------------------------------------
echo.
call :write_log_blank
call :write_result_blank
if "!LANG!"=="RU" (
    call :write_log_line "Проверка восстановления настроек"
    call :write_result_line "Проверка восстановления настроек"
) else (
    call :write_log_line "Verification of Restored Settings"
    call :write_result_line "Verification of Restored Settings"
)

reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" ( call :log_ok "Ограничение телеметрии снято" ) else ( call :log_ok "Telemetry policy restriction removed" )
) else (
    if "!LANG!"=="RU" ( call :log_warn "Ограничение телеметрии всё ещё активно" ) else ( call :log_warn "Telemetry policy restriction still active" )
)

reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" ( call :log_ok "История активности работает в стандартном режиме" ) else ( call :log_ok "Activity history operating in default state" )
) else (
    if "!LANG!"=="RU" ( call :log_warn "История активности всё ещё ограничена" ) else ( call :log_warn "Activity history still restricted" )
)

reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" ( call :log_ok "Web-поиск в меню Пуск работает в стандартном режиме" ) else ( call :log_ok "Start Menu Web Search operating in default state" )
) else (
    if "!LANG!"=="RU" ( call :log_warn "Web-поиск в меню Пуск всё ещё ограничен" ) else ( call :log_warn "Start Menu Web Search still restricted" )
)

reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableLocation >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" ( call :log_ok "Ограничение геолокации снято" ) else ( call :log_ok "Location restriction removed" )
) else (
    if "!LANG!"=="RU" ( call :log_warn "Геолокация всё ещё ограничена" ) else ( call :log_warn "Location restriction still active" )
)

reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" ( call :log_ok "Ограничение Consumer Features снято" ) else ( call :log_ok "Consumer Features restriction removed" )
) else (
    if "!LANG!"=="RU" ( call :log_warn "Consumer Features всё ещё ограничены" ) else ( call :log_warn "Consumer Features still restricted" )
)

reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds 2>nul | find /i "0x1" >nul 2>&1
if "%errorlevel%"=="0" (
    if "!LANG!"=="RU" ( call :log_ok "Widgets и Feeds работают в стандартном режиме" ) else ( call :log_ok "Widgets and Feeds operating in default state" )
) else (
    reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds >nul 2>&1
    if not "%errorlevel%"=="0" (
        if "!LANG!"=="RU" ( call :log_info "Widgets и Feeds: ограничение не применялось ранее или уже снято" ) else ( call :log_info "Widgets and Feeds: restriction not applied or already removed" )
    ) else (
        if "!LANG!"=="RU" ( call :log_warn "Widgets и Feeds всё ещё работают не в стандартном режиме" ) else ( call :log_warn "Widgets and Feeds still not in default state" )
    )
)

sc query "DiagTrack" >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" ( call :log_info "Служба DiagTrack отсутствует в текущей системе" ) else ( call :log_info "DiagTrack service missing on system" )
) else (
    sc qc "DiagTrack" | find /i "DEMAND_START" >nul 2>&1
    if "%errorlevel%"=="0" (
        if "!LANG!"=="RU" ( call :log_ok "Служба DiagTrack возвращена в стандартный ручной режим" ) else ( call :log_ok "DiagTrack service returned to manual start mode" )
    ) else (
        if "!LANG!"=="RU" ( call :log_warn "Служба DiagTrack ещё не возвращена в стандартный режим" ) else ( call :log_warn "DiagTrack service not in manual start mode" )
    )
)

sc query "dmwappushservice" >nul 2>&1
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" ( call :log_info "Служба dmwappushservice отсутствует в текущей системе" ) else ( call :log_info "dmwappushservice service missing on system" )
) else (
    sc qc "dmwappushservice" | find /i "DEMAND_START" >nul 2>&1
    if "%errorlevel%"=="0" (
        if "!LANG!"=="RU" ( call :log_ok "Служба dmwappushservice возвращена в стандартный ручной режим" ) else ( call :log_ok "dmwappushservice service returned to manual start mode" )
    ) else (
        if "!LANG!"=="RU" ( call :log_warn "Служба dmwappushservice ещё не возвращена в стандартный режим" ) else ( call :log_warn "dmwappushservice service not in manual start mode" )
    )
)

schtasks /query /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /fo list /v >"%temp%\restore_chk_1.tmp" 2>nul
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" ( call :log_info "Compatibility Appraiser отсутствует в текущей системе" ) else ( call :log_info "Compatibility Appraiser missing on system" )
) else (
    findstr /i "Disabled Отключ" "%temp%\restore_chk_1.tmp" >nul 2>&1
    if not "%errorlevel%"=="0" (
        if "!LANG!"=="RU" ( call :log_ok "Compatibility Appraiser включена" ) else ( call :log_ok "Compatibility Appraiser enabled" )
    ) else (
        if "!LANG!"=="RU" ( call :log_warn "Compatibility Appraiser всё ещё отключена" ) else ( call :log_warn "Compatibility Appraiser still disabled" )
    )
)
del "%temp%\restore_chk_1.tmp" >nul 2>&1

schtasks /query /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /fo list /v >"%temp%\restore_chk_2.tmp" 2>nul
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" ( call :log_info "CEIP Consolidator отсутствует в текущей системе" ) else ( call :log_info "CEIP Consolidator missing on system" )
) else (
    findstr /i "Disabled Отключ" "%temp%\restore_chk_2.tmp" >nul 2>&1
    if not "%errorlevel%"=="0" (
        if "!LANG!"=="RU" ( call :log_ok "CEIP Consolidator включена" ) else ( call :log_ok "CEIP Consolidator enabled" )
    ) else (
        if "!LANG!"=="RU" ( call :log_warn "CEIP Consolidator всё ещё отключена" ) else ( call :log_warn "CEIP Consolidator still disabled" )
    )
)
del "%temp%\restore_chk_2.tmp" >nul 2>&1

schtasks /query /tn "\Microsoft\Windows\Feedback\Siuf\DmClient" /fo list /v >"%temp%\restore_chk_3.tmp" 2>nul
if not "%errorlevel%"=="0" (
    if "!LANG!"=="RU" ( call :log_info "Feedback DmClient отсутствует в текущей системе" ) else ( call :log_info "Feedback DmClient missing on system" )
) else (
    findstr /i "Disabled Отключ" "%temp%\restore_chk_3.tmp" >nul 2>&1
    if not "%errorlevel%"=="0" (
        if "!LANG!"=="RU" ( call :log_ok "Feedback DmClient включена" ) else ( call :log_ok "Feedback DmClient enabled" )
    ) else (
        if "!LANG!"=="RU" ( call :log_warn "Feedback DmClient всё ещё отключена" ) else ( call :log_warn "Feedback DmClient still disabled" )
    )
)
del "%temp%\restore_chk_3.tmp" >nul 2>&1

echo.
echo    ============================================================
if "!LANG!"=="RU" (
    echo    Проверка восстановления завершена
) else (
    echo    Restoration verification completed
)
echo    ============================================================
echo.
echo    [OK]   !OK_COUNT!
echo    [INFO] !INFO_COUNT!
echo    [WARN] !WARN_COUNT!
echo.
call :write_log_blank
call :write_result_blank
if "!LANG!"=="RU" (
    call :write_log_line "Проверка восстановления завершена"
    call :write_result_line "Проверка восстановления завершена"
) else (
    call :write_log_line "Restoration verification completed"
    call :write_result_line "Restoration verification completed"
)
call :write_log_line "[OK]   !OK_COUNT!"
call :write_result_line "[OK]   !OK_COUNT!"
call :write_log_line "[INFO] !INFO_COUNT!"
call :write_result_line "[INFO] !INFO_COUNT!"
call :write_log_line "[WARN] !WARN_COUNT!"
call :write_result_line "[WARN] !WARN_COUNT!"
call :pause_here
goto :main_menu

:: ==============================================================
::  RESTORE DEFAULT SETTINGS
:: ==============================================================

:confirm_restore
call :header
if "!LANG!"=="RU" goto :confirm_restore_ru

:confirm_restore_en
echo    Restore Default Settings
echo.
echo    Operations to perform:
echo    - Removal of core privacy policies applied by utility
echo    - Reset telemetry services to manual startup
echo    - Re-enable scheduled telemetry tasks disabled by utility
echo.
echo    Important:
echo    - This reverts changes made by Windows Telemetry OFF
echo    - This does not restore personal custom settings prior to script execution
echo.
set /p "CONFIRM=   Continue? (Y/N): "
goto :confirm_restore_process

:confirm_restore_ru
echo    Восстановить стандартные настройки
echo.
echo    Будет выполнено:
echo    - снятие основных privacy-ограничений, применённых утилитой
echo    - возврат служб телеметрии в ручной запуск
echo    - повторное включение задач, отключённых утилитой
echo.
echo    Важно:
echo    - это откат изменений Windows Telemetry OFF
echo    - это не точное восстановление всех прежних пользовательских настроек
echo.
set /p "CONFIRM=   Продолжить? (Y/N): "
goto :confirm_restore_process

:confirm_restore_process
if /i "%CONFIRM%"=="Y" goto :run_restore
goto :main_menu

:run_restore
if "!LANG!"=="RU" (
    set "MODE_NAME=Восстановить стандартные настройки"
) else (
    set "MODE_NAME=Restore Default Settings"
)
call :reset_counters
call :init_logs
call :header

if "!LANG!"=="RU" (
    echo    Запуск режима: %MODE_NAME%
    call :write_log_line "Запуск режима: %MODE_NAME%"
    call :write_result_line "Запуск режима: %MODE_NAME%"
) else (
    echo    Starting profile: %MODE_NAME%
    call :write_log_line "Starting profile: %MODE_NAME%"
    call :write_result_line "Starting profile: %MODE_NAME%"
)
echo.
call :write_log_blank
call :write_result_blank

call :detect_windows_edition
call :separator

call :restore_section_policies
call :restore_section_services
call :restore_section_tasks

call :final_report_restore
call :post_restore_check

:restore_section_policies
if "!LANG!"=="RU" (
    echo    [ЭТАП 1] Восстановление системных параметров
    call :write_log_line "[ЭТАП 1] Восстановление системных параметров"
    call :write_result_line "[ЭТАП 1] Восстановление системных параметров"
) else (
    echo    [STAGE 1] Restoring System Policies
    call :write_log_line "[STAGE 1] Restoring System Policies"
    call :write_result_line "[STAGE 1] Restoring System Policies"
)
echo.

if "!LANG!"=="RU" (
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" "Удалено ограничение телеметрии через policy"
    call :delete_reg_value "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" "Удалено резервное ограничение телеметрии"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" "Удалено ограничение Consumer Features"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" "1" "Восстановлен рекламный ID"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" "Удалено policy-ограничение рекламного ID"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" "Удалено ограничение истории активности"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" "Удалено ограничение публикации активности"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" "Удалено ограничение отправки активности в облако"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338388Enabled" "1" "Восстановлены советы и рекомендации"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" "1" "Восстановлены дополнительные рекомендации"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" "1" "Восстановлены подсказки Windows"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" "1" "Восстановлены системные предложения"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" "1" "Восстановлен feedback-запрос"
    call :delete_reg_value "HKCU\SOFTWARE\Microsoft\Siuf\Rules" "PeriodInNanoSeconds" "Удалено ограничение частоты feedback-уведомлений"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" "Удалено ограничение web-поиска в меню Пуск"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" "1" "Восстановлен Bing Search в поиске"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" "1" "Восстановлен облачный поиск"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" "Удалено ограничение Widgets и News and Interests"
    call :restore_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" "1" "Восстановлены Windows Feeds"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsAccessLocation" "Удалено ограничение доступа приложений к геолокации"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" "Удалено ограничение геолокации Windows"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" "AllowInputPersonalization" "Удалено ограничение персонализации ввода"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreenCamera" "Удалено ограничение камеры на экране блокировки"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreenSlideshow" "Удалено ограничение слайд-шоу на экране блокировки"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "AllowCrossDeviceClipboard" "Удалено ограничение межустройственного буфера обмена"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableCdp" "Удалено ограничение Connected Devices Platform"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableSoftLanding" "Удалено ограничение рекламных подсказок Microsoft"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableTailoredExperiencesWithDiagnosticData" "Удалено ограничение персонализированных предложений"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableThirdPartySuggestions" "Удалено ограничение сторонних рекомендаций"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "ConfigureWindowsSpotlight" "Удалено ограничение Windows Spotlight"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SpyNetReporting" "Удалено ограничение участия в Microsoft MAPS"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SubmitSamplesConsent" "Удалено ограничение автоматической отправки образцов"
) else (
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" "Removed telemetry policy restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" "Removed backup telemetry policy restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" "Removed Consumer Features restriction"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" "1" "Restored Advertising ID"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" "Removed Advertising ID policy restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" "Removed activity history restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" "Removed user activity publishing restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" "Removed activity cloud upload restriction"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338388Enabled" "1" "Restored tips and recommendations"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" "1" "Restored extra recommendations"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" "1" "Restored Windows tips"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" "1" "Restored system suggestions"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" "1" "Restored feedback prompt"
    call :delete_reg_value "HKCU\SOFTWARE\Microsoft\Siuf\Rules" "PeriodInNanoSeconds" "Removed feedback prompt frequency limit"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" "Removed Start Menu web search restriction"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" "1" "Restored Bing Search in search panel"
    call :restore_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" "1" "Restored cloud search consent"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" "Removed Widgets and News & Interests restriction"
    call :restore_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" "1" "Restored Windows Feeds"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsAccessLocation" "Removed app location access restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" "Removed Windows location restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" "AllowInputPersonalization" "Removed input personalization restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreenCamera" "Removed lock screen camera restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreenSlideshow" "Removed lock screen slideshow restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "AllowCrossDeviceClipboard" "Removed cross-device clipboard restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableCdp" "Removed Connected Devices Platform restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableSoftLanding" "Removed Microsoft promotional tips restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableTailoredExperiencesWithDiagnosticData" "Removed tailored experiences restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableThirdPartySuggestions" "Removed third-party suggestions restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "ConfigureWindowsSpotlight" "Removed Windows Spotlight restriction"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SpyNetReporting" "Removed Microsoft MAPS reporting limit"
    call :delete_reg_value "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SubmitSamplesConsent" "Removed automatic sample submission limit"
)

call :separator
exit /b

:restore_section_services
if "!LANG!"=="RU" (
    echo    [ЭТАП 2] Восстановление служб
    call :write_log_line "[ЭТАП 2] Восстановление служб"
    call :write_result_line "[ЭТАП 2] Восстановление служб"
) else (
    echo    [STAGE 2] Restoring Services
    call :write_log_line "[STAGE 2] Restoring Services"
    call :write_result_line "[STAGE 2] Restoring Services"
)
echo.

if "!LANG!"=="RU" (
    call :enable_service_manual "DiagTrack" "Служба DiagTrack"
    call :enable_service_manual "dmwappushservice" "Служба dmwappushservice"
) else (
    call :enable_service_manual "DiagTrack" "DiagTrack Service"
    call :enable_service_manual "dmwappushservice" "dmwappushservice Service"
)

call :separator
exit /b

:restore_section_tasks
if "!LANG!"=="RU" (
    echo    [ЭТАП 3] Восстановление задач
    call :write_log_line "[ЭТАП 3] Восстановление задач"
    call :write_result_line "[ЭТАП 3] Восстановление задач"
) else (
    echo    [STAGE 3] Restoring Scheduled Tasks
    call :write_log_line "[STAGE 3] Restoring Scheduled Tasks"
    call :write_result_line "[STAGE 3] Restoring Scheduled Tasks"
)
echo.

call :enable_task "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" "Compatibility Appraiser"
call :enable_task "\Microsoft\Windows\Application Experience\PcaPatchDbTask" "PcaPatchDbTask"
call :enable_task "\Microsoft\Windows\Application Experience\ProgramDataUpdater" "ProgramDataUpdater"
call :enable_task "\Microsoft\Windows\Application Experience\MareBackup" "Application Experience MareBackup"
call :enable_task "\Microsoft\Windows\Application Experience\StartupAppTask" "StartupAppTask"
call :enable_task "\Microsoft\Windows\Autochk\Proxy" "Autochk Proxy"
call :enable_task "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" "CEIP Consolidator"
call :enable_task "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" "CEIP Kernel Task"
call :enable_task "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" "CEIP USB Task"
call :enable_task "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" "Disk Diagnostic Data Collector"
call :enable_task "\Microsoft\Windows\Feedback\Siuf\DmClient" "Feedback DmClient"
call :enable_task "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" "Feedback DmClientOnScenarioDownload"
call :enable_task "\Microsoft\Windows\PI\Sqm-Tasks" "SQM Tasks"
call :enable_task "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" "Power Efficiency Diagnostics"
call :enable_task "\Microsoft\Windows\Maps\MapsToastTask" "Maps Toast Task"
call :enable_task "\Microsoft\Windows\Maps\MapsUpdateTask" "Maps Update Task"
call :enable_task "\Microsoft\Windows\SettingSync\BackgroundUploadTask" "SettingSync BackgroundUploadTask"
call :enable_task "\Microsoft\Windows\SettingSync\NetworkStateChangeTask" "SettingSync NetworkStateChangeTask"

call :separator
exit /b

:: ==============================================================
::  MAIN MENU
:: ==============================================================

:main_menu
call :header
if "!LANG!"=="RU" goto :main_menu_ru

:main_menu_en
echo    What this utility does:
echo.
echo    - Reduces Windows background telemetry
echo    - Disables diagnostic tasks and background services
echo    - Reduces recommendations, tips, and activity collection
echo    - Allows quick verification of privacy settings
echo    - Restores default Windows settings when needed
echo.
echo    What this utility DOES NOT do:
echo.
echo    - Does not remove Windows system components
echo    - Does not touch Edge, Store, OneDrive, Defender, or Windows Update
echo    - Does not use aggressive service blocking methods
echo.
echo    Select an option:
echo.
echo    [1] Safe      - Basic telemetry disabling
echo    [2] Balanced  - Safe + services and main telemetry tasks
echo    [3] Pro       - Balanced + advanced privacy settings
echo    [4] Check current privacy state
echo    [5] Restore default settings
echo    [L] Change Language / Сменить язык (Current: English)
echo    [0] Exit
echo.
set /p "MENU_CHOICE=   Your choice: "
goto :main_menu_process

:main_menu_ru
echo    Что делает утилита:
echo.
echo    - уменьшает фоновую телеметрию Windows
echo    - отключает часть диагностических задач и служб
echo    - снижает количество рекомендаций, советов и фонового сбора активности
echo    - позволяет быстро проверить текущее состояние основных privacy-настроек
echo    - позволяет восстановить стандартные настройки после применения фикса
echo.
echo    Что эта версия НЕ делает:
echo.
echo    - не удаляет системные компоненты Windows
echo    - не трогает Edge, Store, OneDrive, Defender и Центр обновления
echo    - не использует агрессивные методы блокировки служб
echo.
echo    Выберите действие:
echo.
echo    [1] Safe      - базовое отключение лишней телеметрии
echo    [2] Balanced  - Safe + службы и основные задачи телеметрии
echo    [3] Pro       - Balanced + расширенные privacy-настройки
echo    [4] Проверить текущее состояние
echo    [5] Восстановить стандартные настройки
echo    [L] Change Language / Сменить язык (Текущий: Русский)
echo    [0] Выход
echo.
set /p "MENU_CHOICE=   Ваш выбор: "
goto :main_menu_process

:main_menu_process
if "%MENU_CHOICE%"=="1" (
    set "MODE_ID=SAFE"
    set "MODE_NAME=Safe"
    goto :confirm_safe
)
if "%MENU_CHOICE%"=="2" (
    set "MODE_ID=BALANCED"
    set "MODE_NAME=Balanced"
    goto :confirm_balanced
)
if "%MENU_CHOICE%"=="3" (
    set "MODE_ID=PRO"
    set "MODE_NAME=Pro"
    goto :confirm_pro
)
if "%MENU_CHOICE%"=="4" goto :quick_check
if "%MENU_CHOICE%"=="5" goto :confirm_restore
if /i "%MENU_CHOICE%"=="L" goto :lang_selection
if "%MENU_CHOICE%"=="0" exit /b

echo.
if "!LANG!"=="RU" (
    echo    Некорректный выбор. Попробуйте снова.
) else (
    echo    Invalid choice. Please try again.
)
timeout /t 2 >nul
goto :main_menu

:confirm_safe
call :header
if "!LANG!"=="RU" goto :confirm_safe_ru

:confirm_safe_en
echo    Safe Profile
echo.
echo    Operations to perform:
echo    - Disable activity history and feed
echo    - Block advertising ID
echo    - Disable consumer features
echo    - Disable tips, recommendations, and feedback prompts
echo    - Restrict location tracking
echo    - Disable Start Menu web search
echo    - Disable Widgets via group policy
echo.
echo    This profile is recommended for general users.
echo.
set /p "CONFIRM=   Continue? (Y/N): "
goto :confirm_safe_process

:confirm_safe_ru
echo    Режим Safe
echo.
echo    Будет выполнено:
echo    - отключение истории активности
echo    - отключение рекламного ID
echo    - отключение consumer features
echo    - отключение подсказок, рекомендаций и feedback
echo    - ограничение location tracking
echo    - отключение web-поиска в меню Пуск
echo    - отключение Widgets через policy
echo.
echo    Этот режим подходит большинству пользователей.
echo.
set /p "CONFIRM=   Продолжить? (Y/N): "
goto :confirm_safe_process

:confirm_safe_process
if /i "%CONFIRM%"=="Y" goto :run_mode
goto :main_menu

:confirm_balanced
call :header
if "!LANG!"=="RU" goto :confirm_balanced_ru

:confirm_balanced_en
echo    Balanced Profile
echo.
echo    Operations to perform: All Safe settings, plus:
echo    - Disable DiagTrack and dmwappushservice services
echo    - Disable core CEIP and telemetry scheduled tasks
echo.
echo    Recommended for deeper privacy optimization.
echo.
set /p "CONFIRM=   Continue? (Y/N): "
goto :confirm_balanced_process

:confirm_balanced_ru
echo    Режим Balanced
echo.
echo    Будет выполнено всё из Safe, а также:
echo    - отключение служб DiagTrack и dmwappushservice
echo    - отключение основных задач CEIP и телеметрии
echo.
echo    Подходит для более глубокого ограничения телеметрии.
echo.
set /p "CONFIRM=   Продолжить? (Y/N): "
goto :confirm_balanced_process

:confirm_balanced_process
if /i "%CONFIRM%"=="Y" goto :run_mode
goto :main_menu

:confirm_pro
call :header
if "!LANG!"=="RU" goto :confirm_pro_ru

:confirm_pro_en
echo    Pro Profile
echo.
echo    Operations to perform: All Balanced settings, plus:
echo    - Extended disabling of diagnostic and feedback tasks
echo    - Advanced input personalization and spotlight restrictions
echo.
echo    Important:
echo    - No system components are deleted
echo    - Major Windows updates may revert some group policy settings
echo.
set /p "CONFIRM=   Continue? (Y/N): "
goto :confirm_pro_process

:confirm_pro_ru
echo    Режим Pro
echo.
echo    Будет выполнено всё из Balanced, а также:
echo    - расширенное отключение диагностических и feedback-задач
echo    - более глубокое применение privacy-настроек
echo.
echo    Важно:
echo    - системные компоненты не удаляются
echo    - после крупных обновлений Windows часть настроек может быть возвращена системой
echo.
set /p "CONFIRM=   Продолжить? (Y/N): "
goto :confirm_pro_process

:confirm_pro_process
if /i "%CONFIRM%"=="Y" goto :run_mode
goto :main_menu

:: ==============================================================
::  PROFILE EXECUTION
:: ==============================================================

:run_mode
call :reset_counters
call :init_logs
call :header

if "!LANG!"=="RU" (
    echo    Запуск режима: %MODE_NAME%
    call :write_log_line "Запуск режима: %MODE_NAME%"
    call :write_result_line "Запуск режима: %MODE_NAME%"
) else (
    echo    Starting profile: %MODE_NAME%
    call :write_log_line "Starting profile: %MODE_NAME%"
    call :write_result_line "Starting profile: %MODE_NAME%"
)
echo.
call :write_log_blank
call :write_result_blank

call :detect_windows_edition
call :separator

call :section_safe

if /i "%MODE_ID%"=="BALANCED" call :section_balanced
if /i "%MODE_ID%"=="PRO" call :section_balanced
if /i "%MODE_ID%"=="PRO" call :section_pro

call :final_report
call :pause_here
goto :main_menu

:: ==============================================================
::  SAFE SECTION
:: ==============================================================

:section_safe
if "!LANG!"=="RU" (
    echo    [ЭТАП 1] Базовые privacy-настройки
    call :write_log_line "[ЭТАП 1] Базовые privacy-настройки"
    call :write_result_line "[ЭТАП 1] Базовые privacy-настройки"
) else (
    echo    [STAGE 1] Basic Privacy Settings
    call :write_log_line "[STAGE 1] Basic Privacy Settings"
    call :write_result_line "[STAGE 1] Basic Privacy Settings"
)
echo.

if "!LANG!"=="RU" (
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" "0" "Ограничение телеметрии через policy"
    call :apply_reg_dword "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" "0" "Резервное ограничение телеметрии"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" "1" "Отключены Consumer Features"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" "0" "Отключён рекламный ID"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" "1" "Заблокирован рекламный ID через policy"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" "0" "Отключена история активности"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" "0" "Отключена публикация активности"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" "0" "Отключена отправка активности в облако"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338388Enabled" "0" "Отключены советы и рекомендации"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" "0" "Отключены дополнительные рекомендации"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" "0" "Отключены подсказки Windows"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" "0" "Отключены предложения в системе"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" "0" "Отключён feedback-запрос"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Siuf\Rules" "PeriodInNanoSeconds" "0" "Снижена частота feedback-уведомлений"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" "1" "Отключён web-поиск в меню Пуск"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" "0" "Отключён Bing Search в поиске"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" "0" "Ограничен облачный поиск"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" "0" "Отключены Widgets и News and Interests"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" "0" "Отключены Windows Feeds"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsAccessLocation" "2" "Ограничен доступ приложений к геолокации"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" "1" "Отключена геолокация Windows"
) else (
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" "0" "Telemetry policy restriction"
    call :apply_reg_dword "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" "0" "Backup telemetry policy restriction"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" "1" "Consumer Features disabled"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" "0" "Advertising ID disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" "1" "Advertising ID blocked via policy"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" "0" "Activity feed disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" "0" "Publishing user activities disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" "0" "Uploading user activities to cloud disabled"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338388Enabled" "0" "Tips and recommendations disabled"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" "0" "Extra recommendations disabled"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" "0" "Windows prompts disabled"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" "0" "System pane suggestions disabled"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" "0" "Feedback requests disabled"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Siuf\Rules" "PeriodInNanoSeconds" "0" "Feedback frequency reduced"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" "1" "Start menu web search disabled"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" "0" "Bing Search in search panel disabled"
    call :apply_reg_dword "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" "0" "Cloud search consent restricted"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" "0" "Widgets and News & Interests disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" "0" "Windows Feeds disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsAccessLocation" "2" "App location access restricted"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" "1" "Windows location services disabled"
)

call :separator
exit /b

:: ==============================================================
::  BALANCED SECTION
:: ==============================================================

:section_balanced
if "!LANG!"=="RU" (
    echo    [ЭТАП 2] Службы и основные задачи телеметрии
    call :write_log_line "[ЭТАП 2] Службы и основные задачи телеметрии"
    call :write_result_line "[ЭТАП 2] Службы и основные задачи телеметрии"
) else (
    echo    [STAGE 2] Services and Core Telemetry Tasks
    call :write_log_line "[STAGE 2] Services and Core Telemetry Tasks"
    call :write_result_line "[STAGE 2] Services and Core Telemetry Tasks"
)
echo.

if "!LANG!"=="RU" (
    call :disable_service "DiagTrack" "Служба DiagTrack"
    call :disable_service "dmwappushservice" "Служба dmwappushservice"
) else (
    call :disable_service "DiagTrack" "DiagTrack Service"
    call :disable_service "dmwappushservice" "dmwappushservice Service"
)

call :disable_task "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" "Compatibility Appraiser"
call :disable_task "\Microsoft\Windows\Application Experience\PcaPatchDbTask" "PcaPatchDbTask"
call :disable_task "\Microsoft\Windows\Application Experience\ProgramDataUpdater" "ProgramDataUpdater"
call :disable_task "\Microsoft\Windows\Autochk\Proxy" "Autochk Proxy"
call :disable_task "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" "CEIP Consolidator"
call :disable_task "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" "CEIP Kernel Task"
call :disable_task "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" "CEIP USB Task"
call :disable_task "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" "Disk Diagnostic Data Collector"
call :disable_task "\Microsoft\Windows\Feedback\Siuf\DmClient" "Feedback DmClient"
call :disable_task "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" "Feedback DmClientOnScenarioDownload"

call :separator
exit /b

:: ==============================================================
::  PRO SECTION
:: ==============================================================

:section_pro
if "!LANG!"=="RU" (
    echo    [ЭТАП 3] Расширенные privacy-настройки
    call :write_log_line "[ЭТАП 3] Расширенные privacy-настройки"
    call :write_result_line "[ЭТАП 3] Расширенные privacy-настройки"
) else (
    echo    [STAGE 3] Advanced Privacy Settings
    call :write_log_line "[STAGE 3] Advanced Privacy Settings"
    call :write_result_line "[STAGE 3] Advanced Privacy Settings"
)
echo.

if "!LANG!"=="RU" (
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" "AllowInputPersonalization" "0" "Отключена персонализация ввода"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreenCamera" "1" "Отключён доступ камеры на экране блокировки"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreenSlideshow" "1" "Отключено слайд-шоу на экране блокировки"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "AllowCrossDeviceClipboard" "0" "Отключён межустройственный буфер обмена"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableCdp" "0" "Отключён Connected Devices Platform"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableSoftLanding" "1" "Отключены рекламные подсказки Microsoft"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableTailoredExperiencesWithDiagnosticData" "1" "Отключены персонализированные предложения"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableThirdPartySuggestions" "1" "Отключены сторонние рекомендации"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "ConfigureWindowsSpotlight" "2" "Отключён Windows Spotlight"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SpyNetReporting" "0" "Снижен уровень участия в Microsoft MAPS"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SubmitSamplesConsent" "2" "Ограничена автоматическая отправка образцов"
) else (
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" "AllowInputPersonalization" "0" "Input personalization disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreenCamera" "1" "Lock screen camera access disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreenSlideshow" "1" "Lock screen slideshow disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "AllowCrossDeviceClipboard" "0" "Cross-device clipboard disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableCdp" "0" "Connected Devices Platform disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableSoftLanding" "1" "Microsoft promotional tips disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableTailoredExperiencesWithDiagnosticData" "1" "Tailored experiences disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableThirdPartySuggestions" "1" "Third-party suggestions disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "ConfigureWindowsSpotlight" "2" "Windows Spotlight disabled"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SpyNetReporting" "0" "Microsoft MAPS participation reduced"
    call :apply_reg_dword "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SubmitSamplesConsent" "2" "Automatic sample submission restricted"
)

call :disable_task "\Microsoft\Windows\Application Experience\MareBackup" "Application Experience MareBackup"
call :disable_task "\Microsoft\Windows\Application Experience\StartupAppTask" "StartupAppTask"
call :disable_task "\Microsoft\Windows\PI\Sqm-Tasks" "SQM Tasks"
call :disable_task "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" "Power Efficiency Diagnostics"
call :disable_task "\Microsoft\Windows\Maps\MapsToastTask" "Maps Toast Task"
call :disable_task "\Microsoft\Windows\Maps\MapsUpdateTask" "Maps Update Task"
call :disable_task "\Microsoft\Windows\SettingSync\BackgroundUploadTask" "SettingSync BackgroundUploadTask"
call :disable_task "\Microsoft\Windows\SettingSync\NetworkStateChangeTask" "SettingSync NetworkStateChangeTask"

call :separator
exit /b

:: ==============================================================
::  FINAL REPORTS
:: ==============================================================

:final_report
call :header
if "!LANG!"=="RU" (
    echo    Готово.
    echo.
    echo    Итоги выполнения:
    echo.
    echo    [OK]   !OK_COUNT!
    echo    [INFO] !INFO_COUNT!
    echo    [WARN] !WARN_COUNT!
    echo    [ERR]  !ERR_COUNT!
    echo.
    echo    Файлы отчёта:
    echo    - %LOGFILE%
    echo    - %RESULTFILE%
    echo.
    echo    Рекомендации:
    echo    - перезагрузите компьютер для полного применения изменений
    echo    - после крупных обновлений Windows часть настроек может быть возвращена системой
) else (
    echo    Finished.
    echo.
    echo    Execution Summary:
    echo.
    echo    [OK]   !OK_COUNT!
    echo    [INFO] !INFO_COUNT!
    echo    [WARN] !WARN_COUNT!
    echo    [ERR]  !ERR_COUNT!
    echo.
    echo    Report Files:
    echo    - %LOGFILE%
    echo    - %RESULTFILE%
    echo.
    echo    Recommendations:
    echo    - Restart your computer for all changes to take full effect
    echo    - Major Windows feature updates may revert some group policy parameters
)
echo.

call :write_log_blank
call :write_result_blank
if "!LANG!"=="RU" (
    call :write_log_line "Итоги выполнения:"
    call :write_result_line "Итоги выполнения:"
) else (
    call :write_log_line "Execution Summary:"
    call :write_result_line "Execution Summary:"
)
call :write_log_line "[OK]   !OK_COUNT!"
call :write_result_line "[OK]   !OK_COUNT!"
call :write_log_line "[INFO] !INFO_COUNT!"
call :write_result_line "[INFO] !INFO_COUNT!"
call :write_log_line "[WARN] !WARN_COUNT!"
call :write_result_line "[WARN] !WARN_COUNT!"
call :write_log_line "[ERR]  !ERR_COUNT!"
call :write_result_line "[ERR]  !ERR_COUNT!"
call :write_log_blank
call :write_result_blank
if "!LANG!"=="RU" (
    call :write_log_line "Рекомендуется перезагрузка компьютера."
    call :write_result_line "Рекомендуется перезагрузка компьютера."
) else (
    call :write_log_line "System restart recommended."
    call :write_result_line "System restart recommended."
)
exit /b

:final_report_restore
call :header
if "!LANG!"=="RU" (
    echo    Готово.
    echo.
    echo    Стандартные настройки восстановлены.
    echo.
    echo    Итоги выполнения:
    echo.
    echo    [OK]   !OK_COUNT!
    echo    [INFO] !INFO_COUNT!
    echo    [WARN] !WARN_COUNT!
    echo    [ERR]  !ERR_COUNT!
    echo.
    echo    Файлы отчёта:
    echo    - %LOGFILE%
    echo    - %RESULTFILE%
    echo.
    echo    Далее утилита выполнит понятную проверку результата восстановления.
) else (
    echo    Finished.
    echo.
    echo    Default settings restored.
    echo.
    echo    Execution Summary:
    echo.
    echo    [OK]   !OK_COUNT!
    echo    [INFO] !INFO_COUNT!
    echo    [WARN] !WARN_COUNT!
    echo    [ERR]  !ERR_COUNT!
    echo.
    echo    Report Files:
    echo    - %LOGFILE%
    echo    - %RESULTFILE%
    echo.
    echo    The utility will now perform a verification audit of the restoration.
)
echo.

call :write_log_blank
call :write_result_blank
if "!LANG!"=="RU" (
    call :write_log_line "Стандартные настройки восстановлены."
    call :write_result_line "Стандартные настройки восстановлены."
    call :write_log_line "Итоги выполнения:"
    call :write_result_line "Итоги выполнения:"
) else (
    call :write_log_line "Default settings restored."
    call :write_result_line "Default settings restored."
    call :write_log_line "Execution Summary:"
    call :write_result_line "Execution Summary:"
)
call :write_log_line "[OK]   !OK_COUNT!"
call :write_result_line "[OK]   !OK_COUNT!"
call :write_log_line "[INFO] !INFO_COUNT!"
call :write_result_line "[INFO] !INFO_COUNT!"
call :write_log_line "[WARN] !WARN_COUNT!"
call :write_result_line "[WARN] !WARN_COUNT!"
call :write_log_line "[ERR]  !ERR_COUNT!"
call :write_result_line "[ERR]  !ERR_COUNT!"
call :write_log_blank
call :write_result_blank
if "!LANG!"=="RU" (
    call :write_log_line "Запуск понятной проверки результата восстановления."
    call :write_result_line "Запуск понятной проверки результата восстановления."
) else (
    call :write_log_line "Launching verification audit of restored settings."
    call :write_result_line "Launching verification audit of restored settings."
)
exit /b

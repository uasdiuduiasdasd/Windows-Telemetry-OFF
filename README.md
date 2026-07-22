# Windows Telemetry OFF

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D4.svg)](https://microsoft.com)
[![Script](https://img.shields.io/badge/Language-Batch%20%2F%20CMD-4D5BCE.svg)](Windows-Telemetry-OFF.bat)
[![Architecture](https://img.shields.io/badge/Architecture-x64%20%7C%20ARM64-lightgrey.svg)]()

Interactive Batch utility to disable background telemetry, diagnostic collection tasks, and improve overall user privacy in Windows 10 and Windows 11 operating systems.

Designed with system stability in mind: the script does not remove core OS components, does not break Windows Update functionality, and provides built-in state verification and configuration restoration tools.

## Key Features

- **Resource Optimization**: Disables background telemetry services (`DiagTrack`, `dmwappushservice`).
- **Privacy Protection**: Restricts advertising ID tracking, activity feed synchronization, location services, and feedback requests.
- **Interface Streamlining**: Blocks Bing web search in the Start menu, consumer features, tips, recommendations, and widgets.
- **Task Scheduler Control**: Disables Customer Experience Improvement Program (CEIP) and Compatibility Appraiser tasks.
- **Safe & Reversible**: All registry policies, services, and scheduled tasks can be restored to default settings at any time.

## Configuration Profiles

The utility offers three operational profiles depending on the desired level of intervention:

| Feature / Setting | Safe | Balanced | Pro |
| :--- | :---: | :---: | :---: |
| Disable Activity History & Feed | Yes | Yes | Yes |
| Block Advertising ID | Yes | Yes | Yes |
| Restrict Location Tracking | Yes | Yes | Yes |
| Disable Start Menu Web Search | Yes | Yes | Yes |
| Disable Consumer Features & Suggestions | Yes | Yes | Yes |
| Disable Telemetry Services (`DiagTrack`, `dmwappushservice`) | No | Yes | Yes |
| Disable Core CEIP & Appraiser Tasks | No | Yes | Yes |
| Restrict Input Personalization | No | No | Yes |
| Disable Windows Spotlight | No | No | Yes |
| Disable Diagnostic Sync & Advanced Scheduled Tasks | No | No | Yes |

> [!NOTE]
> **Profile Recommendation**: The **Safe** profile is suitable for general use. The **Balanced** profile offers an optimal combination of privacy and stability. The **Pro** profile is intended for advanced configuration.

## System Requirements

- **Operating System**: Windows 10 (x64) or Windows 11 (x64 / ARM64).
- **Permissions**: Administrator privileges (the script automatically prompts for elevation on launch).
- **Environment**: Standard Windows Command Processor (`cmd.exe`) with UTF-8 support (`chcp 65001`).


## Quick Start

1. Download the `Windows-Telemetry-OFF.bat` file from the repository.
2. Right-click `Windows-Telemetry-OFF.bat` and run it as **Administrator**.
3. Select the desired operational mode from the interactive menu (keys `1`–`5`).
4. Restart your system after completion to apply all changes.

## Logging and Reports

Upon completion, the script generates two log files in its working directory:

- `Windows_Telemetry_OFF_Log.txt` — Detailed technical log recording every executed command and status code.
- `Windows_Telemetry_OFF_Result.txt` — Concise summary report listing successful, warning, and skipped operations.

## Restoring Default Settings

You can revert all applied policies and services back to default Windows settings using the built-in restore tool.

1. Launch `Windows-Telemetry-OFF.bat`.
2. Select option **[5] Restore default settings**.
3. Confirm the operation when prompted.

> [!IMPORTANT]
> Major Windows feature updates can reset group policies back to default system values. Use option **[4] Check current state** in the main menu to audit parameters after system updates.

## Disclaimer

Modifications to registry keys and system services are made at your own risk. Creating a System Restore point prior to executing tweaking utilities is strongly recommended.

## License

Distributed under the [MIT License](LICENSE).

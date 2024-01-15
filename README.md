# ProcessBind
**Overview**: *Watcher Script to Set Affinity and Priority of a running process with PowerShell.* <br>
**Requirements**: *PowerShell 5.0+* <br>
**Version**: *1.0* <br>
*This script will not run if you do not meet the PowerShell Version Requirements* <br>
<br>
**Detailed Description** <br>
Allows for multiple processes with the same "ExecutableName" to be identified by checking the extracted Image Path of the running process
and comparing it to a predefined Path: "ExeImagePath". If they are identical the Affinity and Priority are set by ProcessID and Logged to a time stamped file in the 'Logs' folder.
<br>
## Setup
1. Download the files and Place the folder in the directory of your choice.
2. Configure the Config.json file.
3. Run script in PowerShell with Admin.
<br>

#### Config.json Example
```json
{
  "Executables": [
    {
      "ExecutableName": "mongoose.exe",
      "ExeImagePath": "C:\\Users\\Administrator\\Desktop\\ASA Save\\webserve\\",
      "CpuCores": "2,3,4,5",
      "MemPriority": "Normal"
    },
    {
      "ExecutableName": "ArkAscendedServer.exe",
      "ExeImagePath": "N:\\asatest\\island\\ShooterGame\\Binaries\\Win64\\",
      "CpuCores": "16,17,18,19,20,21,22,23",
      "MemPriority": "High"
    },
    {
      "ExecutableName": "ArkAscendedServer.exe",
      "ExeImagePath": "O:\\asatest\\island\\ShooterGame\\Binaries\\Win64\\",
      "CpuCores": "10,11,12,13,14,15",
      "MemPriority": "High"
    }
  ],
  "MaxLogsToKeep": 2,
  "SleepDurationSeconds": 5
}
```

>[!NOTE]
>If `CpuCores` is not set or incorrect, the default is "All Cores" <br>
>If `MemPriority` is not set or incorrect, the default is "Normal" <br>
>*this follows normal windows assignments*

###### Config.json Explanation
```json
{
  "Executables": [
    {
      "ExecutableName": "Name of the Executable to Monitor with extension. (Notepad.exe) " 
      "ExeImagePath": "Full Path to the ExecutableName seperated by '\\' (copy windows path and double the backslashes)"
      "CpuCores": "Logical Cores to bind/pin. (Comma seperated list with no spaces: 0,1,2...)"
      "MemPriority": "Memory Priority Options: (High, AboveNormal, Normal, BelowNormal, Idle)"
    }
  ],
  "MaxLogsToKeep": "Will always be the number you enter +1 for the current active log. IE: setting this to 2 will keep 2 'old logs' and one 'active log'"
  "SleepDurationSeconds": "Time to wait before next check (in seconds)."
}
```

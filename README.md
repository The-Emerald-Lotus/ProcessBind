# ProcessBind
**Overview**: *Monitor and Set Affinity and/or Priority of a running process with PowerShell.* <br>
**Requirements**: *PowerShell 5.0+* <br>
**Version**: *1.0* <br>
<br>
**Detailed Description** <br>
Supports multiple processes with the same "ExecutableName" by checking the extracted 'Image Path' of the running process and comparing it to a predefined Path "ExeImagePath" in the Config.json file. 
If they are identical the Affinity and Priority are set by ProcessID and Logged to a time stamped file in the created 'Logs' folder.
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
>[!TIP]
>**Run as service**
><br>
>1. Download [NSSM](https://nssm.cc/download) and place in system Path (usually C:\\)
>2. Open Command Prompt and type `nssm install ProcessBind`
>3. Under the Application tab set the following. <br>
>+ Path: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe` <br>
>+ Startup directory: `Folder path for ProcessBindv1.0.ps1` <br>
>+ Options: `.\ProcessBindv1.0.ps1`
>4. Click Install service.
><br>
>
>**Start Service**
>1. Open Task Manager.
>2. Look for a service named `ProcessBind`, right click and select `Start`.
<br>

>[!NOTE]
>Run the powershell script before running it as a service to check your config file is correct.

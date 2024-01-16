# Check PowerShell version...
$requiredPSVersion = [Version]"5.0"

if ($PSVersionTable.PSVersion -lt $requiredPSVersion) {
    Write-Host "This script requires PowerShell version 5.0 or higher. Current version is $($PSVersionTable.PSVersion). Please upgrade PowerShell."
    Exit
}

# Get the current script directory...
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Construct the full path to the JSON config file...
$jsonConfigPath = Join-Path -Path $scriptDirectory -ChildPath "Config.json"

# Load the JSON configuration file...
$config = Get-Content -Raw -Path $jsonConfigPath | ConvertFrom-Json

# Create a "Logs" folder if it doesn't exist...
$logFolder = Join-Path -Path $scriptDirectory -ChildPath "Logs"
if (-not (Test-Path -Path $logFolder -PathType Container)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}

# Construct the full path to the log file with the timestamp...
$logFileName = "Log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
$logFilePath = Join-Path -Path $logFolder -ChildPath $logFileName

# Clean up old log files if MaxLogsToKeep is defined...
if ($config.MaxLogsToKeep -gt 0) {
    $allLogs = Get-ChildItem -Path $logFolder -Filter "Log_*.txt" | Sort-Object LastWriteTime -Descending
    $logsToDelete = $allLogs | Select-Object -Skip $config.MaxLogsToKeep
    $logsToDelete | ForEach-Object {
        Remove-Item -Path $_.FullName -Force
    }
}

# Validate the specified CPU cores in the config file...
foreach ($exeConfig in $config.Executables) {
    $validCoresRange = 0..((Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors - 1)

    $specifiedCores = $exeConfig.CpuCores -split ',' | ForEach-Object { [int]$_ }

    foreach ($core in $specifiedCores) {
        if ($core -notin $validCoresRange) {
            Write-Host "Invalid CPU core specified for $($exeConfig.ExecutableName). `nRequrested Range: $($exeConfig.CpuCores) `nValid range: $($validCoresRange -join ',')."
            Exit
        }
    }
}

# Hashtable to store the last posted message for each process ID...
$lastPostedMessages = @{}

# Calculate the CPU mask based on selected logical cores...
function CalculateAffinityMask($SelectedCores) {
    $Mask = 0
    $SelectedCores | ForEach-Object { $Mask += [Math]::Pow(2, $_) }
    return $Mask
}

# Set affinity and priority...
function SetAffinity($ProcessId, $CpuCores, $MemPriority) {
    # Extract CPU cores from the config file argument...
    if (-not $CpuCores -or $CpuCores -eq 0) {
        $validCores = 0..((Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors - 1)
        $AffinityMask = CalculateAffinityMask $validCores
    }
    else {
        $SelectedCores = $CpuCores -split ',' | ForEach-Object { [int]$_ }
        $AffinityMask = CalculateAffinityMask $SelectedCores
    }

    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($process) {
        # Check if the current affinity matches the requested affinity...
        $currentAffinity = $process.ProcessorAffinity.ToInt64()
        $requestedAffinity = [IntPtr]::new($AffinityMask).ToInt64()

        $exePath = $process.Path
        $imagePath = $process.MainModule.FileName

        if ($currentAffinity -ne $requestedAffinity) {
            # Set processor affinity if it's different...
            $process.ProcessorAffinity = [IntPtr]::new($AffinityMask)
            $message = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " - New Running Process Found. `nProcess: $($exeConfig.ExecutableName) `nProcessID: $($ProcessId) `nExpected Path: $($exeConfig.ExeImagePath) `nRunning Path: $exePath `nImage Path: $($imagePath) `nAffinity Set: $CpuCores `nBitmask: $($process.ProcessorAffinity)`n"
        }
        else {
            $message = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " - Running Process Affinity Check `nProcess: $($exeConfig.ExecutableName) (PID: $($ProcessId)) Running Path: '$($imagePath)' is set to: $CpuCores (BM: $($process.ProcessorAffinity)).`n"
        }

        # Set memory priority if it's different...
        if ($process.PriorityClass -ne $MemPriority) {
            $validMemoryPriorities = @('Normal', 'Idle', 'High', 'BelowNormal', 'AboveNormal')

            if ($validMemoryPriorities -contains $MemPriority) {
                $process.PriorityClass = $MemPriority
                $message += "Memory Priority Set: $MemPriority`n"
            }
            else {
                $defaultPriority = 'Normal'
                $process.PriorityClass = $defaultPriority
                $message += "Invalid memory priority '$MemPriority'. Defaulting to '$defaultPriority'.`n"
            }
        }

        # Check for message update...
        $messageWithoutTimestamp = $message -replace '^.*\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} - '
        if ($lastPostedMessages[$ProcessId] -ne $messageWithoutTimestamp) {
            Write-Host $message
            Add-Content -Path $logFilePath -Value $message
            $lastPostedMessages[$ProcessId] = $messageWithoutTimestamp
        }
    }
    else {
        $message = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " - Process $ProcessId not found for configuration."
        # Check for message update...
        $messageWithoutTimestamp = $message -replace '^.*\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} - '
        if ($lastPostedMessages[$ProcessId] -ne $messageWithoutTimestamp) {
            Write-Host $message
            Add-Content -Path $logFilePath -Value $message
            $lastPostedMessages[$ProcessId] = $messageWithoutTimestamp
        }
    }
}

# Continuously monitor all processes...
while ($true) {
    # Get all processes with executable path...
    $allProcesses = Get-WmiObject Win32_Process | Select-Object ProcessId, Name, ExecutablePath

    # Iterate over config file...
    foreach ($exeConfig in $config.Executables) {
        $matchFound = $false
        # Iterate over all processes...
        foreach ($process in $allProcesses) {
            if ($process.Name -eq $exeConfig.ExecutableName -and $process.ExecutablePath -eq "$($exeConfig.ExeImagePath)$($exeConfig.ExecutableName)") {
                # Call SetAffinity function with process ID and CPU cores argument...
                SetAffinity -ProcessId $process.ProcessId -CpuCores $exeConfig.CpuCores -MemPriority $exeConfig.MemPriority
                $matchFound = $true
                break
            }
        }

		# Check if a process match was found for the current configuration...
		if (-not $matchFound) {
			$message = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " - Process Not Found `nProcess: '$($exeConfig.ExecutableName)' Not Found Running At Path: '$($exeConfig.ExeImagePath)'`n"
			# Check for message update...
			$messageWithoutTimestamp = $message -replace '^.*\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} - '
			# Check if the message for this configuration was already logged...
			$configKey = "$($exeConfig.ExecutableName)-$($exeConfig.ExeImagePath)"
			if ($lastPostedMessages[$configKey] -ne $messageWithoutTimestamp) {
				Write-Host $message
				Add-Content -Path $logFilePath -Value $message
				$lastPostedMessages[$configKey] = $messageWithoutTimestamp
            }
        }
    }

    # Delay before checking again...
    Start-Sleep -Seconds $config.SleepDurationSeconds
}
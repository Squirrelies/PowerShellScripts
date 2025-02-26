function Get-FunctionName {
    param (
        [int]$StackNumber = 1
    )
    $progressPreference = 'silentlyContinue'
    return [string]$(Get-PSCallStack)[$StackNumber].FunctionName
}

function Get-EnvPath {
    param (
        [ValidateSet('Process', 'User', 'Machine')][System.EnvironmentVariableTarget]$EnvTarget = 'Process'
    )
    $progressPreference = 'silentlyContinue'
    return [Environment]::GetEnvironmentVariable("Path", $EnvTarget)
}

function Set-EnvPath {
    param (
        [Parameter(Mandatory)][string]$NewPath,
        [ValidateSet('Process', 'User', 'Machine')][System.EnvironmentVariableTarget]$EnvTarget = 'Process'
    )
    $progressPreference = 'silentlyContinue'
    $currentPath = Get-EnvPath -EnvTarget $EnvTarget

    if (!$currentPath.Contains($newPath, [System.StringComparer]::OrdinalIgnoreCase)) {
        $updatedPath = "${$currentPath};${$NewPath}"
        [Environment]::SetEnvironmentVariable("Path", $updatedPath, $envTarget)
        Write-Host "[${Get-FunctionName}] Path ${NewPath} added for scope ${$envTarget} successfully."
    }
    else {
        Write-Host "[${Get-FunctionName}] Path ${NewPath} already existed for scope ${$envTarget}, no changes committed."
    }
}

function Resize-Drive-Maximum {
    param (
        [Parameter(Mandatory)][char]$DriveLetter
    )
    $progressPreference = 'silentlyContinue'
    Write-Output "[${Get-FunctionName}] ${DriveLetter}: $($(Get-Partition -DriveLetter $DriveLetter).Size) -> $($(Get-PartitionSupportedSize -DriveLetter $DriveLetter).SizeMax)"

    Resize-Partition -DriveLetter $DriveLetter -Size $($(Get-PartitionSupportedSize -DriveLetter $DriveLetter).SizeMax)
}

function New-Shortcut {
    param (
        [Parameter(Mandatory)][string]$ShortcutPath,
        [Parameter(Mandatory)][string]$TargetPath,
        [string]$Arguments,
        [string]$WorkingDirectory,
        [string]$IconLocation,
        [string]$Hotkey
    )
    $progressPreference = 'silentlyContinue'
    Write-Output "[${Get-FunctionName}] ${ShortcutPath}"

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)

    $Shortcut.TargetPath = $TargetPath
    Write-Output "`tTargetPath: ${TargetPath}"

    if (![string]::IsNullOrWhitespace($Arguments)) {
        $Shortcut.Arguments = $Arguments
        Write-Output "`tArguments: ${Arguments}"
    }

    if (![string]::IsNullOrWhitespace($IconLocation)) {
        $Shortcut.IconLocation = $IconLocation
        Write-Output "`tIconLocation: ${IconLocation}"
    }

    if (![string]::IsNullOrWhitespace($WorkingDirectory)) {
        $Shortcut.WorkingDirectory = $WorkingDirectory
        Write-Output "`tWorkingDirectory: ${WorkingDirectory}"
    }
    else {
        $Shortcut.WorkingDirectory = $(Split-Path -Parent $Shortcut.TargetPath)
        Write-Output "`tWorkingDirectory: $(Split-Path -Parent $TargetPath)"
    }

    if (![string]::IsNullOrWhitespace($Hotkey)) {
        $Shortcut.Hotkey = $Hotkey
        Write-Output "`tHotkey: ${Hotkey}"
    }

    $Shortcut.Save()
}

function Get-FileDownload {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$OutFile,
        [int]$Retries = 3,
        [int]$RetryDelaySeconds = 5
    )
    $progressPreference = 'silentlyContinue'
    Write-Output "[${Get-FunctionName}] `"${Url}`" -> `"${OutFile}`"..."

    while ($true) {
        try {
            Invoke-WebRequest $Url -OutFile $OutFile
            break
        }
        catch {
            Write-Output "`tFailed to download `"${Url}`": ${_.Exception.Message}"
            if ($Retries -gt 0) {
                $Retries--
                Write-Output "`tRetrying after a delay of ${RetryDelaySeconds} seconds... Retries remaining: ${Retries}"
                Start-Sleep -Seconds $RetryDelaySeconds
            }
            else {
                throw $_.Exception
            }
        }
    }
}

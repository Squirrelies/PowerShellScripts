function Get-FunctionName {
    param (
        [int]$StackNumber = 1
    )
    $progressPreference = 'silentlyContinue'
    return [string](Get-PSCallStack)[$StackNumber].FunctionName
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
        Write-Output "[$(Get-FunctionName)] Path ${NewPath} added for scope ${$envTarget} successfully."
    }
    else {
        Write-Output "[$(Get-FunctionName)] Path ${NewPath} already existed for scope ${$envTarget}, no changes committed."
    }
}

function Resize-Drive-Maximum {
    param (
        [Parameter(Mandatory)][char]$DriveLetter
    )
    $progressPreference = 'silentlyContinue'
    Write-Output "[$(Get-FunctionName)] ${DriveLetter}: $($(Get-Partition -DriveLetter $DriveLetter).Size) -> $($(Get-PartitionSupportedSize -DriveLetter $DriveLetter).SizeMax)"

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
    Write-Output "[$(Get-FunctionName)] ${ShortcutPath}"

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
    Write-Output "[$(Get-FunctionName)] `"${Url}`" -> `"${OutFile}`"..."

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

function Repair-WindowsComponentStore {
    param(
        [string]$Source = $null
    )
    $progressPreference = 'silentlyContinue'
    Write-Output "[$(Get-FunctionName)] Repairing the Windows Component Store using the DISM PowerShell module..."

    if (![string]::IsNullOrWhitespace($Source)) {
        Write-Output "`tRepair-WindowsImage -RestoreHealth -StartComponentCleanup -ResetBase -Online -LimitAccess -NoRestart -Source ${Source}"
        Repair-WindowsImage -RestoreHealth -StartComponentCleanup -ResetBase -Online -LimitAccess -NoRestart -Source $Source
    }
    else {
        Write-Output "`tRepair-WindowsImage -RestoreHealth -StartComponentCleanup -ResetBase -Online -NoRestart"
        Repair-WindowsImage -RestoreHealth -StartComponentCleanup -ResetBase -Online -NoRestart
    }
}

function Install-WinGet-Program {
    param(
        [ValidateSet('Internal', 'WinGetInstallScript')][string]$Mode = "Internal"
    )
    $progressPreference = 'silentlyContinue'
    Write-Output "[$(Get-FunctionName)] Installing WinGet..."

    if ([string]::Equals($Mode, "Internal", [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Output "`tAdding `"NuGet`" package provider..."
        Install-PackageProvider -Name NuGet -Force | Out-Null
    
        Write-Output "`tInstalling module `"Microsoft.WinGet.Client`"..."
        Install-Module -Name Microsoft.WinGet.Client -Scope AllUsers -Force -Repository PSGallery | Out-Null
    
        Write-Output "`tUsing Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
        Repair-WinGetPackageManager -Force -Latest
    
        Write-Output "`tEnabling WinGet setting `"InstallerHashOverride`"..."
        Enable-WinGetSetting -Name InstallerHashOverride
    
        Write-Output "`tRemoving WinGet source `"winget`"..."
        winget source remove --name winget
        Write-Output "`tRe-adding WinGet source `"winget`" with option `"--accept-source-agreements`"..."
        winget source add winget https://cdn.winget.microsoft.com/cache -t Microsoft.PreIndexed.Package --accept-source-agreements
    
        Write-Output "`tRemoving WinGet source `"msstore`"..."
        winget source remove --name msstore
        Write-Output "`tRe-adding WinGet source `"msstore`" with option `"--accept-source-agreements`"..."
        winget source add msstore https://storeedgefd.dsx.mp.microsoft.com/v9.0 -t Microsoft.Rest --accept-source-agreements
    }
    elseif ([string]::Equals($Mode, "WinGetInstallScript", [System.StringComparison]::OrdinalIgnoreCase)) {
        Install-Script winget-install -Force
        Install-WinGet
    }
    else {
        Write-Error "[$(Get-FunctionName)] Error: You must supply a valid -Mode."
    }
}

function Update-WinGet-AllPackages {
    $progressPreference = 'silentlyContinue'
    Write-Output "[$(Get-FunctionName)] Upgrading all installed WinGet packages where updates are available..."

    Get-WinGetPackage | Where-Object IsUpdateAvailable | Update-WinGetPackage
}

function Install-WinGet-Package {
    param(
        [Parameter(Mandatory)][string]$Id,
        [ValidateSet('winget', 'msstore')][string]$Source = "winget",
        [ValidateSet('x86', 'x64', 'Arm', 'Arm64', 'Default', '')][string]$Architecture = "",
        [ValidateSet('Silent', 'Interactive', 'Default')][string]$Mode = "Silent",
        [string]$Override
    )
    $progressPreference = 'silentlyContinue'
    Write-Output "[$(Get-FunctionName)] Installing package ${Id} from ${Source}..."

    $result = $null
    if (-not [string]::IsNullOrWhiteSpace($Override) -and -not [string]::IsNullOrWhiteSpace($Architecture)) {
        Write-Output "`tUsing -Architecture ${Architecture} and -Override `"${Override}`""
        $result = Install-WinGetPackage -Id $Id -Source $Source -Architecture $Architecture -Mode $Mode -Override $Override
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Override) -and [string]::IsNullOrWhiteSpace($Architecture)) {
        Write-Output "`tUsing -Override `"${Override}`""
        $result = Install-WinGetPackage -Id $Id -Source $Source -Mode $Mode -Override $Override
    }
    elseif ([string]::IsNullOrWhiteSpace($Override) -and -not [string]::IsNullOrWhiteSpace($Architecture)) {
        Write-Output "`tUsing -Architecture ${Architecture}"
        $result = Install-WinGetPackage -Id $Id -Source $Source -Architecture $Architecture -Mode $Mode
    }
    else {
        $result = Install-WinGetPackage -Id $Id -Source $Source -Mode $Mode
    }

    if ($result.InstallerErrorCode -or $result.Status -ne "Ok") {
        Write-Output "`tInstall failed with exit code ${result.InstallerErrorCode} and status ${result.Status}. Reason: ${result.ExtendedErrorCode}"
        $result | Format-List
    }
    else {
        Write-Output "`tInstall succeeded."
    }
}

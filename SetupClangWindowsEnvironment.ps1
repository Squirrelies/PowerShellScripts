Import-Module "${PSScriptRoot}\CommonFunctions" -DisableNameChecking

[System.Uri]$llvmUrl = "https://github.com/llvm/llvm-project/releases/download/llvmorg-20.1.0-rc2/clang+llvm-20.1.0-rc2-x86_64-pc-windows-msvc.tar.xz"
[string]$llvmFileName = "clang+llvm-20.1.0-rc2-x86_64-pc-windows-msvc.tar.xz"
[string]$llvmArchiveFolderName = "clang+llvm-20.1.0-rc2-x86_64-pc-windows-msvc"

Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery
Install-WinGetPackage -Id 7zip.7zip -Architecture x64
Install-WinGetPackage -Id Microsoft.WindowsSDK.10.0.26100 -Architecture x64
Get-FileDownload -Url $llvmUrl -OutFile $llvmFileName
& "C:\Program Files\7-Zip\7z.exe" x $llvmFileName -so | & "C:\Program Files\7-Zip\7z.exe" x -si -ttar -aoa
Remove-Item $llvmFileName
Rename-Item $llvmArchiveFolderName "LLVM"
Set-EnvPath -NewPath "${PSScriptRoot}\LLVM\bin" -EnvTarget "Process"
Set-EnvPath -NewPath "${PSScriptRoot}\LLVM\bin" -EnvTarget "User"

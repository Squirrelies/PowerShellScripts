Import-Module "${PSScriptRoot}\CommonFunctions" -DisableNameChecking

[string]$msystem = "clang64"
[string]$arch = "clang-x86_64"

Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery
Install-WinGetPackage -Id MSYS2.MSYS2 -Architecture x64
& "C:\msys64\msys2_shell.cmd" -defterm -no-start -$msystem -here -c "pacman -Suy --noconfirm"
& "C:\msys64\msys2_shell.cmd" -defterm -no-start -$msystem -here -c "pacman -S --noconfirm base-devel mingw-w64-${arch}-toolchain mingw-w64-${arch}-cmake git"

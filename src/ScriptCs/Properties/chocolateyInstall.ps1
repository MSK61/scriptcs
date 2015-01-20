﻿try {
    $tools = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
    $nuget = "$env:ChocolateyInstall\ChocolateyInstall\nuget"
    $nugetPath = "$tools\nugets"

    Write-Host "Retrieving NuGet dependencies..." -ForegroundColor DarkYellow

    $dependencies = @{
        "Roslyn.Compilers.CSharp" = "1.2.20906.2";
    }

    $dependencies.GetEnumerator() | %{ &nuget install $_.Name -version $_.Value -o $nugetPath }

    Get-ChildItem $nugetPath -Filter "*.dll" -Recurse | %{ Copy-Item $_.FullName $tools -Force }
    Remove-Item $nugetPath -Recurse -Force

    if (Test-Path "$tools\..\lib") {
        Remove-Item "$tools\..\lib" -Recurse -Force
    }

    # Handle upgrade from previous packages that installed to the %AppData%/scriptcs folders.
    $oldPaths = @(
        "$env:APPDATA\scriptcs",
        "$env:LOCALAPPDATA\scriptcs"
    )

    $oldPaths | foreach {
        # Remove the old user-specific scriptcs folders.
        if (Test-Path $_) {
            Remove-Item $_ -Recurse -Force
        }

        # Remove the user-specific path that got added in previous installs.
        # There's no Uninstall-ChocolateyPath yet so we need to do it manually.
        # https://github.com/chocolatey/chocolatey/issues/97
        $envPath = $env:PATH
        if ($envPath.ToLower().Contains($_.ToLower())) {
            $userPath = Get-EnvironmentVariable -Name 'Path' -Scope "User"
            if($userPath) {
                $actualPath = [System.Collections.ArrayList]($userPath).Split(";")
                $actualPath.Remove($_)
                $newPath =  $actualPath -Join ";"
                Set-EnvironmentVariable -Name 'Path' -Value $newPath -Scope "User"
            }
        }

        Write-Host "'$_' has been removed." -ForegroundColor DarkYellow
    }
    Update-SessionEnvironment
    # End upgrade handling.

    Write-ChocolateySuccess 'scriptcs'
} catch {
    Write-ChocolateyFailure 'scriptcs' "$($_.Exception.Message)"
    throw
}
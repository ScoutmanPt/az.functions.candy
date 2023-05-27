## Original script from 4bes.nl https://4bes.nl/2020/02/13/prepare-to-create-an-azure-powershell-function-with-visual-studio-code/


if (-not ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 7) ) {
    Write-Output "this script is for Windows only"
}

# To make the script run correctly, running scripts need to be allowed.
# The next line makes that possible for this single run
Set-ExecutionPolicy Bypass -Scope Process -Force

$Registry = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

#Check if PWSH is already installed
$PwshCurrent = Get-ItemProperty $Registry | Where-Object { $_.DisplayName -match "PowerShell [0-9]-x" }
if ($PwshCurrent) {
    Write-Output "PowerShell $($PwshCurrent.DisplayVersion) has already been installed"
}
else {
    Write-output "Installing PWSH"
    # PSCore is installed by using a script created by the PowerShell team
    Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI "
}

#Try to get the installed extensions and confirm if you are running in code.
try {
    $Extensions = code --list-extensions
    Write-Output "VSCode has already been installed, checking extensions"
    $NeededExtensions = @("ms-vscode.powershell", "ms-azuretools.vscode-azurefunctions")
    $NeededExtensions | ForEach-Object {
        if ($null -eq ($Extensions | Select-String $_)) {
            code --install-extension $_
        }
        else {
            Write-Output "$_ has already been installed"
        }
    }
}
Catch {
    # VSCode is installed using a script provided by the VSCode PowerShell extension team.
    # The Azure Functions extension is installed as well.
    # If one of these component was already installed, they might be updated.
    Write-Output "Installing VSCode and Extensions"
    $URL = "https://raw.githubusercontent.com/PowerShell/vscode-powershell/master/scripts/Install-VSCode.ps1"
    Invoke-Expression "& { $(Invoke-RestMethod $URL) } -AdditionalExtensions 'ms-azuretools.vscode-azurefunctions'"

}

# A check is performed to see if chocolatey is already installed. If this errors out, it is not present and installation starts
try {
    $Null = Choco
    Write-Output "Chocolatey has already been installed"
}
Catch {
    #Chocolatey is used as a provider to install the rest of the components.
    # The script for instalation is provided by the Chocolatey team
    Start-Process PowerShell.exe -Verb RunAs "Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression" -WindowStyle Hidden
    Write-Output "Installing Chocolatey"
    Start-Sleep 30
}

# Refresh Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Some checks are done to see if software was already present
$Variables = @{
    Dotnet   = (Get-ItemProperty $Registry | Where-Object { $_.displayname -like "Microsoft .NET Core SDK *" })
    azureFunctionTools = (pwsh.exe -Command { (choco list --local-only ) | Select-String "azure-functions-core-tools" })
}
Write-output "Installing Dotnet"
#Install dotnetcore sdk latest version first
pwsh.exe -Command { choco install dotnetcore-sdk -y --no-progress }


foreach ($Var in $Variables.GetEnumerator()) {
    if ([string]::IsNullOrEmpty($Var.Value)) {
        Write-Output "Installing $($Var.Name)"
        switch ($Var.Name) {
            "Dotnet" { pwsh.exe -Command { choco install dotnetcore-sdk -y -my  } }
            "azureFunctionTools" { pwsh.exe -Command { choco install azure-functions-core-tools -y  } }
            default { "var not known" }

        }
    }
    else {
        Write-Output "$($Var.name) has already been installed"
    }
}
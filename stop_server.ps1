<#
.SYNOPSIS
Stops and deallocates the Azure VM hosting The Forest Dedicated Server to save costs.
#>

param(
    [string]$ResourceGroupName = "rg-theforest-server",
    [string]$VmName = "theforest-vm"
)

$ErrorActionPreference = "Stop"

Write-Host "Stopping and deallocating Azure VM '$VmName' (compute billing stopped)..." -ForegroundColor Yellow
az vm deallocate --resource-group $ResourceGroupName --name $VmName -o table

Write-Host "`nAzure VM '$VmName' has been deallocated successfully." -ForegroundColor Green
Write-Host "All game files, saves, and Docker configuration are preserved on disk." -ForegroundColor Green

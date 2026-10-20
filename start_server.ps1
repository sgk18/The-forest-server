<#
.SYNOPSIS
Starts the Azure VM hosting The Forest Dedicated Server.
#>

param(
    [string]$ResourceGroupName = "rg-theforest-server",
    [string]$VmName = "theforest-vm"
)

$ErrorActionPreference = "Stop"

Write-Host "Starting Azure VM '$VmName' in '$ResourceGroupName'..." -ForegroundColor Cyan
az vm start --resource-group $ResourceGroupName --name $VmName -o table

Write-Host "Retrieving Public IP address..." -ForegroundColor Cyan
$publicIp = az vm show --resource-group $ResourceGroupName --name $VmName --show-details --query "publicIps" -o tsv

Write-Host "`nThe Forest Dedicated Server is online!" -ForegroundColor Green
Write-Host "Server IP:      $publicIp" -ForegroundColor Yellow
Write-Host "Game Port:      27015 (UDP)" -ForegroundColor Yellow
Write-Host "Connect string: steam://connect/$($publicIp):27015" -ForegroundColor White

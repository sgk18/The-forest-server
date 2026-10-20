<#
.SYNOPSIS
Restarts The Forest Dedicated Server Docker container or VM.
#>

param(
    [string]$ResourceGroupName = "rg-theforest-server",
    [string]$VmName = "theforest-vm",
    [switch]$FullVmRestart
)

$ErrorActionPreference = "Stop"

if ($FullVmRestart) {
    Write-Host "Performing full Azure VM reboot for '$VmName'..." -ForegroundColor Cyan
    az vm restart --resource-group $ResourceGroupName --name $VmName -o table
} else {
    Write-Host "Restarting The Forest Docker container inside VM '$VmName'..." -ForegroundColor Cyan
    $restartCmd = "cd /opt/theforest && sudo docker compose restart && sudo docker compose ps"
    az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VmName `
        --command-id RunShellScript `
        --scripts $restartCmd `
        -o table
}

$publicIp = az vm show --resource-group $ResourceGroupName --name $VmName --show-details --query "publicIps" -o tsv
Write-Host "`nServer restart command completed!" -ForegroundColor Green
Write-Host "Server IP: $publicIp" -ForegroundColor Yellow

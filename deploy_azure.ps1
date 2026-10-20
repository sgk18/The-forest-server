<#
.SYNOPSIS
Deploys The Forest Dedicated Server Docker to Microsoft Azure.

.DESCRIPTION
This PowerShell script provisions an Azure Virtual Machine, configures Network Security Group
rules for The Forest (UDP 27015 Game, UDP 27016 Query, UDP 8766 Steam, TCP 5050 Dashboard, TCP 22 SSH),
installs Docker & Docker Compose on Ubuntu 22.04 LTS, transfers configuration and starts the server.

.PARAMETER ResourceGroupName
Azure Resource Group name (Default: "rg-theforest-server")

.PARAMETER Location
Azure Region (Default: "centralindia")

.PARAMETER VmName
Azure Virtual Machine Name (Default: "theforest-vm")

.PARAMETER VmSize
Azure VM SKU size (Default: "Standard_D2as_v4")

.PARAMETER AdminUsername
Admin user for Linux VM (Default: "azureuser")
#>

param(
    [string]$ResourceGroupName = "rg-theforest-server",
    [string]$Location = "centralindia",
    [string]$VmName = "theforest-vm",
    [string]$VmSize = "Standard_D2as_v4",
    [string]$AdminUsername = "azureuser"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       The Forest Dedicated Server - Azure Deployment        " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Verify Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    $azPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin"
    if (Test-Path $azPath) {
        $env:PATH = "$azPath;$env:PATH"
    } else {
        $azLocalPath = "$env:LOCALAPPDATA\Programs\Python\Python39\Scripts"
        if (Test-Path $azLocalPath) {
            $env:PATH = "$azLocalPath;$env:PATH"
        } else {
            Write-Error "Azure CLI ('az') is not installed or not in PATH. Please install Azure CLI."
            exit 1
        }
    }
}

# 2. Check Azure Account login (OAuth / CLI interactive login)
Write-Host "`n[Step 1/7] Verifying Azure authentication..." -ForegroundColor Cyan
try {
    $account = az account show 2>$null | ConvertFrom-Json
} catch {
    $account = $null
}

if (-not $account) {
    Write-Host "Not signed in to Azure CLI. Launching interactive OAuth login..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}

Write-Host "Connected to Azure Subscription: $($account.name)" -ForegroundColor Green
Write-Host "  Subscription ID: $($account.id)" -ForegroundColor DarkGray
Write-Host "  Tenant ID:       $($account.tenantId)" -ForegroundColor DarkGray
Write-Host "  User:            $($account.user.name)" -ForegroundColor DarkGray

# 3. Create Resource Group
Write-Host "`n[Step 2/7] Ensuring Resource Group '$ResourceGroupName' in '$Location'..." -ForegroundColor Cyan
az group create --name $ResourceGroupName --location $Location -o table

# 4. Create Virtual Machine
Write-Host "`n[Step 3/7] Provisioning Azure VM '$VmName' (Size: $VmSize, Location: $Location)..." -ForegroundColor Cyan
$vmJson = az vm create `
    --resource-group $ResourceGroupName `
    --name $VmName `
    --image Ubuntu2204 `
    --size $VmSize `
    --admin-username $AdminUsername `
    --generate-ssh-keys `
    --public-ip-sku Standard `
    -o json

$vm = $vmJson | ConvertFrom-Json
$publicIp = $vm.publicIpAddress
Write-Host "VM Provisioned successfully! Public IP: $publicIp" -ForegroundColor Green

# 5. Configure Network Security Group rules for The Forest
Write-Host "`n[Step 4/7] Configuring Network Security Group firewall rules..." -ForegroundColor Cyan
$nsgName = "$($VmName)NSG"

# Open UDP 27015 (The Forest Game Communication Port)
az network nsg rule create `
    --resource-group $ResourceGroupName `
    --nsg-name $nsgName `
    --name "AllowTheForestGameUDP" `
    --priority 1010 `
    --direction Inbound `
    --access Allow `
    --protocol Udp `
    --destination-port-ranges 27015 `
    -o table

# Open UDP 27016 (Steam Query Port)
az network nsg rule create `
    --resource-group $ResourceGroupName `
    --nsg-name $nsgName `
    --name "AllowTheForestQueryUDP" `
    --priority 1020 `
    --direction Inbound `
    --access Allow `
    --protocol Udp `
    --destination-port-ranges 27016 `
    -o table

# Open UDP 8766 (Steam Communication Port)
az network nsg rule create `
    --resource-group $ResourceGroupName `
    --nsg-name $nsgName `
    --name "AllowTheForestSteamUDP" `
    --priority 1030 `
    --direction Inbound `
    --access Allow `
    --protocol Udp `
    --destination-port-ranges 8766 `
    -o table

# Open TCP 5050 (Insights & Dashboard Web Port)
az network nsg rule create `
    --resource-group $ResourceGroupName `
    --nsg-name $nsgName `
    --name "AllowDashboardTCP" `
    --priority 1040 `
    --direction Inbound `
    --access Allow `
    --protocol Tcp `
    --destination-port-ranges 5050 `
    -o table

# Open TCP 22 (SSH Remote Management)
az network nsg rule create `
    --resource-group $ResourceGroupName `
    --nsg-name $nsgName `
    --name "AllowSSHTCP" `
    --priority 1050 `
    --direction Inbound `
    --access Allow `
    --protocol Tcp `
    --destination-port-ranges 22 `
    -o table

# 6. Install Docker & Docker Compose on VM
Write-Host "`n[Step 5/7] Installing Docker & Docker Compose on Ubuntu VM..." -ForegroundColor Cyan
$setupScript = @'
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker azureuser
sudo mkdir -p /opt/theforest/game
sudo chown -R azureuser:azureuser /opt/theforest
'@

az vm run-command invoke `
    --resource-group $ResourceGroupName `
    --name $VmName `
    --command-id RunShellScript `
    --scripts $setupScript `
    -o table

# 7. Upload compose.yml, .env, and start server
Write-Host "`n[Step 6/7] Deploying compose.yml and environment config to /opt/theforest/..." -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$composePath = Join-Path $scriptDir "compose.yml"
$envPath = Join-Path $scriptDir "default.env"
if (-not (Test-Path $envPath)) {
    $envPath = Join-Path $scriptDir ".env"
}

$composeContent = Get-Content -Raw $composePath
$envContent = Get-Content -Raw $envPath

$composeB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($composeContent))
$envB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($envContent))

$startScript = @"
echo '$composeB64' | base64 -d | sudo tee /opt/theforest/compose.yml > /dev/null
echo '$envB64' | base64 -d | sudo tee /opt/theforest/default.env > /dev/null
echo '$envB64' | base64 -d | sudo tee /opt/theforest/.env > /dev/null
cd /opt/theforest
sudo docker compose pull
sudo docker compose up -d
sudo docker compose ps
"@

az vm run-command invoke `
    --resource-group $ResourceGroupName `
    --name $VmName `
    --command-id RunShellScript `
    --scripts $startScript `
    -o table

# 8. Finished summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " The Forest Dedicated Server Deployed Successfully on Azure! " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Server Public IP:        $publicIp" -ForegroundColor Yellow
Write-Host " Game Port (UDP):         27015" -ForegroundColor Yellow
Write-Host " Query Port (UDP):        27016" -ForegroundColor Yellow
Write-Host " Steam Port (UDP):        8766" -ForegroundColor Yellow
Write-Host " Server Name:             The Forest Dedicated Server [Azure]" -ForegroundColor Cyan
Write-Host " Server Password:         ForestPlay2026!" -ForegroundColor Cyan
Write-Host " Admin Password:          ForestAdmin2026!Secure" -ForegroundColor Cyan
Write-Host " Steam Direct Connect:    steam://connect/$($publicIp):27015" -ForegroundColor White
Write-Host " SSH Host:                ssh $AdminUsername@$publicIp" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Green

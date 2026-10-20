$ErrorActionPreference = "Stop"

$composePath = "c:\projects\The-forest-server\compose.yml"
$envPath = "c:\projects\The-forest-server\default.env"

$composeContent = Get-Content -Raw $composePath
$envContent = Get-Content -Raw $envPath

$composeB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($composeContent))
$envB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($envContent))

$startScript = @"
mkdir -p /opt/theforest/game
echo '$composeB64' | base64 -d | sudo tee /opt/theforest/compose.yml > /dev/null
echo '$envB64' | base64 -d | sudo tee /opt/theforest/default.env > /dev/null
echo '$envB64' | base64 -d | sudo tee /opt/theforest/.env > /dev/null
sudo chown -R azureuser:azureuser /opt/theforest
cd /opt/theforest
sudo docker compose pull
sudo docker compose up -d
sudo docker compose ps
"@

Write-Host "Deploying container configuration to VM..."
az vm run-command invoke `
    --resource-group rg-theforest-server `
    --name theforest-vm `
    --command-id RunShellScript `
    --scripts $startScript `
    -o table

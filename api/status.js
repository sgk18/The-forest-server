import { execSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default async function statusHandler(req, res) {
  const resourceGroup = process.env.AZURE_RESOURCE_GROUP || 'rg-theforest-server';
  const vmName = process.env.AZURE_VM_NAME || 'theforest-vm';
  const serverName = process.env.SERVER_NAME || 'The Forest Dedicated Server [Azure]';
  const gamePort = parseInt(process.env.FOREST_GAME_PORT || '27015', 10);
  const queryPort = parseInt(process.env.FOREST_QUERY_PORT || '27016', 10);
  const steamPort = parseInt(process.env.FOREST_STEAM_PORT || '8766', 10);

  let vmInfo = {
    powerState: 'Unknown',
    publicIp: 'Pending Deployment',
    vmSize: process.env.AZURE_VM_SIZE || 'Standard_D2as_v4',
    location: process.env.AZURE_LOCATION || 'centralindia',
    resourceGroup
  };

  // Try checking Azure CLI for live VM details
  try {
    const output = execSync(
      `az vm show --resource-group ${resourceGroup} --name ${vmName} --show-details --query "{publicIp:publicIps, powerState:powerState, vmSize:hardwareProfile.vmSize, location:location}" -o json`,
      { encoding: 'utf8', timeout: 8000, stdio: ['pipe', 'pipe', 'ignore'] }
    );
    const parsed = JSON.parse(output);
    if (parsed) {
      vmInfo.powerState = parsed.powerState || 'Unknown';
      vmInfo.publicIp = parsed.publicIp || 'None';
      vmInfo.vmSize = parsed.vmSize || vmInfo.vmSize;
      vmInfo.location = parsed.location || vmInfo.location;
    }
  } catch (err) {
    // If VM doesn't exist yet or CLI isn't in scope
    vmInfo.powerState = 'Not Provisioned / Offline';
  }

  const isOnline = vmInfo.powerState.toLowerCase().includes('running');

  // Load insights data
  let insightsData = {};
  const insightsPath = path.join(__dirname, '..', 'schema', 'server-insights.json');
  if (fs.existsSync(insightsPath)) {
    try {
      insightsData = JSON.parse(fs.readFileSync(insightsPath, 'utf8'));
    } catch (e) {
      // ignore
    }
  }

  const responsePayload = {
    success: true,
    status: isOnline ? 'online' : 'offline',
    server: {
      name: serverName,
      gamePort,
      queryPort,
      steamPort,
      maxPlayers: parseInt(process.env.SERVER_PLAYERS || '8', 10),
      difficulty: process.env.DIFFICULTY || 'Normal',
      saveSlot: parseInt(process.env.SAVE_SLOT || '1', 10),
      passwordProtected: Boolean(process.env.SERVER_PASSWORD),
      treeRegrow: process.env.TREE_REGROW_MODE || 'on',
      buildingDestruction: process.env.ALLOW_BUILDING_DESTRUCTION || 'on'
    },
    vm: vmInfo,
    connect: {
      ip: vmInfo.publicIp,
      gamePort,
      connectString: isOnline && vmInfo.publicIp !== 'None' ? `steam://connect/${vmInfo.publicIp}:${gamePort}` : null,
      serverBrowserName: serverName
    },
    timestamp: new Date().toISOString()
  };

  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(responsePayload, null, 2));
}

import { execSync } from 'node:child_process';

export default async function controlHandler(req, res) {
  if (req.method !== 'POST') {
    res.statusCode = 405;
    res.setHeader('Content-Type', 'application/json');
    return res.end(JSON.stringify({ error: 'Method Not Allowed' }));
  }

  const resourceGroup = process.env.AZURE_RESOURCE_GROUP || 'rg-theforest-server';
  const vmName = process.env.AZURE_VM_NAME || 'theforest-vm';

  let body = {};
  if (typeof req.body === 'string') {
    try {
      body = JSON.parse(req.body);
    } catch (e) {
      body = {};
    }
  } else if (req.body && typeof req.body === 'object') {
    body = req.body;
  }

  const action = (body.action || '').toLowerCase();

  try {
    let resultMessage = '';
    if (action === 'start') {
      execSync(`az vm start --resource-group ${resourceGroup} --name ${vmName} --no-wait`, { timeout: 15000 });
      resultMessage = 'Azure VM start command dispatched successfully.';
    } else if (action === 'stop' || action === 'deallocate') {
      execSync(`az vm deallocate --resource-group ${resourceGroup} --name ${vmName} --no-wait`, { timeout: 15000 });
      resultMessage = 'Azure VM deallocate command dispatched (compute billing paused).';
    } else if (action === 'restart') {
      execSync(`az vm restart --resource-group ${resourceGroup} --name ${vmName} --no-wait`, { timeout: 15000 });
      resultMessage = 'Azure VM restart command dispatched successfully.';
    } else {
      res.statusCode = 400;
      res.setHeader('Content-Type', 'application/json');
      return res.end(JSON.stringify({ error: 'Invalid action. Supported: start, stop, restart' }));
    }

    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ success: true, message: resultMessage, action }));
  } catch (err) {
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ success: false, error: err.message }));
  }
}

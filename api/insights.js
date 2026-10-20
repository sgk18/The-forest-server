import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default async function insightsHandler(req, res) {
  const schemaPath = path.join(__dirname, '..', 'schema', 'forest-server-schema.json');
  const insightsPath = path.join(__dirname, '..', 'schema', 'server-insights.json');
  const propDefPath = path.join(__dirname, '..', 'property-definitions.json');

  let schema = null;
  let insights = null;
  let propertyDefinitions = null;

  if (fs.existsSync(schemaPath)) {
    try { schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8')); } catch (e) {}
  }
  if (fs.existsSync(insightsPath)) {
    try { insights = JSON.parse(fs.readFileSync(insightsPath, 'utf8')); } catch (e) {}
  }
  if (fs.existsSync(propDefPath)) {
    try { propertyDefinitions = JSON.parse(fs.readFileSync(propDefPath, 'utf8')); } catch (e) {}
  }

  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({
    success: true,
    schema,
    insights,
    propertyDefinitions,
    timestamp: new Date().toISOString()
  }, null, 2));
}

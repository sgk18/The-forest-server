# 🌲 The Forest Dedicated Server - Azure Deployment & Connection Guide

This guide walks you through deploying **The Forest Dedicated Server** to Microsoft Azure using Docker, configuring real environment settings, and connecting from your game client.

---

## 📋 Table of Contents
1. [Overview & Architecture](#1-overview--architecture)
2. [Prerequisites & Steam GSLT Token](#2-prerequisites--steam-gslt-token)
3. [Environment Configuration (`env/` folder)](#3-environment-configuration-env-folder)
4. [Insights & Schema Files](#4-insights--schema-files)
5. [Deploying to Azure via Azure CLI / OAuth](#5-deploying-to-azure-via-azure-cli--oauth)
6. [How to Connect to the Server in The Forest](#6-how-to-connect-to-the-server-in-the-forest)
7. [In-Game Admin Commands](#7-in-game-admin-commands)
8. [Managing the Azure VM (Start / Stop to Save Costs)](#8-managing-the-azure-vm-start--stop-to-save-costs)
9. [Web Insights Dashboard](#9-web-insights-dashboard)

---

## 1. Overview & Architecture

The Forest dedicated server is a Windows Unity application run inside an optimized Linux Docker container via **Wine 9.0** and **SteamCMD** (`jammsen/the-forest-dedicated-server:latest`).

### Network Port Map (All UDP)
| Port | Protocol | Purpose |
|------|----------|---------|
| **27015** | UDP | **Game Communication**: Main player synchronization traffic |
| **27016** | UDP | **Query Port**: Steam Master Server listing, ping & player queries |
| **8766** | UDP | **Steam Communication**: Steam peer relays and auth |
| **5050** | TCP | **Web Dashboard & Insights**: Live telemetry and power controls |
| **22** | TCP | **SSH**: Secure remote host administration |

---

## 2. Prerequisites & Steam GSLT Token

### Step 1: Create a Steam Game Server Account (Required by Steam for Dedicated Servers)
Steam requires dedicated game servers to authenticate with a **Game Server Login Token (GSLT)**:
1. Log in to your Steam account at: **[https://steamcommunity.com/dev/managegameservers](https://steamcommunity.com/dev/managegameservers)**
2. In the **AppID** field, enter: `242760` *(The Forest App ID)*.
3. In the **Memo** field, enter a name (e.g. `TheForestAzureServer`).
4. Click **Create**.
5. Copy the 32-character hexadecimal token (e.g. `A948C7B036D81F274E82A1B49C5D02E3`).
6. Paste it into `env/.env` and `default.env` at:
   ```env
   SERVER_STEAM_ACCOUNT_TOKEN=YOUR_32_HEX_TOKEN_HERE
   ```

---

## 3. Environment Configuration (`env/` folder)

Real environment files are located in `env/` and in project root:
- `env/.env`: Full unified real settings
- `env/theforest.env`: Dedicated game parameters
- `env/azure.env`: Azure subscription and cloud resource variables
- `default.env`: Docker Compose source environment

### Real Environment Values configured:
```env
# Server Identification
SERVER_NAME=The Forest Dedicated Server [Azure]
SERVER_PASSWORD=ForestPlay2026!
ADMIN_PASSWORD=ForestAdmin2026!Secure

# Game Parameters
DIFFICULTY=Normal
INIT_TYPE=Continue
SAVE_SLOT=1
SERVER_PLAYERS=8
SERVER_AUTOSAVE_INTERVAL=30
TREE_REGROW_MODE=on
ALLOW_BUILDING_DESTRUCTION=on
ENABLE_VAC=off

# Cloud Metadata
AZURE_RESOURCE_GROUP=rg-theforest-server
AZURE_VM_NAME=theforest-vm
AZURE_LOCATION=centralindia
AZURE_VM_SIZE=Standard_D2as_v4
```

> [!IMPORTANT]
> The server automatically enforces security: if passwords match `adminPasswordHere` or `serverPasswordHere`, the container aborts to prevent unauthorized takeover. The passwords above have been pre-set to secure custom values.

---

## 4. Insights & Schema Files

We provide structured schemas with real values to inspect and validate all server configurations:

1. **`schema/forest-server-schema.json`**: Formal JSON Schema (Draft 2020-12) defining every server property, data type, allowed enum, description, and environment variable mapping.
2. **`schema/server-insights.json`**: Live snapshot containing actual Azure infrastructure specs (2 vCPUs, 8GB RAM, Standard SSD), ports, game settings, and Steam AppIDs (`242760` client / `556450` server).
3. **`property-definitions.json`**: Quick key-value property dictionary mapping server properties to Docker environment variables.

---

## 5. Deploying to Azure via Azure CLI / OAuth

You can deploy the server to Azure with a single PowerShell script:

```powershell
.\deploy_azure.ps1
```

### What `deploy_azure.ps1` does automatically:
1. **Checks Azure CLI & Signs In**:
   - If not signed in, automatically prompts for browser OAuth (`az login`).
   - If already signed in, uses the active session.
2. **Provisions Resource Group & Ubuntu VM**:
   - Creates Resource Group `rg-theforest-server` in `centralindia`.
   - Creates Ubuntu 22.04 LTS VM (`theforest-vm`, `Standard_D2as_v4`).
3. **Configures NSG Firewall Rules**:
   - Opens UDP 27015 (Game), UDP 27016 (Query), UDP 8766 (Steam), TCP 5050 (Dashboard), TCP 22 (SSH).
4. **Installs Docker & Compose**:
   - Automatically installs Docker CE and sets up permissions.
5. **Transfers Config & Starts Container**:
   - Deploys `compose.yml` and `.env` to `/opt/theforest` and runs `docker compose up -d`.
6. **Outputs Server Public IP and live connection strings**.

---

## 6. How to Connect to the Server in The Forest

### Method A: Join via In-Game Server Browser (Recommended)
1. Launch **The Forest** on your PC.
2. In the main menu, click **Multiplayer** &rarr; **Join Game**.
3. Select **Dedicated (Internet)** at the top.
4. In the filter box at the top right, type:
   ```text
   The Forest Dedicated Server [Azure]
   ```
5. Click on the server name from the list.
6. When prompted for the password, enter:
   ```text
   ForestPlay2026!
   ```
7. Click **Join** and enjoy the game!

---

### Method B: Add to Steam Server Favorites (Direct IP)
If the server doesn't immediately show up in the in-game list:
1. Open the Steam desktop client.
2. In the top menu bar, click **View** &rarr; **Game Servers** (or **Servers**).
3. Switch to the **Favorites** tab.
4. Click the **+** (Add Server) button at the bottom.
5. Enter your server's Azure Public IP and query port:
   ```text
   <AZURE_PUBLIC_IP>:27016
   ```
   *(e.g., `40.80.95.157:27016`)*
6. Click **Add this address to favorites**.
7. The server will appear in your favorites list with current ping and player count.
8. Now launch **The Forest**, go to **Multiplayer** &rarr; **Join Game** &rarr; **Dedicated (Favorites)**, and click Join!

---

### Method C: One-Click Steam Protocol URL
You or your friends can paste this URL into any browser or Windows Run dialog (`Win + R`):
```text
steam://connect/<AZURE_PUBLIC_IP>:27015
```
Steam will automatically launch The Forest and connect directly to your server.

---

## 7. In-Game Admin Commands

When connected to the server, you can log in as admin and manage the game world:

1. Open the in-game chat or console.
2. Authenticate as admin:
   ```text
   /adminpassword ForestAdmin2026!Secure
   ```
3. Available administrator commands:
   - `/save`: Forces an immediate game world save to disk.
   - `/restart`: Saves the game and restarts the server process.
   - `/shutdown`: Saves the game and cleanly shuts down the server.
   - `/kick <player_name>`: Kicks a player from the server.
   - `/ban <player_name>`: Permanently bans a player.
   - `/unban <steam_id>`: Removes a player from the ban list.

---

## 8. Managing the Azure VM (Start / Stop to Save Costs)

To avoid consuming Azure credits when no one is playing, stop (deallocate) the VM:

```powershell
# Stop and deallocate VM (stops compute billing, preserves all game files & saves)
.\stop_server.ps1

# Start the server again when you want to play
.\start_server.ps1

# Restart the server Docker container
.\restart_server.ps1
```

---

## 9. Web Insights Dashboard

Launch the local web dashboard for monitoring server health, viewing real-time insights, and controlling power:

```powershell
npm start
# Or: node server.js
```
Open **[http://localhost:5050](http://localhost:5050)** in your browser to:
- Monitor live online/offline status
- Copy connection URLs with 1-click
- View the active configuration and JSON schema
- Start / Stop / Restart the Azure VM directly from the UI.

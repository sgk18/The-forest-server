#!/usr/bin/env bash
set -e

mkdir -p /opt/theforest/game

cat << 'EOF' > /opt/theforest/compose.yml
services:
  the-forest-dedicated-server:
    container_name: the-forest-dedicated-server
    image: jammsen/the-forest-dedicated-server:latest
    restart: always
    ports:
      - 8766:8766/udp
      - 27015:27015/udp
      - 27016:27016/udp
    env_file:
      - ./default.env
    volumes:
      - ./game:/theforest
EOF

cat << 'EOF' > /opt/theforest/default.env
# Container-settings
PUID=1000
PGID=1000
TZ=Asia/Kolkata
SERVER_SETTINGS_MODE=auto
FILTER_SHADER_AND_MESH_AND_WINE_DEBUG=true

# SteamCMD-settings
ALWAYS_UPDATE_ON_START=true

# Server-settings
SERVER_STEAM_ACCOUNT_TOKEN=A948C7B036D81F274E82A1B49C5D02E3
SERVER_NAME=The Forest Dedicated Server [Azure]
ADMIN_PASSWORD=ForestAdmin2026!Secure
SERVER_PASSWORD=ForestPlay2026!

# Ports
FOREST_GAME_PORT=27015
FOREST_QUERY_PORT=27016
FOREST_STEAM_PORT=8766
DASHBOARD_PORT=5050

# Azure Metadata
AZURE_TENANT_ID=06d78c90-0e5c-44b3-a8fd-6459314b6aa9
AZURE_CLIENT_ID=27e30b14-43f1-4864-8a27-cf60a5d44505
AZURE_SUBSCRIPTION_ID=0d3d4048-6e60-4719-8f43-30facb9158a6
AZURE_RESOURCE_GROUP=rg-theforest-server
AZURE_VM_NAME=theforest-vm
AZURE_LOCATION=centralindia
AZURE_VM_SIZE=Standard_D2as_v4
EOF

cp /opt/theforest/default.env /opt/theforest/.env
chown -R azureuser:azureuser /opt/theforest

cd /opt/theforest
docker compose pull
docker compose up -d
docker compose ps

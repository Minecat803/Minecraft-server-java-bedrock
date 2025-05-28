#!/bin/bash

# Set up environment
set -e

# Download Geyser and Floodgate if not present (Forge versions for NeoForge)
if [ ! -f /server/mods/geyser-forge.jar ]; then
    echo "Downloading Geyser for Forge/NeoForge..."
    wget -O /server/mods/geyser-forge.jar \
        "https://ci.opencollab.dev/job/GeyserMC/job/Geyser/job/master/lastSuccessfulBuild/artifact/bootstrap/forge/target/Geyser-Forge.jar"
fi

if [ ! -f /server/mods/floodgate-forge.jar ]; then
    echo "Downloading Floodgate for Forge/NeoForge..."
    wget -O /server/mods/floodgate-forge.jar \
        "https://ci.opencollab.dev/job/GeyserMC/job/Floodgate/job/master/lastSuccessfulBuild/artifact/forge/target/floodgate-forge.jar"
fi

# Process resource packs
RESOURCE_PACKS=$(find /server/mods -type f -iname "*.zip")
if [ -n "$RESOURCE_PACKS" ]; then
    # Use first found resource pack
    FIRST_PACK=$(echo "$RESOURCE_PACKS" | head -n1)
    PACK_NAME=$(basename "$FIRST_PACK")
    
    # Update server.properties
    if [ -f /server/server.properties.template ]; then
        # Use envsubst to replace environment variables in the template
        envsubst < /server/server.properties.template > /server/server.properties
    else
        # If no template, start with an empty file
        touch /server/server.properties
    fi
    
    # Append resource pack settings
    echo "resource-pack=mods/$PACK_NAME" >> /server/server.properties
    echo "require-resource-pack=true" >> /server/server.properties
    echo "Applied resource pack: mods/$PACK_NAME"
fi

# Process behavior packs
find /server/mods -type f -iname "manifest.json" | while read manifest; do
    if jq -e '.modules[] | select(.type == "data")' "$manifest" >/dev/null; then
        PACK_DIR=$(dirname "$manifest")
        PACK_NAME=$(basename "$PACK_DIR")
        echo "Registering behavior pack: $PACK_NAME"
        
        # Add to world behavior packs
        for world in /server/worlds/*; do
            mkdir -p "$world/behavior_packs"
            # Create a symbolic link to the behavior pack in the world's behavior_packs directory
            ln -sf "$PACK_DIR" "$world/behavior_packs/$PACK_NAME"
        done
    fi
done

# Generate mod list file for server
find /server/mods -type f \( -iname "*.jar" -o -iname "*.zip" \) | \
    awk -F/ '{print $NF}' > /server/config/mods-list.txt

# NeoForge specific setup
if [ -d /server/libraries/net/neoforged ]; then
    echo "Configuring NeoForge server"
    
    # Create mods directory if it doesn't exist
    mkdir -p /server/mods
    
    # Create user_jvm_args.txt if missing
    if [ ! -f /server/user_jvm_args.txt ]; then
        echo "-Xms2G" > /server/user_jvm_args.txt
        echo "-Xmx4G" >> /server/user_jvm_args.txt
    fi
fi

echo "Configuration complete. Starting server..."
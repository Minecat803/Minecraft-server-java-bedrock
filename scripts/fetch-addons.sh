#!/bin/bash

# Check if URL is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <addon-url> [<addon-url> ...]"
    exit 1
fi

# Define mods directory relative to script location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODS_DIR="$SCRIPT_DIR/../data/mods"

# Create mods directory if not exists
mkdir -p "$MODS_DIR"

# Download each addon
for url in "$@"; do
    echo "Downloading: $url"
    filename=$(basename "$url")
    filepath="$MODS_DIR/$filename"
    
    # Download with retries
    for i in {1..3}; do
        if wget -O "$filepath" "$url"; then
            break
        else
            echo "Download failed (attempt $i/3), retrying..."
            sleep 2
            rm -f "$filepath"
        fi
    done
    
    # Handle different file types
    case "$filename" in
        *.mcaddon|*.mcpack)
            echo "Detected Bedrock addon: $filename"
            # Leave as is - container will extract it
            ;;
        *.zip)
            # Check if it's a behavior pack
            if unzip -l "$filepath" | grep -q manifest.json; then
                echo "Extracting behavior pack: $filename"
                folder_name="${filename%.*}"
                unzip -q "$filepath" -d "$MODS_DIR/$folder_name"
                rm "$filepath"
            else
                echo "Downloaded resource pack: $filename"
            fi
            ;;
        *.jar)
            # Handle NeoForge mods
            if [[ "$url" == *"neoforge"* ]]; then
                echo "Downloaded NeoForge mod: $filename"
            else
                echo "Downloaded Java mod/plugin: $filename"
            fi
            ;;
        *)
            echo "Unknown file type: $filename"
            ;;
    esac
done

# Fix permissions
if [ "$(uname)" == "Linux" ]; then
    echo "Setting permissions"
    find "$MODS_DIR" -type d -exec chmod 755 {} \;
    find "$MODS_DIR" -type f -exec chmod 644 {} \;
fi

echo "Addons downloaded to: $MODS_DIR"
echo "Restart server to apply changes"
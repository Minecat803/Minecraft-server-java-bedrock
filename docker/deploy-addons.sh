#!/bin/bash

# Process all addons
find /server/mods -type f \( -iname "*.mcaddon" -o -iname "*.mcpack" \) -print0 | while IFS= read -r -d $'\0' file; do
    echo "Processing addon: $file"
    
    TEMP_DIR=$(mktemp -d)
    unzip -q "$file" -d "$TEMP_DIR"
    
    # Move all content to mods folder
    find "$TEMP_DIR" -type f \( -iname "*.jar" -o -iname "*.json" -o -iname "*.js" -o -iname "*.zip" \) \
        -exec mv -t /server/mods/ {} +
    
    rm -rf "$TEMP_DIR"
    rm "$file"
    echo "Addon deployed: $file"
done

# Set permissions
chown -R 1000:1000 /server/mods
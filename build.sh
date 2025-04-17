#!/bin/bash

# Directory containing .env files
ENV_DIR=".envs"
# Output JSON file
OUTPUT_FILE="Caddyfile"

# Check if the directory exists
if [ ! -d "$ENV_DIR" ]; then
    echo "Error: Directory $ENV_DIR does not exist"
    exit 1
fi

# Initialize the empty JSON file with the hosts header
echo "" > "$OUTPUT_FILE"

# Process each file in the directory
for FILE in "$ENV_DIR"/*; do
    # Skip if not a file
    if [ ! -f "$FILE" ]; then
        continue
    fi
    
    # Get the filename without path
    FILENAME=$(basename "$FILE")
    
    # Skip hidden files
    if [[ "$FILENAME" == .* ]]; then
        continue
    fi

    echo "Reading $FILENAME"

    # Source the env file to get variables
    NRTK_HOST_NAME=""
    NRTK_HTTP_SERVER_PORT=""
    
    # Read the file line by line to extract NRTK_HOST_NAME and NRTK_HTTP_SERVER_PORT
    while IFS= read -r line || [ -n "$line" ]; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | xargs)
        
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" == \#* ]]; then
            continue
        fi
        
        # Extract NRTK_HOST_NAME and NRTK_HTTP_SERVER_PORT variables
        if [[ "$line" == NRTK_HOST_NAME=* ]]; then
            NRTK_HOST_NAME="${line#NRTK_HOST_NAME=}"
            # Remove quotes if present
            NRTK_HOST_NAME="${NRTK_HOST_NAME//\"/}"
            NRTK_HOST_NAME="${NRTK_HOST_NAME//\'/}"
        elif [[ "$line" == NRTK_HTTP_SERVER_PORT=* ]]; then
            NRTK_HTTP_SERVER_PORT="${line#NRTK_HTTP_SERVER_PORT=}"
            # Remove quotes if present
            NRTK_HTTP_SERVER_PORT="${NRTK_HTTP_SERVER_PORT//\"/}"
            NRTK_HTTP_SERVER_PORT="${NRTK_HTTP_SERVER_PORT//\'/}"
        fi
    done < "$FILE"
    
    # Only add to JSON if both HOST and NRTK_HTTP_SERVER_PORT are found
    if [ -n "$NRTK_HOST_NAME" ] && [ -n "$NRTK_HTTP_SERVER_PORT" ]; then
        echo "$NRTK_HOST_NAME {" >> "$OUTPUT_FILE"
        echo "  reverse_proxy nrtk-$FILENAME:$NRTK_HTTP_SERVER_PORT" >> "$OUTPUT_FILE"
        echo "}" >> "$OUTPUT_FILE"
    fi
done

echo "JSON file generated at $OUTPUT_FILE"

echo "Starting Docker Compose"

docker compose down
docker image prune -a -f
docker compose up -d
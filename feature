#!/usr/bin/env sh

# Check if command is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <add|delete> <feature_path_or_url>"
    echo "  add <feature_path> - add feature from specified path"
    echo "  add <oci_url> - add feature from OCI registry URL (e.g., ghcr.io/devcontainers/features/python:1)"
    echo "  delete <feature_name> - remove feature by name"
    exit 1
fi

COMMAND=$1
FEATURE_ARG=$2

if [ -z "$FEATURE_ARG" ]; then
    echo "Feature path or URL is required. Usage: $0 <add|delete> <feature_path_or_url>"
    exit 1
fi

# Function to download OCI feature from GitHub repository
download_oci_feature() {
    local url="$1"
    local feature_name="$2"
    local output_dir="$3"
    
    echo "Downloading OCI feature from: $url"
    
    # Parse URL to extract registry, namespace, and tag
    local registry=$(echo "$url" | cut -d'/' -f1)
    local path_with_tag=$(echo "$url" | cut -d'/' -f2-)
    local namespace=$(echo "$path_with_tag" | rev | cut -d':' -f2- | rev)
    local tag=$(echo "$path_with_tag" | rev | cut -d':' -f1 | rev)
    
    if [ "$namespace" = "$tag" ]; then
        tag="latest"
    fi
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    
    # For ghcr.io, download directly from GitHub repository
    if [ "$registry" = "ghcr.io" ]; then
        echo "Downloading feature from GitHub repository"
        
        # Extract feature name from namespace (e.g., "devcontainers/features/python" -> "python")
        local feature_name_only=$(echo "$namespace" | sed 's|.*/||')
        
        # GitHub raw content URL for the feature
        local github_raw_url="https://raw.githubusercontent.com/devcontainers/features/main/src/$feature_name_only"
        
        echo "Downloading from GitHub: $github_raw_url"

        # Download additional files that might exist in the feature directory
        # Get the list of files from GitHub API
        local github_api_url="https://api.github.com/repos/devcontainers/features/contents/src/$feature_name_only"
        echo "Fetching file list from GitHub API: $github_api_url"
        
        local file_list
        if command -v jq >/dev/null 2>&1; then
            file_list=$(curl -sL "$github_api_url" | jq -r '.[] | select(.type == "file") | .name' 2>/dev/null)
        else
            # Fallback: try to get file list using curl and grep
            file_list=$(curl -sL "$github_api_url" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 2>/dev/null)
        fi
        
        if [ -n "$file_list" ]; then
            echo "Found files: $file_list"
            for file in $file_list; do
                if curl -sL -f "$github_raw_url/$file" -o "$temp_dir/$file"; then
                    echo "Downloaded file: $file"
                    # Make scripts executable if they have .sh extension
                    if echo "$file" | grep -q '\.sh$'; then
                        chmod +x "$temp_dir/$file"
                    fi
                fi
            done
        else
            echo "Could not fetch file list from GitHub API"
        fi
        
        # Check if we have at least the required files
        if [ ! -f "$temp_dir/devcontainer-feature.json" ]; then
            echo "Error: Required file devcontainer-feature.json not found"
            rm -rf "$temp_dir"
            return 1
        fi

    else
        echo "Unsupported registry: $registry"
        echo "Only ghcr.io is supported for OCI feature downloads"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Copy to output directory
    mkdir -p "$output_dir"
    cp -r "$temp_dir"/* "$output_dir/" 2>/dev/null || true
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo "OCI feature downloaded successfully to: $output_dir"
    return 0
}

case $COMMAND in
    add)
        # Check if argument is a URL (contains :// or starts with common registry names)
        if echo "$FEATURE_ARG" | grep -q -E '(^ghcr\.io|^docker\.io|^registry\.|://)' || echo "$FEATURE_ARG" | grep -q ':'; then
            # OCI URL case
            FEATURE_NAME=$(echo "$FEATURE_ARG" | sed 's|.*/||' | sed 's|:[^:]*$||' | tr '/' '_')
            
            if [ -z "$FEATURE_NAME" ]; then
                echo "Error: Could not extract feature name from URL: $FEATURE_ARG"
                exit 1
            fi
            
            echo "Adding OCI feature: $FEATURE_NAME from $FEATURE_ARG"
            
            # Create temporary directory for download
            TEMP_FEATURE_DIR=$(mktemp -d)
            
            # Download OCI feature
            if ! download_oci_feature "$FEATURE_ARG" "$FEATURE_NAME" "$TEMP_FEATURE_DIR"; then
                echo "Error: Failed to download OCI feature"
                rm -rf "$TEMP_FEATURE_DIR"
                exit 1
            fi
            
            # Copy to .devcontainer
            mkdir -p ".devcontainer/$FEATURE_NAME"
            cp -r "$TEMP_FEATURE_DIR"/* ".devcontainer/$FEATURE_NAME/" 2>/dev/null || true
            
            # Cleanup temp directory
            rm -rf "$TEMP_FEATURE_DIR"
            
        else
            # Local path case
            FEATURE_ABS_PATH=$(realpath "$FEATURE_ARG" 2>/dev/null || echo "$FEATURE_ARG")
            FEATURE_NAME=$(basename "$FEATURE_ABS_PATH")
            
            # Check if feature directory exists
            if [ ! -d "$FEATURE_ABS_PATH" ]; then
                echo "Feature directory '$FEATURE_ARG' not found"
                exit 1
            fi

            # Check if feature has required files
            if [ ! -f "$FEATURE_ABS_PATH/install.sh" ]; then
                echo "Feature '$FEATURE_NAME' must have install.sh file"
                exit 1
            fi

            echo "Adding local feature: $FEATURE_NAME from $FEATURE_ABS_PATH"
            cp -r "$FEATURE_ABS_PATH" ".devcontainer/$FEATURE_NAME"
        fi

        # Update devcontainer.json to include feature as local referenced feature using jq
        echo "Adding feature to devcontainer.json"
        if [ -f ".devcontainer/devcontainer.json" ]; then
            if command -v jq >/dev/null 2>&1; then
                jq --arg feature_name "$FEATURE_NAME" '.features["./\($feature_name)"] = {}' ".devcontainer/devcontainer.json" > ".devcontainer/devcontainer.json.tmp"
                mv ".devcontainer/devcontainer.json.tmp" ".devcontainer/devcontainer.json"
            else
                echo "Warning: jq not found, cannot update devcontainer.json automatically"
                echo "Please add the following to devcontainer.json features section manually:"
                echo "    \"./$FEATURE_NAME\": {}"
            fi
        fi

        # Update Dockerfile to include feature's install.sh
        echo "Adding feature installation to Dockerfile"
        if [ -f ".devcontainer/Dockerfile" ]; then
            # Create a backup of the original Dockerfile
            cp ".devcontainer/Dockerfile" ".devcontainer/Dockerfile.backup"
            
            # Find the line with "# features end" and insert the feature install command before it
            awk -v feature="$FEATURE_NAME" '
            /# features end/ {
                print "RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \\"
                print "    --mount=type=cache,target=/var/lib/apt,sharing=locked \\"
                print "    --mount=type=cache,target=/root/.cache,sharing=locked \\"
                print "    --mount=type=cache,target=/home/$USER_NAME/.cache,sharing=locked \\"
                print "    if [ -f /workspace/.devcontainer/" feature "/install.sh ]; then bash /workspace/.devcontainer/" feature "/install.sh; fi"
                print $0
                next
            }
            { print $0 }
            ' ".devcontainer/Dockerfile.backup" > ".devcontainer/Dockerfile"
            
            # Remove the backup
            rm ".devcontainer/Dockerfile.backup"
        fi

        # Update up script to include feature's compose.yaml if it exists
        if [ -f ".devcontainer/$FEATURE_NAME/compose.yaml" ]; then
            echo "Adding feature compose.yaml to up script"
            # Create a backup of the original up script
            cp ".devcontainer/up" ".devcontainer/up.backup"
            
            # Create a new up script that includes the feature's compose.yaml
            cat > ".devcontainer/up" << 'EOF'
#!/usr/bin/env sh
docker compose -f ./.devcontainer/compose.yaml \
EOF
            
            # Add all feature compose.yaml files
            for feature_dir in .devcontainer/*/; do
                if [ -f "${feature_dir}compose.yaml" ]; then
                    feature_name=$(basename "$feature_dir")
                    echo "    -f ./.devcontainer/${feature_name}/compose.yaml \\" >> ".devcontainer/up"
                fi
            done
            
            # Add the rest of the original up script
            cat >> ".devcontainer/up" << 'EOF'
    up -d --build --remove-orphans
EOF
            
            # Remove the backup
            rm ".devcontainer/up.backup"
        fi

        echo "Feature '$FEATURE_NAME' added successfully"
        ;;
        
    delete)
        # Check if feature directory exists in devcontainer
        if [ ! -d ".devcontainer/$FEATURE_ARG" ]; then
            echo "Feature '$FEATURE_ARG' not found in .devcontainer directory"
            exit 1
        fi

        # Remove feature from devcontainer.json using jq
        echo "Removing feature from devcontainer.json"
        if [ -f ".devcontainer/devcontainer.json" ]; then
            if command -v jq >/dev/null 2>&1; then
                jq --arg feature_name "$FEATURE_ARG" 'del(.features["./\($feature_name)"])' ".devcontainer/devcontainer.json" > ".devcontainer/devcontainer.json.tmp"
                mv ".devcontainer/devcontainer.json.tmp" ".devcontainer/devcontainer.json"
            else
                echo "Warning: jq not found, cannot update devcontainer.json automatically"
                echo "Please remove the following from devcontainer.json features section manually:"
                echo "    \"./$FEATURE_ARG\": {}"
            fi
        fi

        # Remove feature from devcontainer
        echo "Removing feature: $FEATURE_ARG"
        rm -rf ".devcontainer/$FEATURE_ARG"

        # Remove install.sh call from Dockerfile
        echo "Removing feature installation from Dockerfile"
        if [ -f ".devcontainer/Dockerfile" ]; then
            # Remove the 5 lines related to this feature installation
            awk -v feature="$FEATURE_ARG" '
            BEGIN { skip_next = 0 }
            /RUN --mount=type=cache,target=\/var\/cache\/apt,sharing=locked \\/ {
                # Check if this line is followed by our feature install line
                # We will check the next 3 lines and the install line
                line1 = $0
                getline line2
                getline line3
                getline line4
                getline line5
                
                # Check if line5 contains our feature install
                if (line5 ~ "if \\[ -f /workspace/.devcontainer/" feature "/install.sh \\]; then bash /workspace/.devcontainer/" feature "/install.sh; fi") {
                    # Skip all 5 lines
                    next
                } else {
                    # Print all 5 lines
                    print line1
                    print line2
                    print line3
                    print line4
                    print line5
                }
                next
            }
            { print $0 }
            ' ".devcontainer/Dockerfile" > ".devcontainer/Dockerfile.tmp"
            
            mv ".devcontainer/Dockerfile.tmp" ".devcontainer/Dockerfile"
            rm -f ".devcontainer/Dockerfile.tmp"
        fi

        # Update up script to remove feature's compose.yaml if it exists
        if [ -f ".devcontainer/up" ]; then
            echo "Removing feature compose.yaml from up script"
            # Create a backup of the original up script
            cp ".devcontainer/up" ".devcontainer/up.backup"
            
            # Create a new up script without the removed feature's compose.yaml
            cat > ".devcontainer/up" << 'EOF'
#!/usr/bin/env sh
docker compose -f ./.devcontainer/compose.yaml \
EOF
            
            # Add all remaining feature compose.yaml files
            for feature_dir in .devcontainer/*/; do
                if [ -f "${feature_dir}compose.yaml" ]; then
                    feature_name=$(basename "$feature_dir")
                    if [ "$feature_name" != "$FEATURE_ARG" ]; then
                        echo "    -f ./.devcontainer/${feature_name}/compose.yaml \\" >> ".devcontainer/up"
                    fi
                fi
            done
            
            # Add the rest of the original up script
            cat >> ".devcontainer/up" << 'EOF'
    up -d --build --remove-orphans
EOF
            
            # Remove the backup
            rm ".devcontainer/up.backup"
        fi

        echo "Feature '$FEATURE_ARG' removed successfully"
        ;;
        
    *)
        echo "Unknown command: $COMMAND"
        echo "Usage: $0 <add|delete> <feature_path_or_url>"
        exit 1
        ;;
esac

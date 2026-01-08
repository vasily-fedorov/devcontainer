#!/usr/bin/env sh

# Check if command is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <add|delete> <feature_path>"
    echo "  add <feature_path> - add feature from specified local path"
    echo "  delete <feature_name> - remove feature by name"
    exit 1
fi

COMMAND=$1
FEATURE_ARG=$2

if [ -z "$FEATURE_ARG" ]; then
    echo "Feature path is required. Usage: $0 <add|delete> <feature_path>"
    exit 1
fi

case $COMMAND in
    add)
        # Local path case only
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
                print "    --mount=type=cache,target=/home/$USERNAME/.cache,sharing=locked \\"
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
        echo "Usage: $0 <add|delete> <feature_path>"
        exit 1
        ;;
esac

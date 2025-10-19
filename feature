#!/usr/bin/env sh

# Check if command is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <add|delete> <feature>"
    exit 1
fi

COMMAND=$1
FEATURE=$2

if [ -z "$FEATURE" ]; then
    echo "Feature name is required. Usage: $0 <add|delete> <feature>"
    exit 1
fi

case $COMMAND in
    add)
        # Check if feature directory exists
        if [ ! -d "$(dirname "$0")/features/$FEATURE" ]; then
            echo "Feature '$FEATURE' not found in features directory"
            exit 1
        fi

        # Copy feature directly to .devcontainer
        echo "Adding feature: $FEATURE"
        cp -r "$(dirname "$0")/features/$FEATURE" ".devcontainer/$FEATURE"

        # Update Dockerfile to include feature's install.sh
        echo "Adding feature installation to Dockerfile"
        if [ -f ".devcontainer/Dockerfile" ]; then
            # Create a backup of the original Dockerfile
            cp ".devcontainer/Dockerfile" ".devcontainer/Dockerfile.backup"
            
            # Find the line with "# features end" and insert the feature install command before it
            awk '
            /# features end/ {
                print "RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \\"
                print "    --mount=type=cache,target=/var/lib/apt,sharing=locked \\"
                print "    --mount=type=cache,target=/root/.cache,sharing=locked \\"
                print "    --mount=type=cache,target=/home/$USER_NAME/.cache,sharing=locked \\"
                print "    if [ -f /workspace/.devcontainer/'$FEATURE'/install.sh ]; then bash /workspace/.devcontainer/'$FEATURE'/install.sh; fi"
                print $0
                next
            }
            { print $0 }
            ' ".devcontainer/Dockerfile.backup" > ".devcontainer/Dockerfile"
            
            # Remove the backup
            rm ".devcontainer/Dockerfile.backup"
        fi

        # Update up script to include feature's compose.yaml if it exists
        if [ -f ".devcontainer/$FEATURE/compose.yaml" ]; then
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

        echo "Feature '$FEATURE' added successfully"
        ;;
        
    delete)
        # Check if feature directory exists in devcontainer
        if [ ! -d ".devcontainer/$FEATURE" ]; then
            echo "Feature '$FEATURE' not found in .devcontainer directory"
            exit 1
        fi

        # Remove feature from devcontainer
        echo "Removing feature: $FEATURE"
        rm -rf ".devcontainer/$FEATURE"

        # Remove install.sh call from Dockerfile
        echo "Removing feature installation from Dockerfile"
        if [ -f ".devcontainer/Dockerfile" ]; then
            # Remove the 5 lines related to this feature installation
            awk -v feature="$FEATURE" '
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
                    if [ "$feature_name" != "$FEATURE" ]; then
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

        echo "Feature '$FEATURE' removed successfully"
        ;;
        
    *)
        echo "Unknown command: $COMMAND"
        echo "Usage: $0 <add|delete> <feature>"
        exit 1
        ;;
esac

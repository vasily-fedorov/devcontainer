#!/usr/bin/env bash
# test devcontainers/cli compatibility with devcontainers/features/python
set -e

echo "Setting up test environment..."

# Create a temporary directory for the test
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    cd /tmp
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
    if docker ps -a --format "table {{.Names}}" | grep -q "testdjango"; then
        docker rm -f testdjango >/dev/null 2>&1 || true
    fi
}

# Register cleanup on exit
trap cleanup EXIT

# Copy current project to test directory
echo "Copying project to test directory..."
cp -r . "$TEST_DIR/devcontainer"
cd "$TEST_DIR"
echo "Test directory: $TEST_DIR"

echo "Cloning features..."
git clone https://github.com/devcontainers/features.git

echo "Cloning django-helloworld..."
git clone https://github.com/vasily-fedorov/django-helloworld

echo "Initializing devcontainer..."
cd "$TEST_DIR/django-helloworld"
"$TEST_DIR/devcontainer/init" --port=8643 testdjango

# # Add python feature
echo "Adding python feature..."
"$TEST_DIR/devcontainer/feature" add "$TEST_DIR/features/src/python"

# # Build and start container
echo "Building and starting container..."
cd "$TEST_DIR/django-helloworld/"
devcontainer --workspace-folder . up

# Execute commands in container
echo "Running test commands in container..."
devcontainer exec --workspace-folder . bash -ic "
    cd /workspace
    pip install -r requirements.txt
    python manage.py migrate
    python manage.py runserver 0.0.0.0:8643 &
    sleep 3
    curl -s http://localhost:8643 | grep -q 'Hello, world!' && echo '✅ Test PASSED: Django application is working correctly' || (ech
o '❌ Test FAILED: Django application is not working as expected' && exit 1)"

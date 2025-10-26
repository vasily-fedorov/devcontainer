#!/usr/bin/env bash
set -e

echo "Setting up test environment..."

#../init --port=8641 devcontainer-test
#../feature add ../features/python
#.devcontainer/up
#.devcontainer/down
#rm -rf .devcontainer/

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
    if docker ps -a --format "table {{.Names}}" | grep -q "test-django"; then
        docker rm -f test-django >/dev/null 2>&1 || true
    fi
}

# Register cleanup on exit
trap cleanup EXIT

# Copy current project to test directory
echo "Copying project to test directory..."
cp -r . "$TEST_DIR/project"

cd "$TEST_DIR"

# Clone django-helloworld
echo "Cloning django-helloworld..."
git clone https://github.com/vasily-fedorov/django-helloworld
cd django-helloworld

# Initialize devcontainer
echo "Initializing devcontainer..."
"$TEST_DIR/project/init" --port=8643 test-django

# Add python feature
echo "Adding python feature..."
"$TEST_DIR/project/feature" add "$TEST_DIR/project/features/python"

# Build and start container
echo "Building and starting container..."
cd "$TEST_DIR/django-helloworld/"
.devcontainer/up

# Execute commands in container
echo "Running test commands in container..."
docker exec test-django bash -ic "
    cd /workspace
    pyenv activate workspace
    pip install -r requirements.txt
    python manage.py migrate
    python manage.py runserver 0.0.0.0:8643 &
    sleep 10
    curl -s http://localhost:8643 | grep -q 'Hello, world!' && echo '✅ Test PASSED: Django application is working correctly' || echo '❌ Test FAILED: Django application is not working as expected'"

#!/bin/sh
set -e

echo "=== Docker Binary Distribution ==="

# Ensure shared directory exists
mkdir -p /shared-bin

# Check if binary needs updating
NEED_UPDATE=0

if [ ! -f /shared-bin/docker ]; then
    echo "Docker binary not found in shared volume"
    NEED_UPDATE=1
else
    DIND_VERSION=$(/usr/local/bin/docker --version 2>/dev/null || echo "unknown")
    SHARED_VERSION=$(/shared-bin/docker --version 2>/dev/null || echo "unknown")
    
    if [ "$DIND_VERSION" != "$SHARED_VERSION" ]; then
        echo "Version mismatch detected:"
        echo "  DIND:   $DIND_VERSION"
        echo "  Shared: $SHARED_VERSION"
        NEED_UPDATE=1
    else
        echo "Docker binary is up to date: $DIND_VERSION"
    fi
fi

# Copy binary if needed
if [ "$NEED_UPDATE" = "1" ]; then
    echo "Copying docker binary to shared volume..."
    cp /usr/local/bin/docker /shared-bin/docker
    chmod 755 /shared-bin/docker
    UPDATED_VERSION=$(/shared-bin/docker --version)
    echo "Docker binary updated: $UPDATED_VERSION"
fi

echo "==================================="
echo ""

# Execute original entrypoint with all arguments
exec dockerd-entrypoint.sh "$@"


#!/bin/bash

# =============================================================================
# PHP Container Entrypoint
# Fixes permissions for cross-platform compatibility (Mac/WSL)
# =============================================================================

# Fix permissions for /var/www to ensure app user can read/write
# This runs on every container start to handle files created by host or root
# Run in background to avoid blocking PHP-FPM startup
if [ -d "/var/www" ]; then
    echo "=== Fixing permissions for /var/www (running in background) ==="
    
    # Detect host UID/GID from mounted volume (works on both Mac and WSL)
    # This ensures files are owned by the host user, allowing seamless access
    HOST_UID=$(stat -c '%u' /var/www 2>/dev/null || stat -f '%u' /var/www 2>/dev/null || echo "1000")
    HOST_GID=$(stat -c '%g' /var/www 2>/dev/null || stat -f '%g' /var/www 2>/dev/null || echo "1000")
    
    # Get app user UID/GID (created in Dockerfile)
    APP_UID=$(id -u app 2>/dev/null || echo "1000")
    APP_GID=$(id -g app 2>/dev/null || echo "1000")
    
    echo "Host UID/GID: $HOST_UID/$HOST_GID (detected from mounted volume)"
    echo "App UID/GID: $APP_UID/$APP_GID (from Dockerfile)"
    
    # Fix permissions in background to avoid blocking PHP-FPM startup
    # This is safe for dev environments where immediate permission fix isn't critical
    (
        # Strategy: Use host UID/GID for ownership to match host filesystem
        # This ensures files created in container are accessible from host (Mac/WSL)
        # Ensure app user can write by adding to host GID group
        
        # Ensure app user is in the host GID group for write access
        # Create group with host GID if it doesn't exist, then add app user to it
        if [ "$HOST_GID" != "$APP_GID" ]; then
            # Get group name for host GID, or create one
            HOST_GROUP=$(getent group $HOST_GID | cut -d: -f1 2>/dev/null || echo "")
            if [ -z "$HOST_GROUP" ]; then
                # Create group with host GID
                groupadd -g $HOST_GID hostgroup 2>/dev/null || true
                HOST_GROUP="hostgroup"
            fi
            # Add app user to host GID group
            usermod -a -G $HOST_GROUP app 2>/dev/null || true
        fi
        
        # Fix ownership to host UID/GID (matches host filesystem)
        chown -R $HOST_UID:$HOST_GID /var/www 2>/dev/null || true
        
        # Set directory permissions (775 = rwxrwxr-x) - allows group write
        find /var/www -type d -exec chmod 775 {} \; 2>/dev/null || true
        
        # Set file permissions (664 = rw-rw-r--) - allows group read/write
        find /var/www -type f -exec chmod 664 {} \; 2>/dev/null || true
        
        # Set setgid bit on directories for group inheritance
        # New files/dirs created will inherit group ownership
        find /var/www -type d -exec chmod g+s {} \; 2>/dev/null || true
        
        echo "=== Permissions fixed (owner: $HOST_UID:$HOST_GID) ==="
    ) &
    
    # Give permission fix a moment to start, but don't wait for completion
    sleep 1
fi

# Execute the original command (php-fpm)
exec "$@"

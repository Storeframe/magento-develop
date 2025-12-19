#!/bin/bash

# =============================================================================
# PHP Container Entrypoint
# Fixes permissions for cross-platform compatibility (Mac/WSL)
# =============================================================================

# Fix permissions for /var/www to ensure app user can read/write
# This runs on every container start to handle files created by host or root
if [ -d "/var/www" ]; then
    echo "=== Fixing permissions for /var/www ==="
    
    # Get app user UID/GID (created in Dockerfile)
    APP_UID=$(id -u app 2>/dev/null || echo "1000")
    APP_GID=$(id -g app 2>/dev/null || echo "1000")
    
    echo "Setting ownership to app:app (UID:$APP_UID, GID:$APP_GID)"
    
    # Fix ownership recursively (suppress errors for read-only mounts)
    chown -R app:app /var/www 2>/dev/null || true
    
    # Set directory permissions (775 = rwxrwxr-x)
    find /var/www -type d -exec chmod 775 {} \; 2>/dev/null || true
    
    # Set file permissions (664 = rw-rw-r--)
    find /var/www -type f -exec chmod 664 {} \; 2>/dev/null || true
    
    # Set setgid bit on directories for group inheritance
    find /var/www -type d -exec chmod g+s {} \; 2>/dev/null || true
    
    echo "=== Permissions fixed ==="
fi

# Execute the original command (php-fpm)
exec "$@"

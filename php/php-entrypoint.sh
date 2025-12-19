#!/bin/bash

# =============================================================================
# PHP Container Entrypoint
# Fixes permissions for cross-platform compatibility (Mac/WSL)
# =============================================================================

# Install/Ensure magerun is available
# This runs on every container start to ensure magerun is always available
# Run in background to avoid blocking PHP-FPM startup
(
    # Check if the actual binary file exists (not just the wrapper script)
    if [ ! -f "/root/.composer/vendor/n98/magerun2-dist/n98-magerun2" ]; then
        echo "=== Installing magerun ==="
        # Install magerun globally for root user
        composer global require n98/magerun2-dist --dev --no-interaction 2>&1 | grep -v "Warning\|Deprecated" || true
        
        # Verify installation
        if [ -f "/root/.composer/vendor/n98/magerun2-dist/n98-magerun2" ]; then
            echo "=== Magerun installed successfully ==="
            chmod +x /root/.composer/vendor/n98/magerun2-dist/n98-magerun2 2>/dev/null || true
        else
            echo "=== Warning: Magerun installation may have failed ==="
        fi
    fi
    
    # Ensure magerun2 alias exists (points to magerun wrapper)
    if [ ! -f "/usr/local/bin/magerun2" ] && [ -f "/usr/local/bin/magerun" ]; then
        ln -sf /usr/local/bin/magerun /usr/local/bin/magerun2 2>/dev/null || true
    fi
) &

# Fix permissions for /var/www to ensure app user can read/write
# This runs on every container start to handle files created by host or root
# Run in background to avoid blocking PHP-FPM startup
if [ -d "/var/www" ]; then
    echo "=== Fixing permissions for /var/www (running in background) ==="
    
    # Detect host UID/GID from mounted volume (works on both Mac and WSL)
    # This ensures files are owned by the host user, allowing seamless access
    HOST_UID=$(stat -c '%u' /var/www 2>/dev/null || stat -f '%u' /var/www 2>/dev/null || echo "1000")
    HOST_GID=$(stat -c '%g' /var/www 2>/dev/null || stat -f '%g' /var/www 2>/dev/null || echo "1000")
    
    echo "Host UID/GID: $HOST_UID/$HOST_GID (detected from mounted volume)"
    
    # Fix permissions in background to avoid blocking PHP-FPM startup
    # This is safe for dev environments where immediate permission fix isn't critical
    (
        # Strategy: Use host UID/GID for ownership + very permissive permissions (777/666)
        # This ensures files are accessible from both Windows IDE (through WSL) and container app user
        # For Windows IDE → WSL → Docker: 777/666 bypasses permission mismatches
        # that occur when Windows IDE file saves have different ownership/permissions
        
        # Fix ownership to host UID/GID (matches host filesystem)
        # This ensures files are accessible from Windows IDE through WSL
        chown -R $HOST_UID:$HOST_GID /var/www 2>/dev/null || true
        
        # Use very permissive permissions for dev environment
        # Directories: 777 (rwxrwxrwx) - full access for all
        find /var/www -type d -exec chmod 777 {} \; 2>/dev/null || true
        
        # Files: 666 (rw-rw-rw-) - read/write for all (no execute for security)
        find /var/www -type f -exec chmod 666 {} \; 2>/dev/null || true
        
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

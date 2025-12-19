#!/bin/bash

# Ensure script runs with bash (required for some features)
# If executed with 'sh', re-execute with bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Set DNSMasq Local Resolver (Mac-specific)
# WSL uses systemd-resolved or /etc/resolv.conf, DNSMasq setup differs
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sudo mkdir -p /etc/resolver
    sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'
    echo "DNSMasq resolver configured for macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux/WSL - DNSMasq typically runs on port 53, system handles resolution
    echo "DNSMasq resolver: WSL/Linux uses system DNS resolution"
    echo "Ensure DNSMasq container is running and port 53 is accessible"
else
    echo "Warning: Unknown OS type, skipping DNSMasq resolver setup"
fi

# Docker binary is now automatically managed via docker-compose volumes
# No manual binary creation needed - it's handled by dind-entrypoint.sh
echo "Docker binary is automatically managed by dind container"

# Function to Create Docker Wrappers
# Usage: create_docker_wrapper name container command user
# user: "app" for PHP container (uses app user), "root" for others
create_docker_wrapper() {
    local name="$1"
    local container="$2"
    local command="$3"
    local user="${4:-root}"  # Default to root if not specified
    local target1="/usr/local/bin/$name"
    local target2="$HOME/Docker/general/bin/$name"

    cat <<EOF | sudo tee $target1 > /dev/null
#!/bin/bash
current_dir=\$(basename "\$(pwd)")
docker exec -u$user -i -w "/var/www/\$current_dir" $container $command "\$@"
EOF

    cat <<EOF | sudo tee $target2 > /dev/null
#!/bin/bash
current_dir=\$(basename "\$(pwd)")
docker exec -u$user -i -w "/var/www/\$current_dir" $container $command "\$@"
EOF

    sudo chmod +rx $target1 $target2
}

# Create Docker Wrapper Scripts
# Format: name|container|command|user
# Commands that access /var/www use 'app' user for consistency and shared volume compatibility
# Database commands (mysql/mysqldump) use 'root' since mariadb container doesn't have 'app' user

# Ensure target directory exists
mkdir -p "$HOME/Docker/general/bin"

# Process each wrapper script definition
# Using a function to avoid array syntax issues in some shells
process_wrapper() {
    local name="$1"
    local container="$2"
    local command="$3"
    local user="${4:-root}"
    create_docker_wrapper "$name" "$container" "$command" "$user"
}

# Create wrapper scripts
# PHP container commands - use 'app' user (matches PHP-FPM user for file ownership)
process_wrapper "php" "php" "php -d memory_limit=-1" "app"
process_wrapper "composer" "php" "php -d memory_limit=-1 /usr/local/bin/composer" "app"
process_wrapper "magerun" "php" "magerun" "app"
process_wrapper "magerun2" "php" "magerun2" "app"
process_wrapper "msmtp" "php" "msmtp" "app"
# NodeJS container commands - use 'root' for Docker socket access
# Grunt exec tasks use docker to run PHP commands (requires socket access)
process_wrapper "nodejs" "nodejs" "nodejs" "root"
process_wrapper "npm" "nodejs" "npm" "root"
process_wrapper "grunt" "nodejs" "grunt" "root"
# Nginx - use 'app' for consistency
process_wrapper "nginx" "nginx" "nginx" "app"
# Database commands - mariadb doesn't have 'app' user, keep as root
process_wrapper "mysql" "mariadb" "mysql" "root"
process_wrapper "mysqldump" "mariadb" "mysqldump" "root"
# Redis - doesn't access /var/www, keep as root
process_wrapper "redis-cli" "redis" "redis-cli" "root"

echo "All configurations have been applied successfully."
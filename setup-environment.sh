#!/bin/bash

# Set DNSMasq Local Resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'

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
# PHP-related commands use 'app' user (matches Dockerfile and www.conf)
# Other commands use 'root' (check their Dockerfiles for internal user setup)
targets=(
    "php|php|php -d memory_limit=-1|app"
    "composer|php|php -d memory_limit=-1 /usr/local/bin/composer|app"
    "msmtp|php|msmtp|app"
    "nginx|nginx|nginx|root"
    "redis-cli|redis|redis-cli|root"
    "mysql|mariadb|mysql|root"
    "mysqldump|mariadb|mysqldump|root"
    "nodejs|nodejs|nodejs|root"
    "npm|nodejs|npm|root"
    "grunt|nodejs|grunt|root"
)

# Ensure target directory exists
mkdir -p "$HOME/Docker/general/bin"

for target in "${targets[@]}"; do
    IFS='|' read -r name container command user <<< "$target"
    create_docker_wrapper "$name" "$container" "$command" "$user"
done

echo "All configurations have been applied successfully."
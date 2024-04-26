#!/bin/bash

# Set DNSMasq Local Resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'

# Create Docker Binary
docker cp dind:/usr/local/bin/docker ~/Docker/magento/bin/docker

# Function to Create Docker Wrappers
create_docker_wrapper() {
    local name="$1"
    local container="$2"
    local command="$3"
    local target1="/usr/local/bin/$name"
    local target2="$HOME/Docker/magento/bin/$name"

    cat <<EOF | sudo tee $target1 > /dev/null
#!/bin/bash
current_dir=\$(basename "\$(pwd)")
docker exec -uroot -i -w "/var/www/\$current_dir" $container $command "\$@"
EOF

    cat <<EOF | sudo tee $target2 > /dev/null
#!/bin/bash
current_dir=\$(basename "\$(pwd)")
docker exec -uroot -i -w "/var/www/\$current_dir" $container $command "\$@"
EOF

    sudo chmod +rx $target1 $target2
}

# Create Docker Wrapper Scripts
targets=(
    "php|php|php -d memory_limit=-1"
    "composer|php|php -d memory_limit=-1 /usr/local/bin/composer"
    "magerun|php|magerun"
    "msmtp|php|msmtp"
    "nginx|nginx|nginx"
    "redis-cli|redis|redis-cli"
    "mysql|mariadb|mysql"
    "mysqldump|mariadb|mysqldump"
    "nodejs|nodejs|nodejs"
    "npm|nodejs|npm"
    "grunt|nodejs|grunt"
)

# Ensure target directory exists
mkdir -p "$HOME/Docker/magento/bin"

for target in "${targets[@]}"; do
    IFS='|' read -r name container command <<< "$target"
    create_docker_wrapper "$name" "$container" "$command"
done

echo "All configurations have been applied successfully."
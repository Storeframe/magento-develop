#!/bin/bash

# Set DNSMasq local resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'

# Function to create docker wrappers
create_docker_wrapper() {
    local name="$1"
    local container="$2"
    local command="$3"
    local target="/usr/local/bin/$name"

    cat <<EOF | sudo tee $target > /dev/null
#!/bin/bash
current_dir=\$(basename "\$(pwd)")
docker exec -i -w "/var/www/\$current_dir" $container $command "\$@"
EOF

    sudo chmod +x $target
}

# Create docker wrapper scripts
create_docker_wrapper "php" "php" "php -d memory_limit=-1"
create_docker_wrapper "composer" "php" "php -d memory_limit=-1 /usr/local/bin/composer"
create_docker_wrapper "dep" "php" "dep"
create_docker_wrapper "magerun" "php" "magerun"
create_docker_wrapper "msmtp" "php" "msmtp"
create_docker_wrapper "nginx" "nginx" "nginx"
create_docker_wrapper "mysql" "mariadb" "mysql"
create_docker_wrapper "mysqldump" "mariadb" "mysqldump"
create_docker_wrapper "nodejs" "nodejs" "nodejs"
create_docker_wrapper "npm" "nodejs" "npm"
create_docker_wrapper "grunt" "nodejs" "grunt"

echo "All configurations have been applied successfully."
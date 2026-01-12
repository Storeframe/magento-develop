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

# Ensure target directory exists
mkdir -p "$HOME/Docker/general/bin"

# Create PHP wrapper (php, composer, magerun, magerun2, msmtp)
# Tries php-{project} first, falls back to php
create_php_wrapper() {
    local name="$1"
    local command="$2"
    local target1="/usr/local/bin/$name"
    local target2="$HOME/Docker/general/bin/$name"

    cat <<'EOF' | sudo tee "$target1" > /dev/null
#!/bin/bash
project=$(pwd | sed "s|$HOME/Sites/||" | cut -d'/' -f1)

if docker ps --format '{{.Names}}' | grep -q "^php-${project}$"; then
    container="php-$project"
else
    container="php"
fi

EOF
    echo "docker exec -uapp -i -w \"/var/www/\$project\" \"\$container\" $command \"\$@\"" | sudo tee -a "$target1" > /dev/null

    cat <<'EOF' | sudo tee "$target2" > /dev/null
#!/bin/bash
project=$(pwd | sed "s|$HOME/Sites/||" | cut -d'/' -f1)

if docker ps --format '{{.Names}}' | grep -q "^php-${project}$"; then
    container="php-$project"
else
    container="php"
fi

EOF
    echo "docker exec -uapp -i -w \"/var/www/\$project\" \"\$container\" $command \"\$@\"" | sudo tee -a "$target2" > /dev/null

    sudo chmod +rx "$target1" "$target2"
}

# Create Node wrapper (npm, nodejs, grunt)
# Tries nodejs-{project} first, falls back to nodejs
create_node_wrapper() {
    local name="$1"
    local command="$2"
    local target1="/usr/local/bin/$name"
    local target2="$HOME/Docker/general/bin/$name"

    cat <<'EOF' | sudo tee "$target1" > /dev/null
#!/bin/bash
project=$(pwd | sed "s|$HOME/Sites/||" | cut -d'/' -f1)

if docker ps --format '{{.Names}}' | grep -q "^nodejs-${project}$"; then
    container="nodejs-$project"
else
    container="nodejs"
fi

EOF
    echo "docker exec -uroot -i -w \"/var/www/\$project\" \"\$container\" $command \"\$@\"" | sudo tee -a "$target1" > /dev/null

    cat <<'EOF' | sudo tee "$target2" > /dev/null
#!/bin/bash
project=$(pwd | sed "s|$HOME/Sites/||" | cut -d'/' -f1)

if docker ps --format '{{.Names}}' | grep -q "^nodejs-${project}$"; then
    container="nodejs-$project"
else
    container="nodejs"
fi

EOF
    echo "docker exec -uroot -i -w \"/var/www/\$project\" \"\$container\" $command \"\$@\"" | sudo tee -a "$target2" > /dev/null

    sudo chmod +rx "$target1" "$target2"
}

# Create MySQL wrapper (mysql, mysqldump)
# Tries mariadb-{project}, then postgres-{project}, falls back to mariadb
create_mysql_wrapper() {
    local name="$1"
    local command="$2"
    local pg_command="$3"
    local target1="/usr/local/bin/$name"
    local target2="$HOME/Docker/general/bin/$name"

    cat <<EOF | sudo tee "$target1" > /dev/null
#!/bin/bash
project=\$(pwd | sed "s|\$HOME/Sites/||" | cut -d'/' -f1)

if docker ps --format '{{.Names}}' | grep -q "^mariadb-\${project}\$"; then
    container="mariadb-\$project"
elif docker ps --format '{{.Names}}' | grep -q "^postgres-\${project}\$"; then
    docker exec -i "postgres-\$project" $pg_command -U root "\$@"
    exit \$?
else
    container="mariadb"
fi

docker exec -uroot -i -w "/var/www/\$project" "\$container" $command "\$@"
EOF

    cat <<EOF | sudo tee "$target2" > /dev/null
#!/bin/bash
project=\$(pwd | sed "s|\$HOME/Sites/||" | cut -d'/' -f1)

if docker ps --format '{{.Names}}' | grep -q "^mariadb-\${project}\$"; then
    container="mariadb-\$project"
elif docker ps --format '{{.Names}}' | grep -q "^postgres-\${project}\$"; then
    docker exec -i "postgres-\$project" $pg_command -U root "\$@"
    exit \$?
else
    container="mariadb"
fi

docker exec -uroot -i -w "/var/www/\$project" "\$container" $command "\$@"
EOF

    sudo chmod +rx "$target1" "$target2"
}

# Create Redis wrapper
# Tries redis-{project} first, falls back to redis
create_redis_wrapper() {
    local target1="/usr/local/bin/redis-cli"
    local target2="$HOME/Docker/general/bin/redis-cli"

    cat <<'EOF' | sudo tee "$target1" > /dev/null
#!/bin/bash
project=$(pwd | sed "s|$HOME/Sites/||" | cut -d'/' -f1)

if docker ps --format '{{.Names}}' | grep -q "^redis-${project}$"; then
    container="redis-$project"
else
    container="redis"
fi

docker exec -uroot -i -w "/var/www/$project" "$container" redis-cli "$@"
EOF

    cat <<'EOF' | sudo tee "$target2" > /dev/null
#!/bin/bash
project=$(pwd | sed "s|$HOME/Sites/||" | cut -d'/' -f1)

if docker ps --format '{{.Names}}' | grep -q "^redis-${project}$"; then
    container="redis-$project"
else
    container="redis"
fi

docker exec -uroot -i -w "/var/www/$project" "$container" redis-cli "$@"
EOF

    sudo chmod +rx "$target1" "$target2"
}

# Create Nginx wrapper
# Tries nginx-{project} first, falls back to nginx
create_nginx_wrapper() {
    local target1="/usr/local/bin/nginx"
    local target2="$HOME/Docker/general/bin/nginx"

    cat <<'EOF' | sudo tee "$target1" > /dev/null
#!/bin/bash
project=$(pwd | sed "s|$HOME/Sites/||" | cut -d'/' -f1)

if docker ps --format '{{.Names}}' | grep -q "^nginx-${project}$"; then
    container="nginx-$project"
else
    container="nginx"
fi

docker exec -uapp -i -w "/var/www/$project" "$container" nginx "$@"
EOF

    cat <<'EOF' | sudo tee "$target2" > /dev/null
#!/bin/bash
project=$(pwd | sed "s|$HOME/Sites/||" | cut -d'/' -f1)

if docker ps --format '{{.Names}}' | grep -q "^nginx-${project}$"; then
    container="nginx-$project"
else
    container="nginx"
fi

docker exec -uapp -i -w "/var/www/$project" "$container" nginx "$@"
EOF

    sudo chmod +rx "$target1" "$target2"
}

# Create wrapper scripts
echo "Creating PHP wrappers..."
create_php_wrapper "php" "php -d memory_limit=-1"
create_php_wrapper "composer" "php -d memory_limit=-1 /usr/local/bin/composer"
create_php_wrapper "magerun" "magerun"
create_php_wrapper "magerun2" "magerun2"
create_php_wrapper "msmtp" "msmtp"

echo "Creating Node wrappers..."
create_node_wrapper "nodejs" "node"
create_node_wrapper "npm" "npm"
create_node_wrapper "grunt" "grunt"

echo "Creating MySQL wrappers..."
create_mysql_wrapper "mysql" "mysql" "psql"
create_mysql_wrapper "mysqldump" "mysqldump" "pg_dump"

echo "Creating Redis wrapper..."
create_redis_wrapper

echo "Creating Nginx wrapper..."
create_nginx_wrapper

echo "All configurations have been applied successfully."

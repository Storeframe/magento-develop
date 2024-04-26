# Magento Local Docker Compose

## Directory Path (Important!)
- ~/Sites/ to store multiple Magento2 webshops separated by their respective directory (the directory name will become the domain name followed by .test)
- ~/Docker/magento to store the root of this repository
```
For example a project named johndoe situated in ~/Sites/johndoe will be accessible by johndoe.test
```

## Initialize setup-environment.sh
```
sudo sh setup-environment.sh
```
## To Start and Stop Docker Compose
```
docker compose up -d
docker compose down
```
## To Troubleshoot DNSMasq Conflict Port 53 UDP
disable use kernel networking for UDP in docker network setting
## Change Php Versions / Other Container Versions
```
nano .env # change the containers version accordingly
docker compose up -d
```

### DNSMasq Local Resolver
```
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'
```
### php (/usr/local/bin/php)
```
#!/bin/bash
current_dir=$(basename "$(pwd)")
docker exec -i -w "/var/www/$current_dir" php php -d memory_limit=-1 "$@"
```
```
sudo chmod +x /usr/local/bin/php
```
### composer (/usr/local/bin/composer)
```
#!/bin/bash
current_dir=$(basename "$(pwd)")
docker exec -i -w "/var/www/$current_dir" php php -d memory_limit=-1 /usr/local/bin/composer "$@"
```
```
sudo chmod +x /usr/local/bin/composer
```
### mysql (/usr/local/bin/mysql)
```
#!/bin/bash
current_dir=$(basename "$(pwd)")
docker exec -i -w "/var/www/$current_dir" mariadb mysql "$@"
```
```
sudo chmod +x /usr/local/bin/mysql
```
### mysqldump (/usr/local/bin/mysqldump)
```
#!/bin/bash
current_dir=$(basename "$(pwd)")
docker exec -i -w "/var/www/$current_dir" mariadb mysqldump "$@"
```
```
sudo chmod +x /usr/local/bin/mysqldump
```
# Magento Local Docker Compose

## Directory Path (Important!)
- ~/Sites/ to store multiple Magento2 webshops separated by their respective directory (the directory name will become the domain name followed by .test)
- ~/Docker/magento to store the root of this repository
```
For example a project named johndoe situated in ~/Sites/johndoe will be accessible by johndoe.test
```

## DNSMasq
```
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'
```

## Php (/usr/local/bin/php)
```
#!/bin/bash
current_dir=$(basename "$(pwd)")
docker exec -i -w "/var/www/$current_dir" php php -d memory_limit=-1 "$@"
```
```
sudo chmod +x /usr/local/bin/php
```
#!/bin/bash

# Install magerun if not present
[ -d "$HOME/.composer/vendor/n98/magerun2-dist" ] || composer global require n98/magerun2-dist --dev

# Execute the original command (php-fpm)
exec "$@"

#!/bin/bash


# Check if repo already exists
if [ -d "behat" ]; then
    echo "[ucla] Behat repo already exists"
    exit 1
fi

# Start setup
echo "[ucla] Setting up moodle for Behat"

# Clone project
git clone git@github.com:ucla/moodle.git behat
cd behat
git checkout behat
git submodule init && git submodule update
cd ..

echo "[ucla] Setting up mysql database and user"

# Set up mysql in vagrant
vagrant ssh -c "mysql --user=root --execute=\"CREATE DATABASE moodle DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;\""
vagrant ssh -c "mysql --user=root --execute=\"GRANT ALL PRIVILEGES ON moodle.* TO 'moodle'@'localhost' IDENTIFIED BY 'test'; FLUSH PRIVILEGES;\""

echo "[ucla] Preloading database with new_moodle_instance.sql"

if [ ! -e "new_moodle_instance.sql" ]; then
    "[ucla] ...but first we need to download it..."
    wget https://test.ccle.ucla.edu/vagrant/new_moodle_instance.sql
fi

vagrant ssh -c "mysql -u root -D moodle < /vagrant/new_moodle_instance.sql"

# Get inside local dir
cd behat

# Create DEV config
echo "[ucla] Creating config.php"
ln -s local/ucla/config/shared_dev_moodle-config.php config.php

# Create config private
echo "[ucla] Creating config_private.php"
sed s/"^\$CFG->wwwroot.*"/"\$CFG->wwwroot   = 'http:\/\/localhost\/behat';"/g  config_private-dist.php > config_private.php 

echo "[ucla] Done."


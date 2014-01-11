#!/bin/bash

# Check for proper usage
if [ "$#" -lt "1" ]; then 
    echo "Usage: $0 <moodle>"
    exit 1
fi

# Check if we're in a vagrant folder
if [ ! -e "Vagrantfile" ]; then 
    echo "You are not in the vagrant project root folder"
    exit 1
fi

# Check if repo already exists
if [ -d "$1" ]; then
    echo "Repo '$1' already exists"
    exit 1
fi

# Start setup
echo "> Setting up repo: $1"

# Clone project
git clone git@github.com:ucla/moodle.git $1
cd $1
git submodule init && git submodule update
cd ..

echo "> Setting up mysql database and user"

# Set up mysql in vagrant
vagrant ssh -c "mysql --user=root --execute=\"CREATE DATABASE $1 DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;\""
vagrant ssh -c "mysql --user=root --execute=\"GRANT ALL PRIVILEGES ON $1.* TO '$1'@'localhost' IDENTIFIED BY 'test'; FLUSH PRIVILEGES;\""

echo "> Setting up your moodledata dir"
vagrant ssh -c "sudo mkdir /opt/moodledata_$1 && sudo chmod -R 777 /opt/moodledata_$1"

echo "> Preloading database with new_moodle_instance.sql"

if [ ! -e "new_moodle_instance.sql" ]; then
    "> ...but first we need to download it."
    wget https://test.ccle.ucla.edu/vagrant/new_moodle_instance.sql
fi

vagrant ssh -c "mysql -u root -D $1 < /vagrant/new_moodle_instance.sql"

# Get inside local dir
cd $1

# Create DEV config
echo "> Creating config.php"
ln -s local/ucla/config/shared_dev_moodle-config.php config.php

# Create config private
echo "> Creating config_private.php"
sed s/"^\$CFG->dbname.*"/"\$CFG->dbname    = '$1';"/g config_private-dist.php | sed s/"^\$CFG->dbuser.*"/"\$CFG->dbuser    = '$1';"/g | sed s/"^\$CFG->wwwroot.*"/"\$CFG->wwwroot   = 'http:\/\/localhost:8080\/$1';"/g | sed s/"^\$CFG->dataroot.*"/"\$CFG->dataroot  = '\/opt\/moodledata_$1';"/g > config_private.php 

if [ ! "$1" == "moodle" ]; then
    echo "> Creating alias for $1"
    vagrant ssh -c "echo \"Alias /$1 '/vagrant/$1'\" | sudo tee -a /etc/httpd/conf.d/alias.conf"
    vagrant ssh -c "sudo service httpd restart"
fi

echo "> Finished."


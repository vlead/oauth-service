#!/bin/bash
# Configure the application in the deployment environment
# 1. Update the config.py file with appropriate values
# 2. Update the apache config to server via WSGI
# 3. Run the database setup scripts to setup the database

if [[ `id -u` -ne 0 ]]; then
  echo "You have to execute this script as super user!"
  exit 1;
fi

ABS_PATH_DS=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

update_app_config () {
  CONFIG_FILE="../runtime/config/flask_app_config.py"
  DB_USER="root"
  DB_PASS=$(cat db_pass.txt)
  DB_NAME="ldsdashboard"
  DB_SERVER="localhost"

  # the list of white-listed IPs for POST/PUT requests to data service
  WHITELIST_IPS="['127.0.0.1']"

  # the list of allowed domains for CORS
  ALLOWED_ORIGINS="['*']"

  echo "Updating config.py.."
  # Update parts of the DB URI
  sed -i "s/<userid>/$DB_USER/" $ABS_PATH_DS/$CONFIG_FILE
  sed -i "s/<password>/$DB_PASS/" $ABS_PATH_DS/$CONFIG_FILE
  sed -i "s/<servername>/$DB_SERVER/" $ABS_PATH_DS/$CONFIG_FILE
  sed -i "s/<db_name>/$DB_NAME/" $ABS_PATH_DS/$CONFIG_FILE
  # update SQLALCHEMY_ECHO
  sed -i "s/^SQLALCHEMY_ECHO.*$/SQLALCHEMY_ECHO = False/" $ABS_PATH_DS/$CONFIG_FILE
  # update WHITELIST_IPS
  #sed -i "s/^WHITELIST_IPS.*$/WHITELIST_IPS = $WHITELIST_IPS/" $CONFIG_FILE
  # update ALLOWED_ORIGINS
  #sed -i "s/^ALLOWED_ORIGINS.*$/ALLOWED_ORIGINS = $ALLOWED_ORIGINS/" $CONFIG_FILE

  # NOTE: this is hardcoded now..somehow the log file when dynamically created
  # is owned by root. then the app fails to run.. hence the following is
  # necessary
}

update_apache_config() {
  PROC_NAME="ldsdashboard"
  WSGI_SCRIPT="ldsdashboard.wsgi"
  APACHE_VHOST_FILE="/etc/apache2/sites-available/000-default.conf"

  sed -i "/<\/VirtualHost>/i \
    WSGIScriptAlias / $ABS_PATH_DS/$WSGI_SCRIPT
  " $APACHE_VHOST_FILE

  #sed -i '/<\/VirtualHost>/i \
  #  WSGIDaemonProcess $PROC_NAME user=www-data group=www-data threads=5
  #  WSGIScriptAlias / $ABS_PATH_DS/$WSGI_SCRIPT

  #  <Directory $ABS_PATH_DS>
  #    WSGIProcessGroup $PROC_NAME
  #    WSGIApplicationGroup %{GLOBAL}
  #    Order deny,allow
  #    Allow from all
  #  </Directory>
  #' $APACHE_VHOST_FILE

}

setup_db() {
  echo "Creating database: $DB_NAME"
  mysql -u $DB_USER -p$DB_PASS -Bse "create database $DB_NAME;"
  if [[ $? -ne 0 ]]; then
    echo "Failed to create database $DB_NAME"
    exit 1;
  fi

}

update_app_config
if [[ $? -ne 0 ]]; then
  echo "FATAL: Failed to update application flask_app_config.py"
  exit 1;
fi
update_apache_config
if [[ $? -ne 0 ]]; then
  echo "FATAL: Failed to update apache config"
  exit 1;
fi

service apache2 restart
export PYTHONPATH="/var/www"
setup_db
exit 0;

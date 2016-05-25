#!/bin/bash
#
# Copyright 2016-present Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Terminate execution on command failure
set -e

if [ "$#" -lt 2 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <sql_instance_name> <http://base_uri> (<http://alternate_base_uri>)"
  exit 1
fi

SQL_INSTANCE=$1
PHABRICATOR_BASE_URI=$2

if [ "$#" -eq 3 ]; then
  PHABRICATOR_ALTERNATE_BASE_URI=$3
else
  PHABRICATOR_ALTERNATE_BASE_URI=
fi

confirm() {
  echo "Press RETURN to continue, or ^C to cancel.";
  read -e ignored
}

GIT='git'
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LTS="Ubuntu 10.04"
ISSUE=`cat /etc/issue`
if [[ $ISSUE != Ubuntu* ]]
then
  echo "This script is intended for use on Ubuntu, but this system appears";
  echo "to be something else. Your results may vary.";
  echo
  confirm
elif [[ `expr match "$ISSUE" "$LTS"` -eq ${#LTS} ]]
then
  GIT='git-core'
fi

echo "PHABRICATOR UBUNTU INSTALL SCRIPT";
echo "This script will install Phabricator and all of its core dependencies.";
echo "Run it from the directory you want to install into.";
echo

ROOT=`pwd`
echo "Phabricator will be installed to: ${ROOT}.";

echo "Testing sudo..."
sudo true
if [ $? -ne 0 ]; then
  echo "ERROR: You must be able to sudo to run this script.";
  exit 1;
fi;

echo "Installing dependencies: git, apache, mysql, php...";
echo

set +x

# -qq No output except for errors
sudo apt-get -qq update

# Install git
sudo apt-get install -y git

# Install mysql
sudo apt-get install -y mysql-client libmysqlclient-dev

# Install Apache
sudo apt-get install -y apache2

# Install php
sudo apt-get install -y php5 php5-mysql php5-gd php5-dev php5-curl php-apc php5-cli php5-json

sudo apt-get clean

# Enable mod-rewrite
sudo a2enmod rewrite

HAVEPCNTL=`php -r "echo extension_loaded('pcntl');"`
if [ $HAVEPCNTL != "1" ]
then
  echo "Installing pcntl...";
  echo
  apt-get source php5
  PHP5=`ls -1F | grep '^php5-.*/$'`
  (cd $PHP5/ext/pcntl && phpize && ./configure && make && sudo make install)
else
  echo "pcntl already installed";
fi

line() {
  echo
  echo "============================================"
  echo "$@"
}

line "Configuring users..."
bash $DIR/configure_users.sh || exit 1

line "Configuring submodules..."
bash $DIR/configure_submodules.sh || exit 1

line "Configuring apache..."
bash $DIR/configure_apache.sh || exit 1

line "Configuring php..."
bash $DIR/configure_php.sh || exit 1

line "Configuring pygments..."
bash $DIR/configure_pygments.sh || exit 1

line "Configuring phabricator..."
bash $DIR/configure_phabricator.sh || exit 1

line "Configuring hosted repos..."
bash $DIR/configure_hosted_repos.sh || exit 1

line "Configuring gcloud..."
bash $DIR/configure_gcloud.sh || exit 1

line "Configuring sql..."
bash $DIR/configure_sql.sh $SQL_INSTANCE $PHABRICATOR_BASE_URI $PHABRICATOR_ALTERNATE_BASE_URI || exit 1

pushd phabricator >> /dev/null
line "Starting daemons"
sudo su phabricator-daemon -c "./bin/phd restart"
popd >> /dev/null

line "Restarting apache..."
sudo apachectl restart

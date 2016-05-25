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

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

# NOTE: This script assumes you are running it from a directory which contains
# arcanist/, libphutil/, and phabricator/.

pushd $DIR >> /dev/null

sudo git fetch
sudo git rebase origin/master
sudo git submodule update

popd >> /dev/null

### CYCLE WEB SERVER AND DAEMONS ###############################################

pushd phabricator >> /dev/null

# Stop daemons.
sudo su phabricator-daemon -c "./bin/phd stop"

# If running the notification server, stop it.
sudo su aphlict -c "./bin/aphlict stop"

# Stop the webserver.
sudo apachectl stop

### UPDATE SYSTEM PACKAGES ######################################################

sudo apt-get -qq update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

### UPDATE WORKING COPIES ######################################################

popd >> /dev/null

sudo $DIR/configure_submodules.sh

pushd phabricator >> /dev/null

# Upgrade the database schema.
sudo ./bin/storage upgrade --force

# Restart the webserver.
sudo apachectl start

# Restart daemons.
sudo su phabricator-daemon -c "./bin/phd start"

# If running the notification server, start it.
if hash nodejs 2>/dev/null; then
  sudo su aphlict -c "./bin/aphlict start"
fi

popd >> /dev/null

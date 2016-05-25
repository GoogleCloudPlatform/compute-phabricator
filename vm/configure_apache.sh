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

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function safe_copy {
  if [ ! -f $2 ]; then
    echo "Copying $1..."
    sudo cp $1 $2
  else
    if ! cmp --silent $1 $2; then
      echo "Overwrite existing $1 at $2?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo "Updating $2 site...";sudo cp $1 $2; break;;
          No ) exit;;
        esac
      done
    fi
  fi
}

if [ $(grep -c "^Listen 80$" /etc/apache2/ports.conf) -ne 0  ]; then
  echo "Listening port set to 8080.";
  sudo sed -i -e 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf
fi

if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
  echo "Removing default site..."
  sudo rm -f /etc/apache2/sites-enabled/000-default.conf
fi

safe_copy $DIR/sites/phabricator.conf /etc/apache2/sites-available/phabricator.conf

if [ ! -h /etc/apache2/sites-enabled/phabricator.conf ]; then
  echo "Activating phabricator site..."
  sudo ln -s /etc/apache2/sites-available/phabricator.conf /etc/apache2/sites-enabled/phabricator.conf
fi

if [ ! -d /usr/local/apache/logs ]; then
  echo "Configuring apache logs..."
  sudo mkdir -p /usr/local/apache/logs && sudo chown www-data:www-data /usr/local/apache/logs
fi

if [ ! -d /var/log/phabricator ]; then
  echo "Configuring phabricator logs..."
  sudo mkdir -p /var/log/phabricator && sudo chown www-data:www-data /var/log/phabricator
fi


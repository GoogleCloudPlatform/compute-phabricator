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

if [ "$#" -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <notifications_url>"
  exit 1
fi

NOTIFICATIONS_URL=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt-get install -y npm

ln -s /usr/bin/nodejs /usr/bin/node

pushd phabricator/support/aphlict/server >> /dev/null
sudo npm install ws
popd >> /dev/null

# Start the notification server
pushd phabricator >> /dev/null

sudo ./bin/config set notification.enabled true
sudo ./bin/config set notification.client-uri $NOTIFICATIONS_URL:22280

sudo touch /var/log/aphlict.log
sudo chmod a+w /var/log/aphlict.log
sudo chown -R aphlict:aphlict /var/tmp/aphlict/

popd >> /dev/null

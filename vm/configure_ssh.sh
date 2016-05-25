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
  echo "Usage: ${BASH_SOURCE[0]} <git_url>"
  exit 1
fi

GIT_URL=$1

if [ $(grep -c "^Port 22$" /etc/ssh/sshd_config) -ne 0  ]; then
  echo "Listening port set to 222.";
  sudo sed -i -e 's/^Port 22$/Port 222/' /etc/ssh/sshd_config

  sudo service ssh restart
fi

sudo mkdir -p /etc/libexec/

if [ ! -f /etc/libexec/phabricator-ssh-hook.sh ]; then
  sudo cp phabricator/resources/sshd/phabricator-ssh-hook.sh /etc/libexec/
fi

sudo sed -i -e "s/^VCSUSER=.*$/VCSUSER=\"git\"/" /etc/libexec/phabricator-ssh-hook.sh
sudo sed -i -e 's:^ROOT=.*$:ROOT="'$(pwd)'/phabricator":' /etc/libexec/phabricator-ssh-hook.sh
sudo chown root /etc/libexec/phabricator-ssh-hook.sh
sudo chmod 755 /etc/libexec/phabricator-ssh-hook.sh

if [ ! -f /etc/ssh/sshd_config.phabricator ]; then
  sudo cp phabricator/resources/sshd/sshd_config.phabricator.example /etc/ssh/sshd_config.phabricator
fi

sudo sed -i -e "s:^AuthorizedKeysCommand .*$:AuthorizedKeysCommand /etc/libexec/phabricator-ssh-hook.sh:" /etc/ssh/sshd_config.phabricator
sudo sed -i -e "s:^AuthorizedKeysCommandUser .*$:AuthorizedKeysCommandUser git:" /etc/ssh/sshd_config.phabricator
sudo sed -i -e "s:^AllowUsers .*$:AllowUsers git:" /etc/ssh/sshd_config.phabricator

# TODO: Turn this into a service.
sudo $(whereis -b sshd | cut -d' ' -f2) -f /etc/ssh/sshd_config.phabricator

pushd phabricator >> /dev/null
sudo ./bin/config set diffusion.ssh-host $GIT_URL
popd >> /dev/null

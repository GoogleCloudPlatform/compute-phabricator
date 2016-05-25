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

if ! cat /etc/passwd | grep "^phabricator-daemon" >> /dev/null; then
  sudo useradd -r -s /bin/bash phabricator-daemon
fi

if ! cat /etc/passwd | grep "^git" >> /dev/null; then
  sudo useradd -r -s /bin/bash git
fi

if ! cat /etc/passwd | grep "^aphlict" >> /dev/null; then
  sudo useradd -r -s /bin/bash aphlict
fi

if sudo cat /etc/shadow | grep "^git:\!:" >> /dev/null; then
  sudo sed -i -e "s/^git:\!:/git:NP:/" /etc/shadow
fi

if ! sudo cat /etc/sudoers | grep "^git ALL=(phabricator-daemon)" >> /dev/null; then
  echo "git ALL=(phabricator-daemon) SETENV: NOPASSWD: $(whereis -b git-upload-pack | cut -d' ' -f2-), $(whereis -b git-receive-pack | cut -d' ' -f2-)" | (sudo su -c 'EDITOR="tee -a" visudo')
fi

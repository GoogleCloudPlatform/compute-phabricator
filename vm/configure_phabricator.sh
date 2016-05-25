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

pushd phabricator >> /dev/null

echo "Stopping daemons..."

sudo ./bin/phd stop

sudo chown -R phabricator-daemon /var/tmp/phd

sudo ./bin/config set phabricator.timezone America/Los_Angeles
sudo ./bin/config set phabricator.show-prototypes true
sudo ./bin/config set pygments.enabled true
sudo ./bin/config set config.ignore-issues '{"mysql.ft_boolean_syntax":true, "mysql.ft_stopword_file": true, "daemons.need-restarting": true, "mysql.max_allowed_packet": true, "large-files": true, "mysql.innodb_buffer_pool_size": true}'
sudo ./bin/config set environment.append-paths '["/usr/lib/git-core/"]'
sudo ./bin/config set phd.user phabricator-daemon
sudo ./bin/config set diffusion.ssh-user git

popd >> /dev/null

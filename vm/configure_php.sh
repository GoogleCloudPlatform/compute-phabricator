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

function disable_php {
  if [ $(grep -c "^$1" /etc/php5/apache2/php.ini) = 0 ]; then
    echo "Disabling $1..."
    echo "$1 = 0" | sudo tee --append /etc/php5/apache2/php.ini
  fi
}

disable_php apc.stat
disable_php apc.slam_defense
disable_php opcache.validate_timestamps

if [ $(grep -c "^post_max_size = 8M$" /etc/php5/apache2/php.ini) -ne 0  ]; then
  echo "Increasing post max size to 32M.";
  sudo sed -i -e "s/post_max_size = 8M/post_max_size = 32M/" /etc/php5/apache2/php.ini
fi


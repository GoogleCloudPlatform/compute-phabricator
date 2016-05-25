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

if [ ! -d /mnt/git-repos ]; then
  echo "Creating hosted repo folder..."
  sudo mkdir -p /mnt/git-repos

  # TODO: This is assuming that the "first" disk mounted is the git-repos one and that its name is
  # /dev/sdb. We should be identifying the disk name from an `instances describe` call.
  sudo /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/sdb /mnt/git-repos

  sudo chown phabricator-daemon:phabricator-daemon /mnt/git-repos
fi

if [ ! -d /mnt/file-storage ]; then
  echo "Creating file storage folder..."
  sudo mkdir -p /mnt/file-storage

  # TODO: This is assuming that the "second" disk mounted is the git-repos one and that its name is
  # /dev/sdc. We should be identifying the disk name from an `instances describe` call.
  sudo /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/sdc /mnt/file-storage

  sudo chown www-data:www-data /mnt/file-storage
fi

pushd phabricator >> /dev/null

sudo ./bin/config set repository.default-local-path /mnt/git-repos
sudo ./bin/config set storage.local-disk.path /mnt/file-storage

popd >> /dev/null

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

pushd $DIR >> /dev/null
git submodule update --init --recursive
popd >> /dev/null

function clone {
  if [ ! -d $1 ]; then
    echo "Cloning $1..."
    sudo git clone $DIR/third_party/$1 $1 || exit 1
  else
    pushd $1 >> /dev/null
    sudo git fetch $DIR/third_party/$1
    popd >> /dev/null
  fi

  pushd $DIR >> /dev/null
  sha=$(git submodule status third_party/$1 | cut -d' ' -f2)
  popd >> /dev/null
  pushd $1 >> /dev/null
  echo "Checking out $1/$sha..."
  sudo git checkout -q $sha
  popd >> /dev/null
}

clone arcanist
clone libphutil
clone phabricator

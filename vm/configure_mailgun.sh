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

if [ "$#" -lt 2 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <base_uri>"
  exit 1
fi

PHABRICATOR_BASE_DOMAIN=$1
MAILGUN_APIKEY=$2

pushd phabricator >> /dev/null

echo "Configuring Phabricator for Mailgun..."

sudo ./bin/config set mailgun.api-key $MAILGUN_APIKEY
sudo ./bin/config set mailgun.domain $PHABRICATOR_BASE_DOMAIN

sudo ./bin/config set --database metamta.mail-adapter PhabricatorMailImplementationMailgunAdapter
sudo ./bin/config set --database metamta.domain $PHABRICATOR_BASE_DOMAIN
sudo ./bin/config set --database metamta.default-address noreply@$PHABRICATOR_BASE_DOMAIN

popd >> /dev/null

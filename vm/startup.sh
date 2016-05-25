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

#VM_NAME=
#DNS_NAME=
#TOP_LEVEL_DOMAIN=
#GIT_SUBDOMAIN=
#NOTIFICATIONS_SUBDOMAIN=

gcloud_instances() {
  sudo /google/google-cloud-sdk/bin/gcloud --quiet compute instances "$@"
}

VM_EXTERNAL_IP=$(gcloud_instances list | grep "\b$VM_NAME\b" | awk '{print $5}')

pushd /opt/phabricator >> /dev/null

sudo su phabricator-daemon -c "./bin/phd restart"
sudo su aphlict -c "./bin/aphlict restart"
sudo $(whereis -b sshd | cut -d' ' -f2) -f /etc/ssh/sshd_config.phabricator

gcloud_dns_records() {
  sudo /google/google-cloud-sdk/bin/gcloud --quiet dns record-sets "$@" --zone="$DNS_NAME"
}

if [[ -n "$GIT_SUBDOMAIN" || -n "$NOTIFICATIONS_SUBDOMAIN" ]]; then
  if gcloud_dns_records transaction describe >> /dev/null 2>&1; then
    gcloud_dns_records transaction abort
  fi

  gcloud_dns_records transaction start
  if [ -n "$GIT_SUBDOMAIN" ]; then
    existing=$(gcloud_dns_records list | grep "$GIT_SUBDOMAIN.$TOP_LEVEL_DOMAIN." | grep "\bA\b" | awk '{print $4}')
    if [ -n "$existing" ]; then
      gcloud_dns_records transaction remove --name="$GIT_SUBDOMAIN.$TOP_LEVEL_DOMAIN." --ttl=60 --type=A "$existing"
    fi
    gcloud_dns_records transaction add --name="$GIT_SUBDOMAIN.$TOP_LEVEL_DOMAIN." --ttl=60 --type=A $VM_EXTERNAL_IP
  fi
  if [ -n "$NOTIFICATIONS_SUBDOMAIN" ]; then
    existing=$(gcloud_dns_records list | grep "$NOTIFICATIONS_SUBDOMAIN.$TOP_LEVEL_DOMAIN." | grep "\bA\b" | awk '{print $4}')
    if [ -n "$existing" ]; then
      gcloud_dns_records transaction remove --name="$NOTIFICATIONS_SUBDOMAIN.$TOP_LEVEL_DOMAIN." --ttl=60 --type=A "$existing"
    fi
    gcloud_dns_records transaction add --name="$NOTIFICATIONS_SUBDOMAIN.$TOP_LEVEL_DOMAIN." --ttl=60 --type=A $VM_EXTERNAL_IP
  fi
  gcloud_dns_records transaction execute
fi

popd >> /dev/null

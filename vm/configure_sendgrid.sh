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

sudo apt-get install postfix libsasl2-modules -y

if [ $(grep -c "^default_transport" /etc/postfix/main.cf) -ne 0 ]; then
  echo "Disabling default_transport...";
  sed -i -e "s/^default_transport/# default_transport/" /etc/postfix/main.cf
fi

if [ $(grep -c "^relay_transport" /etc/postfix/main.cf) -ne 0 ]; then
  echo "Disabling relay_transport...";
  sed -i -e "s/^relay_transport/# relay_transport/" /etc/postfix/main.cf
fi

if [ $(grep -c "^relayhost" /etc/postfix/main.cf) -eq 0 ]; then
  echo "Adding relayhost...";
  echo "relayhost = [smtp.sendgrid.net]:2525" >> /etc/postfix/main.cf
else
  echo "Editing relayhost...";
  sed -i -e "s/^relayhost.+$/#relayhost = [smtp.sendgrid.net]:2525/" /etc/postfix/main.cf
fi

if [ $(grep -c "^smtp_tls_security_level" /etc/postfix/main.cf) -eq 0 ]; then
  echo "Adding smtp_tls_security_level...";
  echo "smtp_tls_security_level = encrypt" >> /etc/postfix/main.cf
  echo "smtp_sasl_auth_enable = yes" >> /etc/postfix/main.cf
  echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" >> /etc/postfix/main.cf
  echo "header_size_limit = 4096000" >> /etc/postfix/main.cf
  echo "smtp_sasl_security_options = noanonymous" >> /etc/postfix/main.cf
fi

if [ ! -f /etc/postfix/sasl_passwd.db ]; then
  echo "Please enter your sendmail credentials from https://app.sendgrid.com/settings/credentials"
  echo -n "Sendgrid Username: "
  read username
  echo
  echo -n "Sendgrid Password: "
  read -s password
  echo

  echo "[smtp.sendgrid.net]:2525 $username:$password" >> /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
  rm /etc/postfix/sasl_passwd
  chmod 600 /etc/postfix/sasl_passwd.db
fi

echo "Restarting postfix..."
/etc/init.d/postfix restart

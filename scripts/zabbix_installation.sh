#!/bin/bash -xe

while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done
sudo wget -O "/tmp/zabbix-release_6.0-4+ubuntu22.04_all.deb" https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bubuntu22.04_all.deb
sudo dpkg -i "/tmp/zabbix-release_6.0-4+ubuntu22.04_all.deb"
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo -S sudo apt-get -y update
sudo -S sudo apt-get install -y zabbix-server-pgsql zabbix-frontend-php php8.1-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-agent postgresql-14
cd /tmp
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD 'Z@bbix123';"
sudo -u postgres createdb -O zabbix zabbix
sudo zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
sudo sed -i 's/# DBPassword=/DBPassword=Z@bbix123/' /etc/zabbix/zabbix_server.conf
sudo touch /etc/zabbix/web/zabbix.conf.php
sudo chmod 666 /etc/zabbix/web/zabbix.conf.php

cat <<EOF > /etc/zabbix/web/zabbix.conf.php
<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']				= 'POSTGRESQL';
\$DB['SERVER']			= 'localhost';
\$DB['PORT']				= '0';
\$DB['DATABASE']			= 'zabbix';
\$DB['USER']				= 'zabbix';
\$DB['PASSWORD']			= 'Z@bbix123';

// Schema name. Used for PostgreSQL.
\$DB['SCHEMA']			= '';

// Used for TLS connection.
\$DB['ENCRYPTION']		= true;
\$DB['KEY_FILE']			= '';
\$DB['CERT_FILE']		= '';
\$DB['CA_FILE']			= '';
\$DB['VERIFY_HOST']		= false;
\$DB['CIPHER_LIST']		= '';

// Vault configuration. Used if database credentials are stored in Vault secrets manager.
\$DB['VAULT_URL']		= '';
\$DB['VAULT_DB_PATH']	= '';
\$DB['VAULT_TOKEN']		= '';

// Use IEEE754 compatible value range for 64-bit Numeric (float) history values.
// This option is enabled by default for new Zabbix installations.
// For upgraded installations, please read database upgrade notes before enabling this option.
\$DB['DOUBLE_IEEE754']	= true;

// Uncomment and set to desired values to override Zabbix hostname/IP and port.
// \$ZBX_SERVER			= '';
// \$ZBX_SERVER_PORT		= '';

\$ZBX_SERVER_NAME		= '';

\$IMAGE_FORMAT_DEFAULT	= IMAGE_FORMAT_PNG;

// Uncomment this block only if you are using Elasticsearch.
// Elasticsearch url (can be string if same url is used for all types).
//\$HISTORY['url'] = [
//	'uint' => 'http://localhost:9200',
//	'text' => 'http://localhost:9200'
//];
// Value types stored in Elasticsearch.
//\$HISTORY['types'] = ['uint', 'text'];

// Used for SAML authentication.
// Uncomment to override the default paths to SP private key, SP and IdP X.509 certificates, and to set extra settings.
//\$SSO['SP_KEY']			= 'conf/certs/sp.key';
//\$SSO['SP_CERT']			= 'conf/certs/sp.crt';
//\$SSO['IDP_CERT']		= 'conf/certs/idp.crt';
//\$SSO['SETTINGS']		= [];
EOF

sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2
# sudo sed -i 's/# PasswordAuthentication no /PasswordAuthentication yes/' /etc/ssh/sshd_config
# sudo echo -e "Z@bbix123" | passwd --stdin ubuntu
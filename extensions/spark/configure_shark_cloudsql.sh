# Copyright 2014 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Configure Hadoop on Google Cloud Platform with Hive MetaStore using Cloud SQL

set -o nounset
set -o errexit

# Declare and intialize configuration variables
CLOUDSQL_PROJECT_ID=${PROJECT}
HIVE_INSTALL_DIR=${SHARK_INSTALL_DIR}

CLOUDSQL_ACCESS_LIST_IP_ADDITION=`curl http://metadata.google.internal/computeMetadata/v1beta1/instance/network-interfaces/0/access-configs/0/external-ip`

echo "CLOUDSQL_PROJECT_ID=${CLOUDSQL_PROJECT_ID}"
echo "CLOUDSQL_IP_ADDRESS=${CLOUDSQL_IP_ADDRESS}"
echo "CLOUDSQL_ACCESS_LIST_IP_ADDITION=${CLOUDSQL_ACCESS_LIST_IP_ADDITION}"

# Get OAuth Access Token
ACCESS_TOKEN=$(curl -s "http://metadata/computeMetadata/v1/instance/service-accounts/default/token" \
    -H "X-Google-Metadata-Request: True" | \
    sed 's/\\\\\//\//g' | \
    sed 's/[{}]//g' | \
    awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | \
    sed 's/\"\:\"/\|/g' | \
    sed 's/[\,]/ /g' | \
    sed 's/\"//g' | \
    grep -w 'access_token' | \
    cut -d '|' -f 2)


# Get the Cloud SQL Instance details to parse out existing Authorized Networks;
# output response to temp file for awk'ing
curl -s --header "Authorization: Bearer ${ACCESS_TOKEN}" --header "Content-Type: application/json" https://www.googleapis.com/sql/v1beta3/projects/${CLOUDSQL_PROJECT_ID}/instances/${CLOUDSQL_INSTANCE_NAME} -X GET > jsoninputtemp.json

# Parse out Cloud SQL Authorized Networks
EXISTING_AUTHORIZED_IPS=$(awk -v RS= -F'\]|\[' '{print $4}' jsoninputtemp.json | awk 'NF')

# Remove tempfile
rm -r jsoninputtemp.json

# Set Cloud SQL Authorized Networks, add NameNode VM IP if not currently in Cloud SQL Access Control List
if echo "${EXISTING_AUTHORIZED_IPS}" | grep -q "${CLOUDSQL_ACCESS_LIST_IP_ADDITION}"; then
   #GCE Namenode VM's IP address is already in Cloud SQL access control list
   echo "Argument 4: ${CLOUDSQL_ACCESS_LIST_IP_ADDITION} containing NameNode IP address already exists in Cloud SQL Access Control list";
else
   #Add GCE Namenode VMs IP address to Cloud SQL access control list
   echo "Adding GCE Namenode VM's IP address to Cloud SQL access control list";
   #Add "/32" and quotes to IP Address to be added
   CLOUDSQL_ACCESS_LIST_IP_ADDITION='"'${CLOUDSQL_ACCESS_LIST_IP_ADDITION}/32'"'
   curl --header "Authorization: Bearer ${ACCESS_TOKEN}" --header "Content-Type: application/json" "https://www.googleapis.com/sql/v1beta3/projects/${CLOUDSQL_PROJECT_ID}/instances/${CLOUDSQL_INSTANCE_NAME}" --data "{'settings' : {'ipConfiguration' : {'enabled' : 'true', 'authorizedNetworks': [${EXISTING_AUTHORIZED_IPS},${CLOUDSQL_ACCESS_LIST_IP_ADDITION}] }}}" -X PATCH
fi

# Install the software packages necessary to run the mySQL client
sudo apt-get install --yes -f
sudo apt-get install --yes mysql-client

# Create hivemeta configuration SQL file
cat << EOF > hivemeta-config.sql
CREATE DATABASE IF NOT EXISTS hivemeta CHARSET latin1;
GRANT ALL PRIVILEGES ON hivemeta.* TO '${SHARK_USER}' IDENTIFIED BY '${SHARK_CLOUDSQL_PW}';
EOF

# Run hivemeta configuration SQL script
cat "hivemeta-config.sql" | while read LINE; do
  echo ${LINE} | mysql -h ${CLOUDSQL_IP_ADDRESS} -u "root" "-p"${CLOUDSQL_ROOT_PASS}
done

# Install the MySQL native JDBC driver
sudo apt-get install --yes libmysql-java

# Add the JDBC driver JAR file to hive's CLASSPATH for hpduser
cp /usr/share/java/mysql-connector-java.jar ${HIVE_INSTALL_DIR}/lib/
chown ${SHARK_USER}:hadoop ${HIVE_INSTALL_DIR}/lib/mysql-connector-java.jar

# Create the Hive Configuration file
cat << EOF > ${HIVE_INSTALL_DIR}/conf/hive-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
  <name>javax.jdo.option.ConnectionURL</name>
  <value>jdbc:mysql://${CLOUDSQL_IP_ADDRESS}/hivemeta?createDatabaseIfNotExist=true</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionDriverName</name>
  <value>com.mysql.jdbc.Driver</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionUserName</name>
  <value>${SHARK_USER}</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionPassword</name>
  <value>${SHARK_CLOUDSQL_PW}</value>
</property>
</configuration>
EOF


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

# Sets environment variables for YARN based Hadoop 2.x deployment

GCS_CACHE_CLEANER_LOGGER='INFO,RFA'

# URI of Hadoop tarball to be deployed. Must begin with gs:// or http(s)://
# Use 'gsutil ls gs://hadoop-dist/hadoop-*.tar.gz' to list Google supplied options
HADOOP_TARBALL_URI="gs://hadoop-dist/hadoop-2.4.1.tar.gz"

# Directory holding config files and scripts for Hadoop
HADOOP_CONF_DIR="${HADOOP_INSTALL_DIR}/etc/hadoop"

# Fraction of worker memory to be used for YARN containers
NODEMANAGER_MEMORY_FRACTION=0.8

# Connector with Hadoop AbstractFileSystem implemenation for YARN
GCS_CONNECTOR_JAR='https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-1.3.1-hadoop2.jar'

DATASTORE_CONNECTOR_JAR='https://storage.googleapis.com/hadoop-lib/datastore/datastore-connector-0.14.9-hadoop2.jar'

BIGQUERY_CONNECTOR_JAR='https://storage.googleapis.com/hadoop-lib/bigquery/bigquery-connector-0.5.0-hadoop2.jar'


HDFS_DATA_DIRS_PERM='700'

# 8088 for YARN, 50070 for HDFS.
MASTER_UI_PORTS=('8088' '50070')

# Use Hadoop 2 specific configuration templates.
if [[ -n "${BDUTIL_DIR}" ]]; then
  UPLOAD_FILES=($(find ${BDUTIL_DIR}/conf/hadoop2 -name '*template.xml'))
  UPLOAD_FILES+=(${BDUTIL_DIR}/libexec/hadoop_helpers.sh)
fi

# Use Hadoop 2 specific start scripts
COMMAND_GROUPS+=(
  'deploy_start2:
    libexec/start_hadoop2.sh'
)

COMMAND_STEPS=(
  "deploy-ssh-master-setup,*"
  'deploy-core-setup,deploy-core-setup'
  "*,deploy-ssh-worker-setup"
  "deploy-master-nfs-setup,*",
  "deploy-client-nfs-setup,deploy-client-nfs-setup",
  'deploy_start2,*'
)

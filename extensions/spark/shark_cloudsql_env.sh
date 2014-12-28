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

# This file contains environment-variable overrides to be used in conjunction
# with bdutil_env.sh in order to deploy a Hadoop + Spark cluster.
# Usage: ./bdutil deploy -e extensions/spark/shark_cloudsql_env.sh

# URIs of tarballs to install.
SCALA_TARBALL_URI='gs://spark-dist/scala-2.10.3.tgz'
SPARK_HADOOP1_TARBALL_URI='gs://spark-dist/spark-0.9.1-bin-hadoop1.tgz'
SHARK_HADOOP1_TARBALL_URI='gs://spark-dist/shark-0.9.1-bin-hadoop1.tgz'
SPARK_HADOOP2_TARBALL_URI='gs://spark-dist/spark-0.9.1-bin-hadoop2.tgz'
SHARK_HADOOP2_TARBALL_URI='gs://spark-dist/shark-0.9.1-bin-hadoop2.tgz'

# Directory on each VM in which to install each package.
SCALA_INSTALL_DIR='/home/hadoop/scala-install'
SPARK_INSTALL_DIR='/home/hadoop/spark-install'
SHARK_INSTALL_DIR='/home/hadoop/shark-install'

# Worker memory to provide in spark-env.sh.
SPARK_WORKER_MEMORY_FRACTION='0.8'

# Default memory per Spark executor, as a fraction of total physical memory;
# used for default spark-shell if not overridden with a -D option. Can be used
# to accommodate multiple spark-shells on a single cluster, e.g. if this value
# is set to half the value of SPARK_WORKER_MEMORY_FRACTION then two sets of
# executors can run simultaneously. However, in such a case, then at the time
# of starting 'spark-shell' or 'shark' you must specify fewer cores, e.g.:
# SPARK_JAVA_OPTS="-Dspark.cores.max=4" shark
# SPARK_JAVA_OPTS="-Dspark.cores.max=4" spark-shell
SPARK_EXECUTOR_MEMORY_FRACTION='0.8'

# Max memory to use by the single Spark daemon process on each node; may need to
# increase when using larger clusters. Expressed as a fraction of total physical
# memory.
SPARK_DAEMON_MEMORY_FRACTION='0.15'

# Value to give Shark indicating the amount of Spark worker memory
# available/usable by Shark per worker. Expressed as a fraction of total
# physical memory.
SHARK_MEM_FRACTION='0.8'

# Variables for configuring CloudSQL for Hive.
# CLOUDSQL_INSTANCE_NAME='<your cloudsql instance>'
# CLOUDSQL_IP_ADDRESS='<your cloudsql external ip'
# CLOUDSQL_ROOT_PASS='<your cloudsql root password>'
if [[ -z "${CLOUDSQL_INSTANCE_NAME}" ]]; then
  echo "You must provide CLOUDSQL_INSTANCE_NAME" 1>&2
  exit 1
fi
if [[ -z "${CLOUDSQL_IP_ADDRESS}" ]]; then
  echo "You must provide CLOUDSQL_IP_ADDRESS" 1>&2
  exit 1
fi
if [[ -z "${CLOUDSQL_ROOT_PASS}" ]]; then
  echo "You must provide CLOUDSQL_ROOT_PASS" 1>&2
  exit 1
fi

GCE_SERVICE_ACCOUNT_SCOPES+=('sql-admin')
SHARK_USER='hadoop'
SHARK_CLOUDSQL_PW='shark-cloudsql-pw'

COMMAND_GROUPS+=(
  "install_spark:
     extensions/spark/install_spark.sh
  "
  "install_shark:
     extensions/spark/install_shark.sh
  "
  "start_spark:
     extensions/spark/configure_shark_cloudsql.sh
     extensions/spark/start_spark.sh
  "
)

# Installation of spark on master and workers; then start_spark only on master.
COMMAND_STEPS+=(
  'install_spark,install_spark'
  'install_shark,install_shark'
  'start_spark,*'
)

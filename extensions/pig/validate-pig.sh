#!/usr/bin/env bash
#
# Copyright 2013 Google Inc. All Rights Reserved.
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

# Runs a basic Pig script.
# Usage:
#  gcloud compute --project <project> ssh hadoopnamenode-0 < validate-pig.sh
#

# File hadoop-confg.sh
HADOOP_CONFIGURE_CMD=''
HADOOP_CONFIGURE_CMD=$(find ${HADOOP_LIBEXEC_DIR} ${HADOOP_PREFIX} \
    /home/hadoop /usr/*/hadoop* -name hadoop-config.sh | head -n 1)

# If hadoop-config.sh has been found source it
if [[ -n "${HADOOP_CONFIGURE_CMD}" ]]; then
  echo "Sourcing '${HADOOP_CONFIGURE_CMD}'"
  . ${HADOOP_CONFIGURE_CMD}
fi

HADOOP_CMD=$(find ${HADOOP_PREFIX} /home/hadoop /usr/*/hadoop* -wholename '*/bin/hadoop' | head -n 1)
PIG_CMD=$(find ${HADOOP_PREFIX} /home/hadoop /usr/*/pig* -wholename '*/bin/pig' | head -n 1)

#if it is still empty then dont run the tests
if [[ "${HADOOP_CMD}" == '' ]]; then
  echo "Did not find hadoop'"
  exit 1
fi

#if it is still empty then dont run the tests
if [[ "${PIG_CMD}" == '' ]]; then
  echo "Did not find pig'"
  exit 1
fi

# Upload sample data.
PARENT_DIR="validate_pig_$(date +%s)"
${HADOOP_CMD} fs -mkdir /${PARENT_DIR}
${HADOOP_CMD} fs -put /etc/passwd /${PARENT_DIR}

# Create a basic Pig script.
echo "Creating pigtest.pig..."
cat << EOF > pigtest.pig
SET job.name 'PigTest';
data = LOAD '/${PARENT_DIR}/passwd'
      USING PigStorage(':')
      AS (user:CHARARRAY, dummy:CHARARRAY, uid:INT, gid:INT,
          name:CHARARRAY, home:CHARARRAY, shell:CHARARRAY);
grp = GROUP data BY (shell);
counts = FOREACH grp GENERATE
        FLATTEN(group), COUNT(data) AS shell_count:LONG;
res = ORDER counts BY shell_count DESC;
DUMP res;
EOF
cat pigtest.pig

# Run the script.
${PIG_CMD} pigtest.pig

# Cleanup.
echo "Cleaning up test data: ${PARENT_DIR}"
${HADOOP_CMD} fs -rmr -skipTrash ${PARENT_DIR}

exit 0

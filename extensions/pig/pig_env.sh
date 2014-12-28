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

# This file contains environment-variable overrides to be used in conjunction
# with bdutil_env.sh in order to deploy a Hadoop cluster with Pig installed.
# Usage: ./bdutil deploy extensions/pig/pig_env.sh

# Set the default filesystem to be 'hdfs' since Pig and Hive will tend to rely
# on multi-stage pipelines more heavily then plain Hadoop MapReduce, and thus
# be vulnerable to eventual list consistency. Okay to read initially from GCS
# using explicit gs:// URIs and likewise to write the final output to GCS,
# letting any intermediate cross-stage items get stored in HDFS temporarily.
DEFAULT_FS='hdfs'

PIG_TARBALL_URI='http://storage.googleapis.com/querytools-dist%2Fpig-0.12.0.tar.gz'
PIG_INSTALL_DIR='/home/hadoop/pig-install'

COMMAND_GROUPS+=(
  "install_pig:
     extensions/pig/install_pig.sh
  "
)

# Pig installation only needs to run on master.
COMMAND_STEPS+=(
  "install_pig,*"
)

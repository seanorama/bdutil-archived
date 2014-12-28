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

# Downloads and installs Pig.

set -e

PIG_TARBALL=${PIG_TARBALL_URI##*/}
PIG_TARBALL_URI_SCHEME=${PIG_TARBALL_URI%%://*}
if [[ "${PIG_TARBALL_URI_SCHEME}" == gs ]]; then
  gsutil cp ${PIG_TARBALL_URI} /home/hadoop/${PIG_TARBALL}
elif [[ "${PIG_TARBALL_URI_SCHEME}" =~ ^https?$ ]]; then
  wget ${PIG_TARBALL_URI} -O /home/hadoop/${PIG_TARBALL}
else
  echo "Unknown scheme \"${PIG_TARBALL_URI_SCHEME}\" in PIG_TARBALL_URI: \
$PIG_TARBALL_URI" >&2
  exit 1
fi
tar -C /home/hadoop -xvzf /home/hadoop/${PIG_TARBALL}
mv /home/hadoop/pig*/ ${PIG_INSTALL_DIR}

chown -R hadoop:hadoop /home/hadoop/${PIG_TARBALL} ${PIG_INSTALL_DIR}

# Update login scripts
add_to_path_at_login "${PIG_INSTALL_DIR}/bin"

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

# Basic installation of Ambari from public repos, followed by starting
# ambari-agent and if running on the master, also the ambari-server.

# SELinux gets in the way of many applications
setenforce 0
sed -i 's/\(^[^#]*\)SELINUX=enforcing/\1SELINUX=permissive/' /etc/selinux/config

# Disable iptables
chkconfig iptables off
service iptables stop

# install jdk
yum install -y java7-devel

# Get Repo
curl -o /etc/yum.repos.d/ambari.repo http://public-repo-1.hortonworks.com/ambari/centos6/1.x/updates/${AMBARI_VERSION}/ambari.repo

JAVA_HOME=/etc/alternatives/java_sdk
yum install -y ambari-agent
sed -i "s/^.*hostname=localhost/hostname=${MASTER_HOSTNAME}/" \
    /etc/ambari-agent/conf/ambari-agent.ini

# script to detect public address of google compute instances
cat > /etc/ambari-agent/conf/public-hostname.sh <<-'EOF'
#!/usr/bin/env bash
curl -Ls -m 5 http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google"
exit 0
EOF
chmod +x /etc/ambari-agent/conf/public-hostname.sh
sed -i "/\[agent\]/ a public_hostname_script=\/etc\/ambari-agent\/conf\/public-hostname.sh" /etc/ambari-agent/conf/ambari-agent.ini

service ambari-agent start

if [[ $(hostname) == ${MASTER_HOSTNAME} ]]; then
  yum install -y ambari-server
  service ambari-server stop
  ambari-server setup -j ${JAVA_HOME} -s
  if ! nohup bash -c "service ambari-server start 2>&1 > /dev/null"; then
    echo 'Ambari Server failed to start' >&2
    exit 1
  fi
fi

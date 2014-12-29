bdutil 
======

Utility for creating a Google Compute Engine cluster and installing, configuring, and calling Hadoop and Hadoop-compatible software on it.

More details here: https://cloud.google.com/hadoop/setting-up-a-hadoop-cluster

Below are my (seanorama) own notes for getting started.

### Configure Google Compute SDK

  - Open https://console.developers.google.com/
  - Login with your preferred Google account.
  - If needed, open "Sign up for free trial"

  - Install https://cloud.google.com/sdk/
    - OS X users with Homebrew can do: ```brew cask install google-cloud-sdk```
  - Authenticate: ```gcloud auth login```

### Create and prep a project for bdutil 

  - Open https://console.developers.google.com/
  - Open 'Create Project'. For example: 'hdp-play-00'
  - Within the project, open 'APIs & auth -> APIs'. Then enable:
    - Google Compute Engine
    - Google Cloud Storage
    - Google Cloud Storage JSON API
  - _(optional)_ Set the default project: ```gcloud config set project hdp-play-00```
  - Create Storage Container: ```gsutil mb -p hdp-play-00 gs://hdp-play-00```

### Deploy a Cluster (examples)

#### Example 01: Deploy HDP (Hortonworks Data Platform) using Ambari

  - Build a cluster with 3 worker nodes:
    ```./bdutil -e platforms/hdp/ambari_env.sh -b hdp-play-00 -p hdp-play-00 -m n1-standard-2 -i centos-6 -n 3 deploy```
  - Ambari will then be available on ‘http://hadoop-m:8080’
    - Get the IP with ```gcloud --project hdp-play-00 compute instances list```
  - You may need to open the firewall, or SSH tunnel. For example:
    - whitelist your ip: ```gcloud compute firewall-rules create whitelist --project hdp-play-00 --allow tcp icmp --network default --source-ranges `curl -s icanhazip.com`/32```
    - open Ambari (:8080) globally: ```gcloud compute firewall-rules create global-ambari --project hdp-play-00 --allow tcp:8080 --network default```

### Do something with your cluster

  - See ```samples/```
  - Example:
    - 

### Access the instances with SSH:

  - Use gcloud tools:
    - ```gcloud --project=hdp-play-00 compute ssh --zone=us-central1-a hadoop-m```
  - Or update your SSH config so only the instance name is required:
    - ```gcloud compute config-ssh```
    - ```ssh hadoop-m.us-central1-a.hdp-play-00```

### Delete a Cluster

  - Make sure to use the exact same parameters as the deploy. Just replace ‘deploy’ with ‘delete’.

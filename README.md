# bm-infra

### Machine configs.

```
export GCP_PROJECT_ID=cloud-tpu-inference-test
export GCP_INSTANCE_ID=vllm-bm-inst
export GCP_DATABASE_ID=vllm-bm-runs
export GCP_REGION=southamerica-west1
export GCP_INSTANCE_NAME=cuiq-infer-v6e-1-1
export GCS_BUCKET=vllm-cb-storage2
export GCP_QUEUE=vllm-bm-queue-v6e-1

export HF_TOKEN=<>

sudo apt-get update && sudo apt-get install -y jq

yes | gcloud auth configure-docker $GCP_REGION-docker.pkg.dev


# v6e-1
sudo tee -a /etc/environment > /dev/null <<EOF
GCP_PROJECT_ID=cloud-tpu-inference-test
GCP_INSTANCE_ID=vllm-bm-inst
GCP_DATABASE_ID=vllm-bm-runs
GCP_REGION=southamerica-west1
GCP_INSTANCE_NAME=cuiq-infer-v6e-1-1
GCS_BUCKET=vllm-cb-storage2
GCP_QUEUE=vllm-bm-queue-v6e-1
EOF

# v6e-8
sudo tee -a /etc/environment > /dev/null <<EOF
GCP_PROJECT_ID=cloud-tpu-inference-test
GCP_INSTANCE_ID=vllm-bm-inst
GCP_DATABASE_ID=vllm-bm-runs
GCP_REGION=southamerica-west1
GCP_INSTANCE_NAME=cuiq-infer-v6e-8-1
GCS_BUCKET=vllm-cb-storage2
GCP_QUEUE=vllm-bm-queue-v6e-8
EOF

```

### Install BM-Agent

```
./service/bm-agent/install.sh 
```

### Create and Delete Detabase

Create instance

```
gcloud spanner instances create $GCP_INSTANCE_ID \
   --description="vllm benchmark run record." \
   --nodes=1 \
   --project=$GCP_PROJECT_ID \
   --config=regional-$REGION
```

Create database

```
gcloud spanner databases create $GCP_DATABASE_ID \
 --project=$GCP_PROJECT_ID \
 --ddl-file=database/vllm_bm.sdl \
 --instance=$GCP_INSTANCE_ID 
```

Delete database

```
gcloud spanner databases delete $GCP_DATABASE_ID \
 --instance=$GCP_INSTANCE_ID \
 --project=$GCP_PROJECT_ID
```

### Create the Pub/sub queue.

Create pubsub

```

# create topic
gcloud pubsub topics create vllm-bm-queue-v6e-1 \
  --project="$GCP_PROJECT_ID"

# create agent subscription
gcloud pubsub subscriptions create vllm-bm-queue-v6e-1-agent \
  --project="$GCP_PROJECT_ID" \
  --topic="vllm-bm-queue-v6e-1" \
  --ack-deadline=600


# create topic
gcloud pubsub topics create vllm-bm-queue-v6e-8 \
  --project="$GCP_PROJECT_ID"

gcloud pubsub subscriptions create vllm-bm-queue-v6e-8-agent \
  --project="$GCP_PROJECT_ID" \
  --topic="vllm-bm-queue-v6e-8" \
  --ack-deadline=600

```

Delete pubsub

```
gcloud pubsub topics delete vllm-bm-queue-v6e-1 \
 --project=YOUR_PROJECT_ID

gcloud pubsub topics delete vllm-bm-queue-v6e-8 \
 --project=YOUR_PROJECT_ID
```

Give permission to service account. 

```
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="<service account>" \
  --role="roles/pubsub.publisher"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="<service account>" \
  --role="roles/pubsub.subscriber"
```

### Test Run command

Create a job

```
./scripts/scheduler/create_job.sh <INPUT_CSV> [CODE_HASH] [JOB_REFERENCE] [RUN_TYPE]
./scripts/scheduler/create_job.sh ./configs/case1.csv
./scripts/scheduler/create_job.sh ./configs/all_models_v6e_1.csv da9b523ce1fd5c27bfd18921ba0388bf2e8e4618 all_v6e1
```

Insert runs to database

```
./scripts/scheduler/schedule_run.sh ./configs/case1.csv a408820f2fcdd4025f05f8a43dc15604fe534367
```

Trigger run by Record id

```
./script/run_job.sh 5b5040f7-c815-4a87-ab8e-54a49fd49916
```

### Debug

```
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable bm-agent.service
sudo systemctl start bm-agent.service
sudo systemctl stop bm-agent.service
sudo systemctl status bm-agent.service
sudo systemctl restart bm-agent.service

sudo journalctl -u bm-agent
sudo journalctl -u bm-agent -f

sudo rm /etc/systemd/system/bm-agent.service

sudo docker exec -it vllm-tpu tail -f /workspace/vllm_log.txt

# create user
sudo useradd -m -s /bin/bash bm-agent

# give docker permission
sudo usermod -aG docker bm-agent


# delete 
sudo userdel -r bm-agent

# "login" to this user.
sudo su - bm-agent
```

buid a local image with local changes

```
# 1. go to the vllm folder. 
# 2. make the changes.
# 3. do git commit.
# run the script scripts/build_and_push_local_image.sh
```
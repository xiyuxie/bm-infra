# bm-infra

### Service account setup (draft) 

```
# create user
sudo useradd -m -s /bin/bash bm-agent

# give docker permission
sudo usermod -aG docker bm-agent


# delete 
sudo userdel -r bm-agent

# "login" to this user.
sudo su - bm-agent


```

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

Insert runs to database

```
./scripts/insert_run.sh ./configs/case1.csv a408820f2fcdd4025f05f8a43dc15604fe534367
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
```
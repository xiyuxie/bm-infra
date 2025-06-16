# Debug and development Notes

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
sudo journalctl -u bm-agent -n 300 -f

sudo systemctl status bm-scheduler.service
sudo systemctl restart bm-scheduler.service
sudo systemctl stop bm-scheduler.service

sudo journalctl -u bm-scheduler -n 300 -f

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

### Create Secret for HF_TOKEN

```
gcloud secrets create bm-agent-hf-token \
  --replication-policy="automatic"
  --project=$GCP_PROJECT_ID

echo -n "hf_your_actual_token" | \
gcloud secrets versions add bm-agent-hf-token \
  --data-file=- \
  --project=$GCP_PROJECT_ID

```

### Disk

after resizing the disk

run this to make sure system use it.

```
sudo resize2fs /dev/nvme0n2

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

# create topic v6e-1
gcloud pubsub topics create vllm-bm-queue-v6e-1 \
  --project="$GCP_PROJECT_ID"

# create agent subscription
gcloud pubsub subscriptions create vllm-bm-queue-v6e-1-agent \
  --project="$GCP_PROJECT_ID" \
  --topic="vllm-bm-queue-v6e-1" \
  --ack-deadline=600

# create topic v6e-4
gcloud pubsub topics create vllm-bm-queue-v6e-4 \
  --project="$GCP_PROJECT_ID"

# create agent subscription
gcloud pubsub subscriptions create vllm-bm-queue-v6e-4-agent \
  --project="$GCP_PROJECT_ID" \
  --topic="vllm-bm-queue-v6e-4" \
  --ack-deadline=600

# create topic v6e-8
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
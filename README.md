# bm-infra

```
export GCP_PROJECT_ID=cloud-tpu-inference-test
export GCP_INSTANCE_ID=vllm-bm-inst
export GCP_DATABASE_ID=vllm-bm-runs
export GCP_REGION=southamerica-west1
export GCS_BUCKET=vllm-cb-storage2
export GCS_INSTANCE_NAME=cuiq-infer-v6e-1-1
export HF_TOKEN=<>
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
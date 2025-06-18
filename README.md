# bm-infra

### Machine configs.

```
export GCP_PROJECT_ID=cloud-tpu-inference-test
export GCP_INSTANCE_ID=vllm-bm-inst
export GCP_DATABASE_ID=vllm-bm-runs
export GCP_REGION=southamerica-west1
export GCS_BUCKET=vllm-cb-storage2

export GCP_QUEUE=vllm-bm-queue-{v6e-1, v6e-4, v6e-6}
export HF_TOKEN=<>
export GCP_INSTANCE_NAME=<your instance name>

# install jq for parsing json.
sudo apt-get update && sudo apt-get install -y jq

# give docker permission to access artifacts registry
yes | gcloud auth configure-docker $GCP_REGION-docker.pkg.dev

```

### Install BM-Agent

This is to install it on dev machine mostly for debugging. 

Terrform deploys bm-agent when creating the agent machines.

```
./service/bm-agent/install.sh 
```

### Deploy and Install everything with TF

install terraform

```
# 1. Install required packages
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

# 2. Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# 3. Add the official HashiCorp Linux repo
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

# 4. Update and install Terraform
sudo apt-get update && sudo apt-get install terraform -y
```

deploy

```
pushd terraform/gcp

terraform init

terraform plan

terraform apply

popd
```

### Create Looker Studio Report

1   Create a "looker friendly" view like this(ok to be different): 

```

CREATE OR REPLACE VIEW
  `HourlyRun` SQL SECURITY INVOKER AS
SELECT
  RunRecord.RecordId,
  RunRecord.JobReference,
  RunRecord.Model,
  RunRecord.CodeHash,
  RunRecord.Status,
  RunRecord.Device,
  IFNULL(RunRecord.Throughput, 0) AS Throughput, 
  PARSE_TIMESTAMP('%Y%m%d_%H%M%S', RunRecord.JobReference, 'America/Los_Angeles') AS JobReferenceTime
FROM
  RunRecord
WHERE
  RunRecord.RunType = 'HOURLY'
  AND RunRecord.Status IN ('COMPLETED',
    'FAILED')
  AND RunRecord.CreatedTime >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
ORDER BY
  RunRecord.JobReference;

```

2.  https://lookerstudio.google.com/
3.  Create a datasource and use Cloud Spanner as Data Source and use the view.
4.  On the UI, choose column you care about and add field if needed, for example, a link to log, etc.
5.  Create a report on it... a lot of manual work.

### Test Run command

Create a job

```
./scripts/scheduler/create_job.sh <INPUT_CSV> [CODE_HASH] [JOB_REFERENCE] [RUN_TYPE]
./scripts/scheduler/create_job.sh ./configs/case1.csv
./scripts/scheduler/create_job.sh ./configs/all_models_v6e_1.csv da9b523ce1fd5c27bfd18921ba0388bf2e8e4618 all_v6e1

# to skip image building and pushing, use SKIP_BUILD_IMAGE=1
SKIP_BUILD_IMAGE=1 ./scripts/scheduler/create_job.sh ./configs/all_models_v6e_1.csv da9b523ce1fd5c27bfd18921ba0388bf2e8e4618 all_v6e1
```

Get Job status

```
./scripts/manager/get_status.sh [JOB_REFERENCE]

```

Insert runs to database

```
./scripts/scheduler/schedule_run.sh ./configs/case1.csv a408820f2fcdd4025f05f8a43dc15604fe534367
```

Trigger run by Record id

```
./script/run_job.sh 5b5040f7-c815-4a87-ab8e-54a49fd49916
```


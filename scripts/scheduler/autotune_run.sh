#!/bin/bash

TIMEZONE="America/Los_Angeles"
TAG="$(TZ="$TIMEZONE" date +%Y%m%d_%H%M%S)"

echo "./scripts/scheduler/create_job.sh ./cases/autotune.csv \"\" $TAG AUTOTUNE"
./scripts/scheduler/create_job.sh ./cases/autotune.csv "" $TAG AUTOTUNE

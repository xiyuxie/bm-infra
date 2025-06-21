#!/bin/bash

echo "git pull to latest."
git pull

./scripts/scheduler/hourly_run.sh

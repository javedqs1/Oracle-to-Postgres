#!/bin/bash
# Copyright 2021 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Dataflow Config Vars
sudo yum install install uuid-runtime -y
NEW_UUID=$(uuidgen | head -c 6 | awk '{print tolower($0)}')
export DATAFLOW_JOB_NAME="${DATAFLOW_JOB_PREFIX}-${NEW_UUID}"
export DATABASE_HOST=$(gcloud sql instances list --project=${PROJECT_ID} | grep "${CLOUD_SQL}" | awk '{print $6;}')

gcloud config set project ${PROJECT_ID}
if [ "$1" == "create" ]
then
  gcloud dataflow flex-template run "${DATAFLOW_JOB_NAME}" --quiet \
    --project="${PROJECT_ID}" --region="${REGION}" \
    --enable-streaming-engine \
    --template-file-gcs-location="${TEMPLATE_IMAGE_SPEC}" \
    --parameters schemaMap=":",gcsPubSubSubscription="projects/${PROJECT_ID}/subscriptions/${PUBSUB_SUBSCRIPTION}",inputFilePattern="${GCS_STREAM_PATH}",databaseHost=${DATABASE_HOST},databasePort="5432",databaseUser=${DATABASE_USER},databasePassword=${DATABASE_PASSWORD},maxNumWorkers=10,autoscalingAlgorithm="THROUGHPUT_BASED"
elif [ "$1" == "destroy" ]
then
  # Kill Running Jobs
  DATAFLOW_JOB_ID=$(gcloud dataflow jobs list --status=active | grep ${DATAFLOW_JOB_PREFIX} | awk '{print $1;}')
  if [ "$DATAFLOW_JOB_ID" != '' ]; then
    gcloud dataflow jobs cancel ${DATAFLOW_JOB_ID} --region=${REGION} --project="${PROJECT_ID}"
    echo 'Killing Old Dataflow Jobs: Feel free to go to lunch'
  fi
else
    echo "Dataflow Jobs"
    gcloud dataflow jobs list --status=active --region="${REGION}" --project="${PROJECT_ID}"
fi

#!/usr/bin/env bash
# Copyright 2020 The Kubernetes Authors.
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

set -o errexit -o nounset -o pipefail
set -x;

# cd to the repo root
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

if [[ -z "${VERSION:-}" ]]; then
  VERSION=$(git describe --always --exclude 'etcd-manager/*')
fi

if [[ -z "${ARTIFACT_LOCATION:-}" ]]; then
  echo "must set ARTIFACT_LOCATION for binary artifacts"
  exit 1
fi

# Make sure ARTIFACT_LOCATION ends in a slash
if [[ "${ARTIFACT_LOCATION}" != */ ]]; then
  ARTIFACT_LOCATION="${ARTIFACT_LOCATION}/"
fi

# Build etcdadm binary
make etcdadm

# Upload etcdadm binary
DOWNLOAD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.tar.gz"
echo "Downloading google-cloud-sdk.tar.gz from $DOWNLOAD_URL"
curl -L -o "/tmp/google-cloud-sdk.tar.gz" "${DOWNLOAD_URL}"
tar xzf /tmp/google-cloud-sdk.tar.gz -C /
rm /tmp/google-cloud-sdk.tar.gz
/google-cloud-sdk/install.sh \
    --bash-completion=false \
    --usage-reporting=false \
    --quiet
ln -s /google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud
ln -s /google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil
gcloud info
gcloud config list
gcloud auth list
gsutil -h "Cache-Control:private, max-age=0, no-transform" -m cp -n etcdadm ${ARTIFACT_LOCATION}${VERSION}/etcdadm

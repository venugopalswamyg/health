#!/usr/bin/env bash
set -euo pipefail

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI is required. Install from https://aka.ms/installazurecli"
  exit 1
fi

if ! az extension show --name azure-devops >/dev/null 2>&1; then
  echo "Installing Azure DevOps CLI extension..."
  az extension add --name azure-devops
fi

if ! az account show >/dev/null 2>&1; then
  echo "Azure CLI login is required. Use the device login flow below."
  az login --use-device-code
fi

: "${AZDO_ORGANIZATION_URL:?Environment variable AZDO_ORGANIZATION_URL is required}"
: "${AZDO_PROJECT:?Environment variable AZDO_PROJECT is required}"

AZDO_PIPELINE_NAME="${AZDO_PIPELINE_NAME:-Healthcare-App Pipeline}"
AZDO_YAML_PATH="${AZDO_YAML_PATH:-azure-pipelines.yml}"
AZDO_REPOSITORY_TYPE="${AZDO_REPOSITORY_TYPE:-github}"

az devops configure --defaults organization="$AZDO_ORGANIZATION_URL" project="$AZDO_PROJECT"

if [[ "$AZDO_REPOSITORY_TYPE" == "github" ]]; then
  : "${AZDO_GITHUB_REPO:?Environment variable AZDO_GITHUB_REPO is required for GitHub repositories}"
  echo "Creating GitHub-backed Azure DevOps pipeline for repository $AZDO_GITHUB_REPO"
  pipeline_args=(
    az pipelines create
    --name "$AZDO_PIPELINE_NAME"
    --description "CI/CD pipeline for Healthcare-APP"
    --repository "$AZDO_GITHUB_REPO"
    --branch main
    --repository-type github
    --yml-path "$AZDO_YAML_PATH"
  )
  if [[ -n "${AZDO_SERVICE_CONNECTION-}" ]]; then
    pipeline_args+=(--service-connection "$AZDO_SERVICE_CONNECTION")
  fi
  "${pipeline_args[@]}"
else
  : "${AZDO_REPOSITORY_NAME:?Environment variable AZDO_REPOSITORY_NAME is required for Azure Repos repositories}"
  echo "Creating Azure Repos-backed Azure DevOps pipeline for repository $AZDO_REPOSITORY_NAME"
  az pipelines create \
    --name "$AZDO_PIPELINE_NAME" \
    --description "CI/CD pipeline for Healthcare-APP" \
    --repository "$AZDO_REPOSITORY_NAME" \
    --branch main \
    --repository-type tfsgit \
    --yml-path "$AZDO_YAML_PATH"
fi

echo "Pipeline creation complete."
az pipelines list --output table --query "[?name=='$AZDO_PIPELINE_NAME']"

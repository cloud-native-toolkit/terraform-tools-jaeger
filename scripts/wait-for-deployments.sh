#!/usr/bin/env bash

NAMESPACE="$1"
NAME="$2"

count=0
until kubectl get deployment -n "${NAMESPACE}" "${NAME}"; do
  if [[ "$count" -eq 12 ]]; then
    echo "Timed out waiting for deployment/${NAME} in ${NAMESPACE}"
    kubectl get deployment -n "${NAMESPACE}" "${NAME}"
    exit 1
  fi

  echo "Waiting for deployment/${NAME} in ${NAMESPACE} namespace"
  sleep 30

  count=$((count+1))
done

DEPLOYMENTS="${NAME}"

echo "${DEPLOYMENTS}" | while read DEPLOYMENT; do
  count=0

  kubectl rollout status deployment "${DEPLOYMENT}" -n "${NAMESPACE}"
done

#!/usr/bin/env bash

NAMESPACE="$1"
NAME="$2"

count=0
while [[ $(kubectl get deployment -n "${NAMESPACE}" -l "app=${NAME}" | wc -l) -gt 2 ]] && [[ "$count" -lt 10 ]]; do
  echo "Waiting for deployments in ${NAMESPACE} namespace"
  sleep 30
done

DEPLOYMENTS=$(kubectl get deployment -n "${NAMESPACE}" -l "app=${NAME}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

echo "${DEPLOYMENTS}" | while read DEPLOYMENT; do
  count=0

  kubectl rollout status deployment "${DEPLOYMENT}" -n "${NAMESPACE}"
done

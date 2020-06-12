#!/usr/bin/env bash

NAMESPACE="$1"
NAME="$2"

if kubectl get -n "${NAMESPACE}" jaeger.jaegertracing.io "${NAME}" 1> /dev/null 2> /dev/null; then
  echo "Deleting jaeger instance: ${NAMESPACE}/${NAME}"
  kubectl delete -n "${NAMESPACE}" jaeger.jaegertracing.io "${NAME}" --wait
else
  echo "Unable to find jaeger instance: ${NAMESPACE}/${NAME}"
fi


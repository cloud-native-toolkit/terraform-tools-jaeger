#!/usr/bin/env bash

NAMESPACE="$1"

if kubectl get -n "${NAMESPACE}" subscription jaeger 1> /dev/null 2> /dev/null; then
  echo "Deleting Jaeger operator subscription: ${NAMESPACE}"
  kubectl delete -n "${NAMESPACE}" subscription jaeger
else
  echo "Unable to find subscription for Jaeger operator in ${NAMESPACE}"
fi

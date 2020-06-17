#!/usr/bin/env bash

CLUSTER_TYPE="$1"
OPERATOR_NAMESPACE="$2"
OLM_NAMESPACE="$3"
APP_NAMESPACE="$4"

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

if [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  SOURCE="redhat-operators"
  NAME="jaeger-product"
else
  SOURCE="operatorhubio-catalog"
  NAME="jaeger"
fi

if [[ -z "${OLM_NAMESPACE}" ]]; then
  if [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
    OLM_NAMESPACE="openshift-marketplace"
  else
    OLM_NAMESPACE="olm"
  fi
fi

YAML_FILE=${TMP_DIR}/jaeger-subscription.yaml

cat <<EOL > ${YAML_FILE}
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: jaeger
spec:
  channel: stable
  installPlanApproval: Automatic
  name: ${NAME}
  source: $SOURCE
  sourceNamespace: $OLM_NAMESPACE
EOL

kubectl apply -f ${YAML_FILE} -n "${OPERATOR_NAMESPACE}"

count=0
until kubectl get jaeger.jaegertracing.io 1> /dev/null 2> /dev/null || [[ "${count}" -eq "10" ]]; do
  echo "Waiting for Jaeger CRD to be installed"
  sleep 15
  count=$((count + 1))
done

kubectl get jaeger.jaegertracing.io

until [[ $(kubectl get csv -n "${APP_NAMESPACE}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep jaeger-operator | wc -l) -gt "0" ]] || [[ "${count}" -eq "10" ]]; do
  echo "Waiting for Jaeger CSV to be installed into ${APP_NAMESPACE}"
  sleep 15
  count=$((count + 1))
done

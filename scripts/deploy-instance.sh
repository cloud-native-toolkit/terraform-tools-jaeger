#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

CLUSTER_TYPE="$1"
NAMESPACE="$2"
INGRESS_SUBDOMAIN="$3"
NAME="$4"
TLS_SECRET_NAME="$5"

if [[ -z "${NAME}" ]]; then
  NAME=jaeger
fi

if [[ -z "${TLS_SECRET_NAME}" ]]; then
  TLS_SECRET_NAME=$(echo "${INGRESS_SUBDOMAIN}" | sed -E "s/([^.]+).*/\1/g")
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  HOST="${NAME}-${NAMESPACE}.${INGRESS_SUBDOMAIN}"
fi

YAML_FILE=${TMP_DIR}/jaeger-instance-${NAME}.yaml

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  cat <<EOL > ${YAML_FILE}
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: ${NAME}
spec:
  ingress:
    hosts:
     - ${HOST}
    tls:
     - hosts:
       - ${HOST}
       secretName: ${TLS_SECRET_NAME}
EOL
else
  cat <<EOL > ${YAML_FILE}
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: ${NAME}
EOL
fi

kubectl apply -f ${YAML_FILE} -n "${NAMESPACE}"

"${SCRIPT_DIR}/wait-for-deployments.sh" "${NAMESPACE}" "${NAME}"

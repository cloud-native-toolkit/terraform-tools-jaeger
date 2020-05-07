
CLUSTER_TYPE="$1"
NAMESPACE="$2"
INGRESS_SUBDOMAIN="$3"
NAME="$4"

if [[ -z "${NAME}" ]]; then
  NAME=nexus
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  HOST="${NAME}-${NAMESPACE}.${INGRESS_SUBDOMAIN}"
fi

YAML_FILE=${TMP_DIR}/jaeger-instance-${NAME}.yaml

cat <<EOL > ${YAML_FILE}
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: ${NAME}
EOL

kubectl apply -f ${YAML_FILE} -n "${NAMESPACE}"

kubectl rollout status deployment/${NAME} -n "${NAMESPACE}"

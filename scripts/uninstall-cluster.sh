#! /bin/bash

NAMESPACE="${1:-byconity}"

echo "NAMESPACE: ${NAMESPACE}"

output=$(kubectl get namespaces  2>&1 | grep ${NAMESPACE};)

if echo $output | grep -q "timeout" || echo $output | grep -v ${NAMESPACE} ; then
	echo "Cannot visit K8s or $NAMESPACE not exists.  Resp=[${output}]"
	exit 1;
fi

helm uninstall --namespace ${NAMESPACE} byconity

kubectl delete namespace ${NAMESPACE}

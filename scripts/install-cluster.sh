#! /bin/bash
#
NAMESPACE="${1:-byconity}"
echo "NAMESPACE: ${NAMESPACE}"

output=$(helm -n byconity get metadata  byconity 2>&1 | grep STATUS)
status=$?

if echo $output | grep -q "timeout"; then
	echo "Cannot visit K8s or $NAMESPACE already exists, please unstiall it first. Resp=[${output}]"
  exit 1;
fi


echo "Step 1:helm install without fdb"

command="helm upgrade --install --create-namespace --namespace ${NAMESPACE} -f values-kind.yaml byconity ./chart/byconity --set fdb.enabled=false"

echo "$command"
eval $command

end_time=$(( $(date +%s) + 60 ))

while [ $(date +%s) -lt $end_time ]; do
  echo "checking deployment"
  kubectl get pods -n ${NAMESPACE}
  sleep 10
done

echo "Step 2: helm install with FDB"
command2="helm upgrade --install --create-namespace --namespace ${NAMESPACE} -f values-kind.yaml byconity ./chart/byconity"

echo "$command2"
eval $command2

end_time=$(( $(date +%s) + 60 ))
while [ $(date +%s) -lt $end_time ]; do
  echo "checking deployment"
  kubectl get pods -n ${NAMESPACE}
  sleep 10
done
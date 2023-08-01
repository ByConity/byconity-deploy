#!/bin/bash
#read values.yaml
#check the resource
#install crd first
#install byconity
# for first
# example ./install value_file_path=x chart_path=x enable_fdb=x
root_path=$(PWD)  #path of your repo
value_file_path=''      #path of your value-file
chart_path=''           #path of your chart
enable_fdb=true        #if need to install fdb,  please set true
is_upgrade=false      #for upgrade please use helm upgrade or set this value into true
namespace='byconity'  #namespace，default byconity
DEPLOYMENT_NAME='byconity' #depoyment_name default byconity



for arg in "$@"; do
  case $arg in
    value_file_path=*)
      value_file_path="${arg#*=}"
      ;;
    chart_path=*)
      chart_path="${arg#*=}"
      ;;
    enable_fdb=*)
      enable_fdb="${arg#*=}"
      ;;
    is_upgrade=*)
      is_upgrade="${arg#*=}"
      ;;
      namespace=*)
   namespace="${arg#*=}"
      ;;
    *)
      ;;
  esac
done

if [ -z "root_path" ]; then
    echo "please input root_path"
    exit 1
fi
if [ -z "value_file_path" ]; then
    echo "please input value_file_path"
    exit 1
fi
if [ -z "chart_path" ]; then
    echo "please input chart_path"
    exit 1
fi
if [ -z "namespace" ]; then
    echo "using default namespace byconity"
fi


echo "value_file_path ${value_file_path}"
echo "chart_path ${chart_path}"
echo "enable_fdb ${enable_fdb}"
echo "is_upgrade ${is_upgrade}"
echo "namespace ${namespace}"


#crd_arr=("foundationdbbackups.apps.foundationdb.org" "foundationdbclusters.apps.foundationdb.org" "foundationdbrestores.apps.foundationdb.org")
if ${enable_fdb} && ! ${is_upgrade};then
   echo 'In order to install the crd of fdb first, temporarily set fdb enabled to false'
  helm upgrade --install --create-namespace --namespace $namespace byconity -f $root_path/$value_file_path $root_path/$chart_path --set fdb.enabled=false

fi

crd_install_result=$?
if [ $crd_install_result -eq 0 ]; then
  echo "crd install successfully"
else
   echo "crd install failed"
   exit
fi
echo 'start to deploy byconity'

helm upgrade --install --create-namespace --namespace $namespace byconity -f $root_path/$value_file_path $root_path/$chart_path

byconity_install_result=$?
if [ $byconity_install_result -eq 0 ]; then
  echo "byconity install successfully"
else
   echo "byconity install failed"
   exit
fi
function checkByconityStatus {
   TIMEOUT=500
   deployments=(`kubectl get deployments -n ${namespace} --selector=app.kubernetes.io/name=${DEPLOYMENT_NAME} | awk '{print $1}'`)
   echo $deployments
   deployments=("${deployments[@]:1}") # throw the header

   for deploy in "${deployments[@]}";
   do
     kubectl wait --for=condition=available --timeout="${TIMEOUT}s" deployment/"${deploy}" -n ${namespace}
   done
   time_spent=0
   while [ ${time_spent} -le ${TIMEOUT} ]; do
      set +e
      # if replicas is set to 0, or replicas == ready_replicas, the statefulset is available
      # here we get list of not yet available ones
      not_ready=(`kubectl get statefulsets -n ${namespace} --selector=app.kubernetes.io/name=${DEPLOYMENT_NAME} --no-headers -ocustom-columns=:.metadata.name,:.status.replicas,:.status.updatedReplicas  | awk '{if ($2 != 0 && $2 != $3) print $0_}'`)
      not_ready_exit_code=$?
      set -e

      if [[ $not_ready_exit_code -ne 0 ]]; then
        echo "Met error while checking readiness of statefulsets"
      elif [[ "${#not_ready[@]}" -eq 0 ]]; then
         echo "All statefulsets are ready"
         break
      else
          echo "Not all statefulsets are ready yet: $not_ready"
      fi
          time_spent=$((time_spent+30))
          sleep 30
      done

      if ! [  "${time_spent}" -le ${TIMEOUT} ]; then
          echo "Not all statefulsets are ready"
          exit 1
      fi
}

checkByconityStatus


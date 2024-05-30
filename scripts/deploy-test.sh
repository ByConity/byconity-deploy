#!/bin/bash
if [ $# -eq 0 ]; then
   kubectl apply -f test-pod.yaml
else
   kubectl apply -f test-pod.yaml -n $1
fi




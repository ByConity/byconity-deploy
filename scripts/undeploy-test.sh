#!/bin/bash
if [ $# -eq 0 ]; then
   kubectl delete pod byconity-test
else
   kubectl delete pod byconity-test -n $1
fi

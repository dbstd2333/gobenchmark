#!/bin/bash

nprocs=$(getconf _NPROCESSORS_ONLN)
if [ $nprocs -lt 2 ]; then
    echo "Your environment should have at least 2 processors"
    exit 1
elif [ $nprocs -gt 20 ]; then
    nprocs=20
fi

# GO
GOEXEC=${GOEXEC:-"go"}
GOROOT=$GOROOT

scpu=1 # 将 scpu 固定为 1
taskset_less="taskset -c 1"
taskset_more="taskset -c 2"

REPORT=${REPORT:-"$(date +%F-%H-%M)"}
tee_cmd="tee -a output/${REPORT}.log"

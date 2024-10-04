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

# 计算 scpu 的值
scpu=$((nprocs > 16 ? 3 : nprocs / 4 - 1)) # 最大值为 3 (4 个 CPU 核心)

# 确保 scpu 至少为 0
scpu=$((scpu < 0 ? 0 : scpu))

taskset_less="taskset -c 0-$scpu"
taskset_more="taskset -c $((scpu + 1))-$((nprocs - 1))"

REPORT=${REPORT:-"$(date +%F-%H-%M)"}
tee_cmd="tee -a output/${REPORT}.log"

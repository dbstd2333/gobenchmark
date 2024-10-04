#!/bin/bash

nprocs=$(getconf _NPROCESSORS_ONLN)
min_procs=2 # 设置允许的最小处理器数量

# 检查处理器数量是否符合要求
if [ $nprocs -lt $min_procs ]; then
    echo "Your environment should have at least $min_procs processors"
    exit 1
elif [ $nprocs -gt 20 ]; then
    nprocs=20
fi

# GO
GOEXEC=${GOEXEC:-"go"}
GOROOT=$GOROOT

# 根据处理器数量设置调度策略
if [ $nprocs -le 4 ]; then
    scpu=$((nprocs - 1)) # 2核或4核时，使用全部CPU
else
    scpu=$((nprocs > 16 ? 3 : nprocs / 4 - 1)) # 对于超过4核的系统，使用原始逻辑
fi

taskset_less="taskset -c 0-$scpu"
taskset_more="taskset -c $((scpu + 1))-$((nprocs - 1))"

REPORT=${REPORT:-"$(date +%F-%H-%M)"}
tee_cmd="tee -a output/${REPORT}.log"

# 输出分配信息
echo "CPU count: $nprocs"
echo "Using CPUs: $taskset_less for primary tasks"
echo "Using CPUs: $taskset_more for secondary tasks"

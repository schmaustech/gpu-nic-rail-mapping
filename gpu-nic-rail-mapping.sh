#!/bin/bash

gpuid="10de:2335"
nicid="15b3:a2dc"

mapfile -t my_gpus < <(lspci -nn|grep $gpuid)
mapfile -t my_nics < <(lspci -nn|grep $nicid)

for (( gpu=0; gpu<${#my_gpus[@]}; gpu++ ))
do
    echo ${my_gpus[$gpu]}
done

for (( nic=0; nic<${#my_nics[@]}; nic++ ))
do
    echo ${my_nics[$nic]}
done

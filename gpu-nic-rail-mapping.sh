#!/bin/bash

gpuid="10de:2335"
nicid="15b3:a2dc"

mapfile -t my_gpus < <(lspci -nn|grep $gpuid)
mapfile -t my_nics < <(lspci -nn|grep $nicid)

for (( gpu=0; gpu<${#my_gpus[@]}; gpu++ ))
do
    gpubusid=`echo ${my_gpus[$gpu]} | awk '{print $1}'` 
    gpupcisw=`lspci -d $gpuid -PP | grep $gpubusid | awk -F '/' {'print $1"/"$2'}`
    #echo "GPU $gpupcisw $gpubusid"
    for (( nic=0; nic<${#my_nics[@]}; nic++ ))
    do
       nicbusid=`echo ${my_nics[$nic]} | awk '{print $1}'`
       nicpcisw=`lspci -d $nicid -PP | grep $nicbusid | awk -F '/' {'print $1"/"$2'}`
       #echo "NIC $nicpcisw $nicbusid"
       if [ "$nicpcisw" = "$gpupcisw" ]; then
           nicslot=`dmidecode -t slot | grep -B4 $nicbusid|grep ID|awk -F ': ' {'print $2'}`
           echo "GPU Bus Address: $gpubusid NIC Bus Address: $nicbusid Common PCIe Switch: $nicpcisw NIC SLOT: $nicslot"
       fi
    done

done

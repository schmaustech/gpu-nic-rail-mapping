#!/bin/bash
##############################################################################################################
# This script maps GPU/NIC/SLOT for ensuring only one Spectrum-X rail is assigned per GPU on same PCI Switch #
##############################################################################################################

### Need to enable passing of options from cli so we can specify our gpu device id and nic device id 
gpuid="10de:2335"
nicid="15b3:a2dc"

# Slurp in the GPU devices 
mapfile -t my_gpus < <(lspci -nn|grep $gpuid)
# Slurp in the NIC devices
mapfile -t my_nics < <(lspci -nn|grep $nicid)

# This is where it gets real
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
           if [[ "$nicbusid" == *.1 ]]; then
               nicport=2
               altnicbusid=`echo $nicbusid | sed 's/.$/0/'`
               nicslot=`dmidecode -t slot | grep -B4 $altnicbusid|grep ID|awk -F ': ' {'print $2'}`
           else
               nicport=1
               nicslot=`dmidecode -t slot | grep -B4 $nicbusid|grep ID|awk -F ': ' {'print $2'}`
           fi
           echo "GPU Bus Address: $gpubusid NIC Bus Address: $nicbusid Common PCIe Switch: $nicpcisw NIC Slot: $nicslot NIC Port: $nicport UDEV Name:"
       fi
    done
done

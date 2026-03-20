# GPU To NIC Rail Mapping

**Goal**: The goal of this project is to provide a simple mechanism to map which GPUs are associated to which NICs on the same PCIe switch inside a baremetal system.  This mapped information can then assist in generating a OpenShift MachineConfig that can identify one network card per GPU on the same PCI root complex and call that the rail nic while marking any others as secondary.   This is primarily for Spectrum-X but could be used across any platform where GPU to NIC coherency is important in regards to configuration for OpenShift.

**Note**: This also provides an example of quick iteration of automating a problem that was just sitting manually in front of us.

## Contents

- [Why](#why)
- [hwloc](#hwloc)
- [gpu-nic-rail-mapping](#gpu-nic-rail-mapping)

## Why

For optimal cluster performance and minimal latency, it’s essential to align each GPU with its nearest high-speed NIC—ideally on the same NUMA node and PCIe root complex. This ensures that data traveling to and from each GPU takes the shortest, most efficient path, which is especially critical for RDMA and high-throughput AI/HPC workloads.

While there are tools that can provide pieces of this view all the commands have to be run manually and then its up to the user to fit it all together.  Ideally there should be one solution that can provide all the details in a concise manner.

## Hwloc

 The Portable Hardware Locality (hwloc) software package provides a portable abstraction of the hierarchical topology of modern architectures, including NUMA memory nodes (DRAM, HBM, non-volatile memory, CXL, etc.), processor packages, shared caches, cores and simultaneous multithreading. It also gathers various system attributes such as cache and memory information as well as the locality of I/O devices such as network interfaces, InfiniBand HCAs or GPUs.

<img src="lstopo.png" style="width: 800px;" border=0/>

hwloc primarily aims at helping applications with gathering information about increasingly complex parallel computing platforms so as to exploit them accordingly and efficiently. For instance, two tasks that tightly cooperate should probably be placed onto cores sharing a cache. However, two independent memory-intensive tasks should better be spread out onto different processor packages so as to maximize their memory throughput. 

However Hwloc does not ship in OpenShift today and seems heavy handed for the task at hand.

## Gpu-nic-rail-mapping

The gpu-nic-rail-mapping aims to provide a simple example to identify the GPU to NIC relationship and then generates the MachineConfig for OpenShift to ensure there is one rail per GPU marked.  Below is an example run on a Dell 9680 (H200) system with the following devices in it:

* 8 x H200 GPUs - Device ID 10de:2335
* 14 x BF3 Cards - Device ID 15b3:a2dc

~~~bash
sh-5.1# ./gpu-nic-rail-mapping -g 10de:2335 -n 15b3:a2dc -u 70-persistent-net.rules -r worker

 GPU BusAddr   NIC BusAddr PCIe Switch             NIC Slot    NIC Port   UDEV Eth    UDEV IB
====================================================================================================
 1b:00.0       18:00.0     15:01.0/16:00.0         40          1          eth_rail0   roce_rail0             
 1b:00.0       1a:00.0     15:01.0/16:00.0         42          1           eth_sec0    roce_sec0             
 3c:00.0       3a:00.0     37:01.0/38:00.0         41          1          eth_rail1   roce_rail1             
 4b:00.0       4d:00.0     48:01.0/49:00.0         38          1          eth_rail2   roce_rail2             
 5c:00.0       5d:00.0     59:01.0/5a:00.0         37          1          eth_rail3   roce_rail3             
 5c:00.0       5f:00.0     59:01.0/5a:00.0         39          1           eth_sec1    roce_sec1             
 5c:00.0       5f:00.1     59:01.0/5a:00.0         39          2           eth_sec2    roce_sec2             
 9a:00.0       9b:00.0     97:01.0/98:00.0         32          1          eth_rail4   roce_rail4             
 bb:00.0       ba:00.0     b7:01.0/b8:00.0         31          1          eth_rail5   roce_rail5             
 bb:00.0       bc:00.0     b7:01.0/b8:00.0         33          1           eth_sec3    roce_sec3             
 bb:00.0       bc:00.1     b7:01.0/b8:00.0         33          2           eth_sec4    roce_sec4             
 cd:00.0       ca:00.0     c7:01.0/c8:00.0         36          1          eth_rail6   roce_rail6             
 cd:00.0       cc:00.0     c7:01.0/c8:00.0         34          1           eth_sec5    roce_sec5             
 dc:00.0       db:00.0     d7:01.0/d8:00.0         35          1          eth_rail7   roce_rail7             
Generated 99-machine-config-udev-network.yaml file for OpenShift
~~~

Here was the 70-persistent-net.rules file generated.

~~~bash
sh-5.1# cat 70-persistent-net.rules 
ACTION=="add", KERNELS=="0000:18:00.0", SUBSYSTEM=="net", NAME="eth_rail0"
ACTION=="add", KERNELS=="0000:18:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_rail0"
ACTION=="add", KERNELS=="0000:1a:00.0", SUBSYSTEM=="net", NAME="eth_sec0"
ACTION=="add", KERNELS=="0000:1a:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_sec0"
ACTION=="add", KERNELS=="0000:3a:00.0", SUBSYSTEM=="net", NAME="eth_rail1"
ACTION=="add", KERNELS=="0000:3a:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_rail1"
ACTION=="add", KERNELS=="0000:4d:00.0", SUBSYSTEM=="net", NAME="eth_rail2"
ACTION=="add", KERNELS=="0000:4d:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_rail2"
ACTION=="add", KERNELS=="0000:5d:00.0", SUBSYSTEM=="net", NAME="eth_rail3"
ACTION=="add", KERNELS=="0000:5d:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_rail3"
ACTION=="add", KERNELS=="0000:5f:00.0", SUBSYSTEM=="net", NAME="eth_sec1"
ACTION=="add", KERNELS=="0000:5f:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_sec1"
ACTION=="add", KERNELS=="0000:5f:00.1", SUBSYSTEM=="net", NAME="eth_sec2"
ACTION=="add", KERNELS=="0000:5f:00.1", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_sec2"
ACTION=="add", KERNELS=="0000:9b:00.0", SUBSYSTEM=="net", NAME="eth_rail4"
ACTION=="add", KERNELS=="0000:9b:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_rail4"
ACTION=="add", KERNELS=="0000:ba:00.0", SUBSYSTEM=="net", NAME="eth_rail5"
ACTION=="add", KERNELS=="0000:ba:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_rail5"
ACTION=="add", KERNELS=="0000:bc:00.0", SUBSYSTEM=="net", NAME="eth_sec3"
ACTION=="add", KERNELS=="0000:bc:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_sec3"
ACTION=="add", KERNELS=="0000:bc:00.1", SUBSYSTEM=="net", NAME="eth_sec4"
ACTION=="add", KERNELS=="0000:bc:00.1", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_sec4"
ACTION=="add", KERNELS=="0000:ca:00.0", SUBSYSTEM=="net", NAME="eth_rail6"
ACTION=="add", KERNELS=="0000:ca:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_rail6"
ACTION=="add", KERNELS=="0000:cc:00.0", SUBSYSTEM=="net", NAME="eth_sec5"
ACTION=="add", KERNELS=="0000:cc:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_sec5"
ACTION=="add", KERNELS=="0000:db:00.0", SUBSYSTEM=="net", NAME="eth_rail7"
ACTION=="add", KERNELS=="0000:db:00.0", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED roce_rail7"
~~~

And finally the OpenShift MachineConfig 99-machine-config-udev-network.yaml for the udev rule naming.

~~~bash
sh-5.1# cat 99-machine-config-udev-network.yaml 
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
   labels:
     machineconfiguration.openshift.io/role: worker
   name: 99-machine-config-udev-network
spec:
   config:
     ignition:
       version: 3.2.0
     storage:
       files:
       - contents:
           source: data:text/plain;charset=utf-8;base64,QUNUSU9OPT0iYWRkIiwgS0VSTkVMUz09IjAwMDA6MTg6MDAuMCIsIFNVQlNZU1RFTT09Im5ldCIsIE5BTUU9ImV0aF9yYWlsMCIKQUNUSU9OPT0iYWRkIiwgS0VSTkVMUz09IjAwMDA6MTg6MDAuMCIsIFNVQlNZU1RFTT09ImluZmluaWJhbmQiLCBQUk9HUkFNPSJyZG1hX3JlbmFtZSAlayBOQU1FX0ZJWEVEIHJvY2VfcmFpbDAiCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOjFhOjAwLjAiLCBTVUJTWVNURU09PSJuZXQiLCBOQU1FPSJldGhfc2VjMCIKQUNUSU9OPT0iYWRkIiwgS0VSTkVMUz09IjAwMDA6MWE6MDAuMCIsIFNVQlNZU1RFTT09ImluZmluaWJhbmQiLCBQUk9HUkFNPSJyZG1hX3JlbmFtZSAlayBOQU1FX0ZJWEVEIHJvY2Vfc2VjMCIKQUNUSU9OPT0iYWRkIiwgS0VSTkVMUz09IjAwMDA6M2E6MDAuMCIsIFNVQlNZU1RFTT09Im5ldCIsIE5BTUU9ImV0aF9yYWlsMSIKQUNUSU9OPT0iYWRkIiwgS0VSTkVMUz09IjAwMDA6M2E6MDAuMCIsIFNVQlNZU1RFTT09ImluZmluaWJhbmQiLCBQUk9HUkFNPSJyZG1hX3JlbmFtZSAlayBOQU1FX0ZJWEVEIHJvY2VfcmFpbDEiCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOjRkOjAwLjAiLCBTVUJTWVNURU09PSJuZXQiLCBOQU1FPSJldGhfcmFpbDIiCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOjRkOjAwLjAiLCBTVUJTWVNURU09PSJpbmZpbmliYW5kIiwgUFJPR1JBTT0icmRtYV9yZW5hbWUgJWsgTkFNRV9GSVhFRCByb2NlX3JhaWwyIgpBQ1RJT049PSJhZGQiLCBLRVJORUxTPT0iMDAwMDo1ZDowMC4wIiwgU1VCU1lTVEVNPT0ibmV0IiwgTkFNRT0iZXRoX3JhaWwzIgpBQ1RJT049PSJhZGQiLCBLRVJORUxTPT0iMDAwMDo1ZDowMC4wIiwgU1VCU1lTVEVNPT0iaW5maW5pYmFuZCIsIFBST0dSQU09InJkbWFfcmVuYW1lICVrIE5BTUVfRklYRUQgcm9jZV9yYWlsMyIKQUNUSU9OPT0iYWRkIiwgS0VSTkVMUz09IjAwMDA6NWY6MDAuMCIsIFNVQlNZU1RFTT09Im5ldCIsIE5BTUU9ImV0aF9zZWMxIgpBQ1RJT049PSJhZGQiLCBLRVJORUxTPT0iMDAwMDo1ZjowMC4wIiwgU1VCU1lTVEVNPT0iaW5maW5pYmFuZCIsIFBST0dSQU09InJkbWFfcmVuYW1lICVrIE5BTUVfRklYRUQgcm9jZV9zZWMxIgpBQ1RJT049PSJhZGQiLCBLRVJORUxTPT0iMDAwMDo1ZjowMC4xIiwgU1VCU1lTVEVNPT0ibmV0IiwgTkFNRT0iZXRoX3NlYzIiCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOjVmOjAwLjEiLCBTVUJTWVNURU09PSJpbmZpbmliYW5kIiwgUFJPR1JBTT0icmRtYV9yZW5hbWUgJWsgTkFNRV9GSVhFRCByb2NlX3NlYzIiCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOjliOjAwLjAiLCBTVUJTWVNURU09PSJuZXQiLCBOQU1FPSJldGhfcmFpbDQiCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOjliOjAwLjAiLCBTVUJTWVNURU09PSJpbmZpbmliYW5kIiwgUFJPR1JBTT0icmRtYV9yZW5hbWUgJWsgTkFNRV9GSVhFRCByb2NlX3JhaWw0IgpBQ1RJT049PSJhZGQiLCBLRVJORUxTPT0iMDAwMDpiYTowMC4wIiwgU1VCU1lTVEVNPT0ibmV0IiwgTkFNRT0iZXRoX3JhaWw1IgpBQ1RJT049PSJhZGQiLCBLRVJORUxTPT0iMDAwMDpiYTowMC4wIiwgU1VCU1lTVEVNPT0iaW5maW5pYmFuZCIsIFBST0dSQU09InJkbWFfcmVuYW1lICVrIE5BTUVfRklYRUQgcm9jZV9yYWlsNSIKQUNUSU9OPT0iYWRkIiwgS0VSTkVMUz09IjAwMDA6YmM6MDAuMCIsIFNVQlNZU1RFTT09Im5ldCIsIE5BTUU9ImV0aF9zZWMzIgpBQ1RJT049PSJhZGQiLCBLRVJORUxTPT0iMDAwMDpiYzowMC4wIiwgU1VCU1lTVEVNPT0iaW5maW5pYmFuZCIsIFBST0dSQU09InJkbWFfcmVuYW1lICVrIE5BTUVfRklYRUQgcm9jZV9zZWMzIgpBQ1RJT049PSJhZGQiLCBLRVJORUxTPT0iMDAwMDpiYzowMC4xIiwgU1VCU1lTVEVNPT0ibmV0IiwgTkFNRT0iZXRoX3NlYzQiCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOmJjOjAwLjEiLCBTVUJTWVNURU09PSJpbmZpbmliYW5kIiwgUFJPR1JBTT0icmRtYV9yZW5hbWUgJWsgTkFNRV9GSVhFRCByb2NlX3NlYzQiCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOmNhOjAwLjAiLCBTVUJTWVNURU09PSJuZXQiLCBOQU1FPSJldGhfcmFpbDYiCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOmNhOjAwLjAiLCBTVUJTWVNURU09PSJpbmZpbmliYW5kIiwgUFJPR1JBTT0icmRtYV9yZW5hbWUgJWsgTkFNRV9GSVhFRCByb2NlX3JhaWw2IgpBQ1RJT049PSJhZGQiLCBLRVJORUxTPT0iMDAwMDpjYzowMC4wIiwgU1VCU1lTVEVNPT0ibmV0IiwgTkFNRT0iZXRoX3NlYzUiCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOmNjOjAwLjAiLCBTVUJTWVNURU09PSJpbmZpbmliYW5kIiwgUFJPR1JBTT0icmRtYV9yZW5hbWUgJWsgTkFNRV9GSVhFRCByb2NlX3NlYzUiCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOmRiOjAwLjAiLCBTVUJTWVNURU09PSJuZXQiLCBOQU1FPSJldGhfcmFpbDciCkFDVElPTj09ImFkZCIsIEtFUk5FTFM9PSIwMDAwOmRiOjAwLjAiLCBTVUJTWVNURU09PSJpbmZpbmliYW5kIiwgUFJPR1JBTT0icmRtYV9yZW5hbWUgJWsgTkFNRV9GSVhFRCByb2NlX3JhaWw3Igo=
         filesystem: root
         mode: 420
         path: /etc/udev/rules.d/70-persistent-net.rules
~~~

This next system was a SuperMicro AMD Instinct type system which had the following devices in it:

* 8 x MI325X - Device ID 1002:74a5
* 7 x AMD Pensando Systems POLLARA-1Q400 100/200/400G 1-port Card - Device ID 1dd8:1002
* 1 x NVIDIA ConnectX-7 - Device ID 15b3:1021

One this system since it had multiple network card types associated with GPUs we got to test out how it behaved.  One caveat on this system was that Dmidecode and lspci both failed to show the physical slot number for the Pollara cards while the CX7 card showed its physical slot just fine.

~~~bash
# ./gpu-nic-rail-mapping -g 1002:74a5 -n 1dd8:1002,15b3:1021 -u 70-persistent-net.rules -r worker

 GPU BusAddr   NIC BusAddr PCIe Switch             NIC Slot    NIC Port   UDEV Eth    UDEV IB
====================================================================================================
 05:00.0       09:00.0     00:01.1/01:00.0         NA          1          eth_rail0   roce_rail0             
 15:00.0       19:00.0     10:01.1/11:00.0         NA          1          eth_rail1   roce_rail1             
 65:00.0       69:00.0     60:01.1/61:00.0         NA          1          eth_rail2   roce_rail2             
 75:00.0       79:00.0     70:01.1/71:00.0         NA          1          eth_rail3   roce_rail3             
 85:00.0       89:00.0     80:01.1/81:00.0         NA          1          eth_rail4   roce_rail4             
 95:00.0       99:00.0     90:01.1/91:00.0         NA          1          eth_rail5   roce_rail5             
 e5:00.0       e6:00.0     e0:01.1/e1:00.0          1          1          eth_rail6   roce_rail6             
 f5:00.0       f9:00.0     f0:01.1/f1:00.0         NA          1          eth_rail7   roce_rail7             
Generated 99-machine-config-udev-network.yaml file for OpenShift
~~~

Whilst a 70-persistent-net.rules file and 99-machine-config-udev-network.yaml MachineConfig were generated here as well they look very much like the H200 examples.

Finally I have an example where I converted the script to run remotely against OpenShift node.

~~~bash
$ ./remote-gpu-nic-rail-mapping.sh -g 10de:2335 -n 15b3:a2dc -u 70-persistent-net.rules -r worker -c dell-h200-2

 GPU BusAddr   NIC BusAddr PCIe Switch             NIC Slot    NIC Port   UDEV Eth    UDEV IB
====================================================================================================
 1b:00.0       18:00.0     15:01.0/16:00.0         40          1          eth_rail0   roce_rail0             
 1b:00.0       1a:00.0     15:01.0/16:00.0         42          1           eth_sec0    roce_sec0             
 3c:00.0       3a:00.0     37:01.0/38:00.0         41          1          eth_rail1   roce_rail1             
 4b:00.0       4d:00.0     48:01.0/49:00.0         38          1          eth_rail2   roce_rail2             
 5c:00.0       5d:00.0     59:01.0/5a:00.0         37          1          eth_rail3   roce_rail3             
 5c:00.0       5f:00.0     59:01.0/5a:00.0         39          1           eth_sec1    roce_sec1             
 5c:00.0       5f:00.1     59:01.0/5a:00.0         39          2           eth_sec2    roce_sec2             
 9a:00.0       9b:00.0     97:01.0/98:00.0         32          1          eth_rail4   roce_rail4             
 bb:00.0       ba:00.0     b7:01.0/b8:00.0         31          1          eth_rail5   roce_rail5             
 bb:00.0       bc:00.0     b7:01.0/b8:00.0         33          1           eth_sec3    roce_sec3             
 bb:00.0       bc:00.1     b7:01.0/b8:00.0         33          2           eth_sec4    roce_sec4             
 cd:00.0       ca:00.0     c7:01.0/c8:00.0         36          1          eth_rail6   roce_rail6             
 cd:00.0       cc:00.0     c7:01.0/c8:00.0         34          1           eth_sec5    roce_sec5             
 dc:00.0       db:00.0     d7:01.0/d8:00.0         35          1          eth_rail7   roce_rail7             
Generated 99-machine-config-udev-network.yaml file for OpenShift
~~~

That way we do not have to copy the script to the node itself and instead can rely on remote command action.

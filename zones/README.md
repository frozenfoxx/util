# Zone Configuration
This is a quick example of how to bootstrap Solaris Zones.

# Example Layout
+ zone1
  - FSS pool = zone1-pool
  - CPU Shares = 10
+ zone2
  - FSS pool = zone2-pool
  - CPU Shares = 10
+ zone3
  - FSS pool = zone3-pool
  - CPU Shares = 10
+ global
  - FSS pool = N/A
  - CPU Shares = 20, configured at boot time
  - Command to configure:  prctl -n zone.cpu-shares -v 20 -r -i -zone global

# Example
## Create/Install a New Zone
```
global:/export/home/root # zonecfg -z zone1   
zone1: No such zone configured
Use 'create' to begin configuring a new zone.
zonecfg:zone1> create -b
zonecfg:zone1> set autoboot=true
zonecfg:zone1> set zonepath=/zones_pool/zone1
zonecfg:zone1> add net
zonecfg:zone1:net> set address=100.1.100.1
zonecfg:zone1:net> set physical=bge0
zonecfg:zone1:net> end
zonecfg:zone1> info
zonename: zone1
zonepath: /zones_pool/zone1
brand: native
autoboot: true
bootargs: 
pool: 
limitpriv: 
scheduling-class: 
ip-type: shared
net:
        address: 100.1.100.1
        physical: bge0
        defrouter not specified
zonecfg:zone1> verify
zonecfg:zone1> commit
zonecfg:zone1> exit
global:/zones_pool # zoneadm -z zone1 verify
global:/zones_pool # zoneadm -z zone1 install
A ZFS file system has been created for this zone.
Preparing to install zone <zone1>.
Creating list of files to copy from the global zone.
Copying <153111> files to the zone.
Initializing zone product registry.
Determining zone package initialization order.
Preparing to initialize <1337> packages on the zone.
Initialized <1337> packages on zone.                                 
Zone <zone1> is initialized.
The file </zones_pool/zone1/root/var/sadm/system/logs/install_log> contains a log of the zone installation.
global:/zones_pool/ # zoneadm -z zone1 boot
```
## Create Pool for Fair System Scheduling (FSS)
1. Manually add pool configuration to poolcfg-options script
```
	"create pool zone1-pool ( string pool.scheduler = "FSS" )"
```
2. Run the following commands using that script
```
	pooladm -x; pooladm -s; poolcfg -f poolcfg-options; pooladm -c
```
3. Add pool to zone configuration
```
	global:/zones_pool # zonecfg -z zone1
	zonecfg:zone1> set pool=zone1-pool
	zonecfg:zone1> add rctl
	zonecfg:zone1:rctl> set name=zone.cpu-shares
	zonecfg:zone1:rctl> add value (priv=privileged,limit=10,action=none)
	zonecfg:zone1:rctl> end
	zonecfg:zone1> verify
	zonecfg:zone1> exit
```
4. Verify pool configuration
```
	global:/zones_pool # prctl -n zone.cpu-shares -i zone zone1
```
## Verify Zone and Pool
```
global:/export/home/root # zoneadm -z zone1 halt
global:/export/home/root # zoneadm -z zone1 boot
global:/export/home/root # zoneadm list -cv
```

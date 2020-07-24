# Manage ESX snapshots

### Set environment

> :warning: Adapt settings to fit to your environment.

> :information_source: Run this on ESX

```
SNAPNAME="OCPInstalled"

WORKERS_PATTERN="[w][1-5]"
OTHERS_PATTERN="[m][1-5]|bs|cli"
ALL_PATTERN="[mw][1-5]|bs|cli"
```
<br>

### Stop workers

> :information_source: Run this on ESX

```
vim-cmd vmsvc/getallvms | awk '$2 ~ "'$WORKERS_PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.shutdown " $1}' | sh

watch -n 10 vim-cmd vmsvc/getallvms | awk '$2 ~ "'$WORKERS_PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh
```

> :bulb: Leave watch with **Ctrl + c** when everyone is **powered off**

<br>

### Stop others

> :information_source: Run this on ESX

```
vim-cmd vmsvc/getallvms | awk '$2 ~ "'$OTHERS_PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.shutdown " $1}' | sh

watch -n 10 vim-cmd vmsvc/getallvms | awk '$2 ~ "'$OTHERS_PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh
```

> :bulb: Leave watch with **Ctrl + c** when everyone is **powered off**

<br>

### -  [Make snaphot](#make-snapshot)
### -  [Revert snaphot](#revert-snapshot)
### -  [Start all](#start-all)

<br>

### Make snapshot

> :information_source: Run this on ESX

```
vim-cmd vmsvc/getallvms | awk '$2 ~ "'$ALL_PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " '$SNAPNAME' "}' | sh
```

<br>

### Revert snapshot

> :information_source: Run this on ESX

```
for vmid in $(vim-cmd vmsvc/getallvms | awk 'NR>1 && $2 ~ "'$ALL_PATTERN'" {print $1}'); \
do \
vim-cmd vmsvc/snapshot.get $vmid | grep -A 1 'Snapshot Name\s\{1,\}: '$SNAPNAME | awk -F' : ' 'NR>1 {print "vim-cmd vmsvc/snapshot.revert "'$vmid'" " $2 " suppressPowerOn"}' | sh; \
done
```
<br>

### Start all

```
vim-cmd vmsvc/getallvms | awk '$2 ~ "'$ALL_PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

watch -n 10 vim-cmd vmsvc/getallvms | awk '$2 ~ "'$OTHERS_PATTERN'" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh
```

> :bulb: Leave watch with **Ctrl + c** when everyone is **powered off**

<br>

:checkered_flag::checkered_flag::checkered_flag:
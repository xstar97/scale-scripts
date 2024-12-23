# scale-scripts
a bunch of noob scripts for truenas scale.

Grab the next IP by running this command.
  optional flags:
  - list-apps

## metallb IPs
```shell
curl -sSL https://raw.githubusercontent.com/xstar97/scale-scripts/main/scripts/NextAvailableIP.sh | bash -s
```
```shell
curl -sSL https://raw.githubusercontent.com/xstar97/scale-scripts/main/scripts/NextAvailableIP.sh | bash -s list-apps
```


## smb auxillary param


```shell
curl -sSL https://raw.githubusercontent.com/xstar97/scale-scripts/refs/heads/main/scripts/smbAuxUpdater.sh | bash --
```

## Patch TrueCharts Trains

update current charts to the latest trains name.

```shell
curl -sSL https://raw.githubusercontent.com/xstar97/scale-scripts/main/scripts/patchTCTrains.sh | bash --
```

## Patch PVC StorageClass

update PVC storageClass with SCALE-ZFS

ALl charts will be checked but wont be updated.

```shell
curl -sSL https://raw.githubusercontent.com/xstar97/scale-scripts/main/scripts/pvcStorageClassUpater.sh | bash -s -- --dry-run
```

Check a single Chart with the dry run flag.

```shell
curl -sSL https://raw.githubusercontent.com/xstar97/scale-scripts/main/scripts/pvcStorageClassUpater.sh | bash -s -- --dry-run --app APP
```

All charts will be checked and updated.

```shell
curl -sSL https://raw.githubusercontent.com/xstar97/scale-scripts/main/scripts/pvcStorageClassUpater.sh | bash -s --
```

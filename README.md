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

download the script

```shell
wget https://raw.githubusercontent.com/xstar97/scale-scripts/main/scripts/smbAuxUpdater.sh
```

edit the script and change some values that say CHANGE_ME.
- BASE_URL
- AUTH_TOKEN
- SMB_USERS

```shell
nano smbAuxUpdater.sh
```

make the script executable and run it.

```shell
chmod +x smbAuxUpdater.sh
```

```shell
smbAuxUpdater.sh
```

## Patch TrueCharts Trains

update current charts to the latest trains name.

```shell
curl -sSL https://raw.githubusercontent.com/xstar97/scale-scripts/main/scripts/patchTCTrains.sh | bash -s
```

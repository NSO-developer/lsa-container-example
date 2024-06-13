#!/bin/sh

docker exec -i nso_upper ncs_cli -u admin >/dev/null <<EOF2
config
set cluster device-notifications enabled
set cluster remote-node lower-nso-1 address 10.0.0.3 port 2024 authgroup default username admin
set cluster remote-node lower-nso-2 address 10.0.0.4 port 2024 authgroup default username admin
set cluster commit-queue enabled
set services global-settings collect-forward-diff true
commit
request cluster remote-node lower-nso-1 ssh fetch-host-keys
request cluster remote-node lower-nso-2 ssh fetch-host-keys
set ncs:devices device lower-nso-1 device-type netconf ned-id lsa-netconf
set ncs:devices device lower-nso-1 authgroup default
set ncs:devices device lower-nso-1 lsa-remote-node lower-nso-1
set ncs:devices device lower-nso-1 state admin-state unlocked
set ncs:devices device lower-nso-2 device-type netconf ned-id lsa-netconf
set ncs:devices device lower-nso-2 authgroup default
set ncs:devices device lower-nso-2 lsa-remote-node lower-nso-2
set ncs:devices device lower-nso-2 state admin-state unlocked
commit
request ncs:devices fetch-ssh-host-keys
request ncs:devices sync-from
set cfs-vlan:devices device ex0 lower-node lower-nso-1
set cfs-vlan:devices device ex1 lower-node lower-nso-1
set cfs-vlan:devices device ex2 lower-node lower-nso-1
set cfs-vlan:devices device fx0 lower-node lower-nso-2
set cfs-vlan:devices device fx1 lower-node lower-nso-2
set cfs-vlan:devices device fx2 lower-node lower-nso-2
commit
exit
EOF2
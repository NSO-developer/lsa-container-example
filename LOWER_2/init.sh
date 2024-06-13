#!/bin/sh

docker exec -i nso_lower_2 ncs_cli -u admin >/dev/null <<EOF2
request ncs:devices fetch-ssh-host-keys
request ncs:devices sync-from
EOF2
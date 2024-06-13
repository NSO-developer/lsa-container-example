#!/bin/sh

docker exec -i nso_upper ncs_cli -u admin >/dev/null <<EOF2
config
request ncs:devices sync-from
exit
EOF2
#!/bin/bash


var1=$(docker exec -i nso-prod ncs_cli -C -u admin <<< "exit" &> /dev/null ; echo $?)
Data1=$(($var1))

echo "NSO Status: "
echo -ne "NOT READY: NSO Status: $var1\033[0K\r"

while [ $Data1 -ne 0 ]
do
var1=$(docker exec -i nso-prod ncs_cli -C -u admin <<< "exit" &> /dev/null ; echo $?)
Data1=$(($var1))

echo -ne "NOT READY: NSO Status: $var1\033[0K\r"
sleep 5
done

#sleep 2
echo -e "READY: NSO Up\033[0K\r"
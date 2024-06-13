#!/bin/bash


var1=$(docker exec -i nso_upper ncs_cli -C -u admin <<< "exit" &> /dev/null ; echo $?)
Data1=$(($var1))
var2=$(docker exec -i nso_lower_1 ncs_cli -C -u admin <<< "exit" &> /dev/null ; echo $?)
Data2=$(($var2))
var3=$(docker exec -i nso_lower_2 ncs_cli -C -u admin <<< "exit" &> /dev/null ; echo $?)
Data3=$(($var3))
Result=$(($Data1+$Data2+$Data3))

echo "NSO Status: "
echo -ne "NOT READY: UPPER Status: $var1 / LOWER_1 Status: $var2 / LOWER_2 Status: $var3\033[0K\r"

while [ $Result -ne 0 ]
do
var1=$(docker exec -i nso_upper ncs_cli -C -u admin <<< "exit" &> /dev/null ; echo $?)
Data1=$(($var1))
var2=$(docker exec -i nso_lower_1 ncs_cli -C -u admin <<< "exit" &> /dev/null ; echo $?)
Data2=$(($var2))
var3=$(docker exec -i nso_lower_2 ncs_cli -C -u admin <<< "exit" &> /dev/null ; echo $?)
Data3=$(($var3))
Result=$(($Data1+$Data2+$Data3))

echo -ne "NOT READY: UPPER Status: $var1 / LOWER_1 Status: $var2 / LOWER_2 Status: $var3\033[0K\r"
sleep 5
done

#sleep 2
echo -e "READY: UPPER, LOWER_1 and LOWER_2 Up\033[0K\r"
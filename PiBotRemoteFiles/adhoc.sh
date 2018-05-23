#!/usr/bin/
line=$(head -n 1 /etc/network/interfaces)
echo before: $line
cp interfacesAdHoc /etc/network/interfaces
line=$(head -n 1 /etc/network/interfaces)
echo after: $line

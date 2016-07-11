#!/bin/bash

# Check internet access

# -q quiet
# -c nb of pings to perform
   
ping -q -c2 google.com > /dev/null
      
if [ $? -eq 0 ] 
then
	echo "internet access OK"
else
        echo "internet inaccessible, rebooting..."
        reboot
fi

# Check local network

#ip a | sed -rn '/: '"eth0"':.*state UP/{N;N;s/.*inet (\S*).*/\1/p}' | grep -Eq '192\.168\.42\.1' || (echo "eth0 is not configured, rebooting..." ; reboot)
ip a | grep -Eq '192\.168\.42\.1' || (echo "eth0 is not configured, rebooting..." ; reboot)

                              
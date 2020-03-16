#!/bin/bash
#
# TCP and UDP dummy traffic test for Collector
#
#	send_collector_test_data.sh IP PROTOCOL PORT [number of messages]
#
#	This script is intended to aid in troubleshooting Rapid7 InsightIDR collectors.
#	It sends some example syslogs to a Collector to confirm if traffic is being:
#		1) recieved by the Collector (check with commands on Collector)
#		2) the Collector is sending the events to the platform (seen on Insight Platform web app)
#
# By default, this script will send 10 test log lines to a Collector to test the connection, but you
#	can specify a different number using the last optional parameter
#
# This script will work with any syslog event source, including the raw log event sources.
# Designed and tested on OS X 10.14.6 with bash version 3.2.57(1)-release (x86_64-apple-darwin18)
#
# Example usage:
#	Listen command on the collector for TCP: tcpflow -c  -i ens33 port 6667
#	./send_collector_test_data.sh 172.16.1.137 TCP 6667
#
#	Listen command on the collector for UDP: tcpdump -i ens33 udp port 6666 -X
#	./send_collector_test_data.sh 172.16.1.137 UDP 6666
#
#	Send 30 log events on UDP 6666 instead of default 10 events
#	./send_collector_test_data.sh 172.16.1.137 UDP 6666 30
#
#	Another command to see which ports are open on collector, includes both TCP and UDP
#	ss -tulwn
#
#	TODO: convert file to local variable

# bomb out immediately if any error occur
set -e

# pull in Bash parameters, required and will fail if they aren't specified
COLLECTOR_HOST="$1"
COLLECTOR_PROTOCOL="$2" # can be UDP or TCP, case sensitive
COLLECTOR_PORT="$3"
MESSAGE_COUNT="${4:-10}" # final parameter is optional, defaults to 10 if not specified
MSG_DATA="sendData-$RANDOM.txt"

# pull some other variables that will be sent with messages
HNAME=$(hostname)
PUBLIC_IP=$(curl -sSf ifconfig.co)

# loop through count of messages
for i in $(seq 1 "$MESSAGE_COUNT")
do
	# store the message before transmission
	echo "$(date)  message_number=$i/$MESSAGE_COUNT, TARGET HOST=$COLLECTOR_HOST, TARGET PORT=$COLLECTOR_PORT, PROTOCOL=$COLLECTOR_PROTOCOL, SOURCE PUBLIC IP=$PUBLIC_IP, SOURCE HOSTNAME=$HNAME" > "$MSG_DATA"

	# sleep for 1 second every 3 posts to ensure timestamp changes
	if ! ((i % 3)); then
	    sleep 1
	fi

	# send messages different ways depending on if it is UDP or TCP
	if [ "$COLLECTOR_PROTOCOL" == "UDP" ]; then
		# send a UDP message without confirmation
 		cat "$MSG_DATA" > "/dev/udp/$COLLECTOR_HOST/$COLLECTOR_PORT"
		cat "$MSG_DATA"
	elif [ "$COLLECTOR_PROTOCOL" == "TCP" ]; then
		# send TCP message using netcat, if it fails then bail
		if nc -n "$COLLECTOR_HOST" "$COLLECTOR_PORT" < "$MSG_DATA" ; then
			# post it to the screen if successful
			cat "$MSG_DATA"
		else
			echo "failed to send message, could not connect to target. Exiting..."
			exit 1
		fi
	else
		# unsupported protocol, fail
		echo "Protocol must be either UDP or TCP and is case sensitive: $COLLECTOR_PROTOCOL"
		exit 2
	fi

done

# post final message
if [ "$COLLECTOR_PROTOCOL" == "UDP" ]; then
	echo "Sent UDP messages, unable to confirm if they were recieved due to nature of UDP"
else
	echo "all TCP sends were successful."
fi

# clean up temp file
rm "$MSG_DATA"

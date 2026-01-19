#!/bin/bash

# MQTT Sample Data Publisher
# Usage: ./publish_mqtt_sample.sh <room> <temp> <humidity>
# Example: ./publish_mqtt_sample.sh c201 21.5 45.2

if [ $# -ne 3 ]; then
    echo "Usage: $0 <room> <temperature> <humidity>"
    echo "Example: $0 c201 21.5 45.2"
    exit 1
fi

ROOM=$1
TEMP=$2
HUMIDITY=$3

mosquitto_pub -h localhost -p 1883 -t "sensors/$ROOM" -m "{
  \"temp\": $TEMP,
  \"humidity\": $HUMIDITY
}"

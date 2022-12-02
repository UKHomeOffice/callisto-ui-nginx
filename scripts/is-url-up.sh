#!/bin/sh

echo "Checking url: $1"

seconds=0
response=0
while [ "$seconds" -lt 60 ] && [ "$response" -ne 200 ]; do 
  seconds=$((seconds+1)); 
  response=$(curl --write-out '%{http_code}' --silent --output /dev/null $1)
  sleep 1
done

if [ "$response" -ne 200 ]; then
  echo "$1 is down"
  exit 1
else
  echo "$1 is up"
fi
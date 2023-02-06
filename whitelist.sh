#!/usr/bin/env bash
set -x

cd /Users/SRaja/copy-infrastructure-live/dev/us-east-1/dev/services/frontend-site

mkdir test

readFile='/Users/SRaja/copy-infrastructure-live/add.yml'
# targetFile is where we will write to
targetFile="/Users/SRaja/copy-infrastructure-live/dev/us-east-1/dev/services/frontend-site/ipv4.yaml"

envsubst < "$readFile" >> "$targetFile"

cat "$targetFile"

#!/usr/bin/env bash
set -x

#cd /Users/SRaja/copy-infrastructure-live/dev/us-east-1/dev/services/frontend-site

#mkdir test

ENV=$1

read commitmessage
 
echo "Enter commit message:"=$2 

git pull

git branch

git checkout -b feature/add-ip-addresses-into-cloudfront-whitelist

git branch

readFile='/Users/SRaja/whitelistip/add.yml'
# targetFile is where we will write to
targetFile="/Users/SRaja/whitelistip/$ENV/us-east-1/$ENV/services/frontend-site/ipv4.yaml"

envsubst < "$readFile" >> "$targetFile"

git add .

git commit -m "$"commitmessage:""

git push --set-upstream origin feature/add-ip-addresses-into-cloudfront-whitelist

#cat "$targetFile"

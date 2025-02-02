#!/bin/bash
set -x
################################################################################
# File:    signRelease.sh
# Purpose: Script that signs our pre-releases. This should be called by the
#          sign_workflow, which is triggered by the build script. This is kept
#          seperate from the build scripts so it doesn't have to be implemented
#          on multiple platforms.
#
#          * https://github.com/BusKill/buskill-app/issues/4
#
# Authors: Michael Altfield <michael@buskill.in>
# Created: 2020-07-12
# Updated: 2020-07-12
# Version: 0.1
################################################################################

################################################################################
#                                  SETTINGS                                    #
################################################################################

# n/a

################################################################################
#                                 MAIN BODY                                    #
################################################################################

######################
# INPUT SANITIZATION #
######################

# our only input should consist of only numbers; strip everything else
RELEASE_ID="${RELEASE_ID//[^0-9]}"

###################
# INSTALL DEPENDS #
###################

apt-get update
apt-get -y install curl jq gpg

###########################
# DOWNLOAD RELEASE ASSETS #
###########################

tmpDir="`mktemp -d`"
pushd "${tmpDir}"

curl --silent --location --header "authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/buskill/buskill-app/releases/${RELEASE_ID}" | jq --raw-output '.assets[].browser_download_url' | xargs curl --location --remote-name-all

######################
# PREPARE NEW ASSETS #
######################

du -sh *
sha256sum * > SHA256SUMS

echo "${BUSKILL_PRERELEASE_PGP_KEY}" | gpg --import
gpg --armor --detach-sign SHA256SUMS

#####################
# UPLOAD NEW ASSETS #
#####################

curl --location --header "authorization: token ${GITHUB_TOKEN}" --header "Content-Type: text/plain" --data-binary @SHA256SUMS "https://uploads.github.com/repos/buskill/buskill-app/releases/${RELEASE_ID}/assets?name=SHA256SUMS"
curl --location --header "authorization: token ${GITHUB_TOKEN}" --header "Content-Type: text/plain" --data-binary @SHA256SUMS.asc "https://uploads.github.com/repos/buskill/buskill-app/releases/${RELEASE_ID}/assets?name=SHA256SUMS.asc"

##################
# CLEANUP & EXIT #
##################

# exit cleanly
exit 0

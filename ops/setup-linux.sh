#!/bin/bash

# This script should be idempotent, ie. you should be able to run it
# twice or thrice and it ends up in the same state as running it once.
# (Until dependencies change – when they change, running it again will
# update dependencies.)

# To use, scp it to an Ubuntu/Debian machine (to whatever path,
# doesn't matter) and run it with sudo / as root.

set -euo pipefail

export LC_ALL=C.UTF-8
export iso639=sme
export bcp47=se
export pipename="${iso639}"gramrelease
export zcheck=/usr/share/voikko/4/"${bcp47}".zcheck
export package=giella-"${iso639}"-speller

# This is the modename expected by the woodwing js scripts, don't
# change without altering js scripts!:
export modename="${iso639}"-"${iso639}"_spell

apt-get install -y --no-install-recommends \
        curl                               \
        lsb-release                        \
        git                                \
        python3-minimal                    \
        python3-tornado                    \
        unzip

curl -sS https://apertium.projectjj.com/apt/install-nightly.sh >install-nightly.sh
bash install-nightly.sh
apt-get install -f -y apertium-all-dev divvun-gramcheck
apt-get install -y --no-install-recommends giella-sme giella-sme-speller

rm -rf /data
mkdir /data
unzip -d /data "${zcheck}"

rm -rf /modes
mkdir /modes
divvun-gen-sh -j /data/pipespec.xml "${pipename}" \
    | grep -v '^#'                                \
    | tr '\n' ' '                                 \
    | sed 's/\\ //g'                              \
    > /modes/"${modename}".mode

rm -rf /apy
git clone -b divvunWoodwing https://github.com/apertium/apertium-apy /apy

useradd apertium || true

cp /apy/tools/systemd/apy.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable apy.service
systemctl restart apy.service

sleep 3
systemctl status apy.service

curl 'http://10.35.10.13:2737/translateRaw' -X POST --data-raw 'langpair=sme%7Csme_spell&q=B%C3%A1ikk%C3%A1la%C5%A1+arttistaid+galget'; echo

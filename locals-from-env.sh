#!/bin/sh
# This file reads data from the OS and user files (e.g. ssh public key)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    REALNAME="$(getent passwd ${USER} | cut -d: -f5)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    REALNAME="$(dscl . -read /Users/${USER} RealName | cut -d: -f2 | sed -e 's/^[ \t]*//' | grep -v "^$")"
fi

# If possible find the URL of the Github repo where this code lives
PROVENANCE=""
if which -s git; then
  if REMOTE=$(git config --get remote.origin.url) 2>/dev/null; then
    PROVENANCE=${REMOTE}
  fi
fi
CURRENT_DATETIME=$(date -Iseconds)

# I prefer ed25519 keys if existing and fall back to RSA
PUBLIC_SSH_KEY=""
if [ -f "${HOME}/.ssh/id_ed25519.pub" ]; then
  PUBLIC_SSH_KEY=$(<"${HOME}/.ssh/id_ed25519.pub")
elif [ -f "${HOME}/.ssh/id_rsa.pub" ]; then
  PUBLIC_SSH_KEY=$(<"${HOME}/.ssh/id_rsa.pub")
fi

# Change the contents of this output to get the environment variables
# of interest. The output must be valid JSON, with strings for both
# keys and values.

cat <<EOF
{
  "public_ssh_key": "${PUBLIC_SSH_KEY}"
}
EOF

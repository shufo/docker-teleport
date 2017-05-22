#!/bin/sh

TELEPORT_CONFIG=/etc/teleport.yml

# nodename
TELEPORT_NODENAME=${TELEPORT_NODENAME:-localhost}
OPTS="$OPTS --nodename $TELEPORT_NODENAME"

# use config file if file exists
if [[ -e $TELEPORT_CONFIG ]]; then
  teleport start $OPTS -c $TELEPORT_CONFIG
  exit 0
fi

# roles
TELEPORT_ROLES=${TELEPORT_ROLES:-auth,proxy,node}
OPTS="$OPTS --roles $TELEPORT_ROLES"

# auth server
if [[ -n "$TELEPORT_AUTH_SERVER" ]]; then
  OPTS="$OPTS --auth-server $TELEPORT_AUTH_SERVER"
fi

# token
if [[ -n "$TELEPORT_TOKEN" ]]; then
  OPTS="$OPTS --token $TELEPORT_TOKEN"
fi

teleport start ${OPTS}

#!/usr/bin/env bash
set -euo pipefail

# Save original LD_LIBRARY_PATH
templdpath=${LD_LIBRARY_PATH-}
export LD_LIBRARY_PATH="./linux64:${LD_LIBRARY_PATH-}"

export SteamAppId=892970
export BOX64_DYNAREC_BLEEDING_EDGE=0
export BOX64_DYNAREC_BIGBLOCK=0
export BOX64_DYNAREC_STRONGMEM=2

echo "Starting server - press CTRL-C to exit"

# Validate required server binary
if [ ! -x ./valheim_server.x86_64 ]; then
	echo "valheim_server.x86_64 not found or not executable in $(pwd)" >&2
	exit 1
fi

# Recommended: ensure env vars have defaults
VALHEIM_SERVER_NAME=${VALHEIM_SERVER_NAME:-GorniusValheimBox64}
VALHEIM_WORLD_NAME=${VALHEIM_WORLD_NAME:-Box64World}
VALHEIM_PASSWORD=${VALHEIM_PASSWORD:-box64pass}
VALHEIM_ISPUBLIC=${VALHEIM_ISPUBLIC:-0}

# Exec so this script becomes the server process (PID 1 inside container) and receives signals
exec box64 ./valheim_server.x86_64 -nographics -batchmode -name "$VALHEIM_SERVER_NAME" -world "$VALHEIM_WORLD_NAME" -password "$VALHEIM_PASSWORD" -public "$VALHEIM_ISPUBLIC"

# restore LD_LIBRARY_PATH on exit (in practice this line won't run because of exec)
export LD_LIBRARY_PATH=$templdpath

#!/usr/bin/env sh
set -eu
# safer stdout for debug
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
STEAMCMD_DIR="${SCRIPT_DIR}/../steamcmd"
SERVER_DIR="/root/server_files"

export DEBUGGER=/usr/local/bin/box86

mkdir -p "$SERVER_DIR"

if [ ! -x "$STEAMCMD_DIR/steamcmd.sh" ]; then
	echo "steamcmd not found in $STEAMCMD_DIR. Expecting steamcmd to be in that directory." >&2
	exit 1
fi

"$STEAMCMD_DIR/steamcmd.sh" +@sSteamCmdForcePlatformType linux +force_install_dir "$SERVER_DIR" +login anonymous +app_update 896660 +quit

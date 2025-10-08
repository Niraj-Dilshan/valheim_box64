#!/usr/bin/env sh
set -eu
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

cd "$ROOT_DIR"

sh "$SCRIPT_DIR/download_server_files.sh"

# Copy start script into server files dir if present
if [ -f "$SCRIPT_DIR/start_server.sh" ]; then
	cp "$SCRIPT_DIR/start_server.sh" /root/server_files/start_server.sh
	chmod +x /root/server_files/start_server.sh
fi

mkdir -p /root/.steam/sdk64/
if [ -f "$ROOT_DIR/steamcmd/linux64/steamclient.so" ]; then
	cp "$ROOT_DIR/steamcmd/linux64/steamclient.so" /root/.steam/sdk64/
fi

cd /root/server_files

# Use exec so signals are forwarded to the server process
exec sh ./start_server.sh

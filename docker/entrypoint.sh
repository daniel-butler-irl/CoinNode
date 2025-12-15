#!/bin/sh
# =============================================================================
# Bitcoin Core Entrypoint Script
# Handles signal forwarding for graceful shutdown and network configuration
# =============================================================================
set -e

BITCOIN_DATA="${BITCOIN_DATA:-/home/bitcoin/.bitcoin}"
BITCOIN_NETWORK="${BITCOIN_NETWORK:-mainnet}"

# -----------------------------------------------------------------------------
# Signal handler for graceful shutdown
# Uses bitcoin-cli stop for clean database shutdown
# -----------------------------------------------------------------------------
# shellcheck disable=SC2329  # Function is invoked via trap
shutdown_handler() {
    echo "[entrypoint] Received shutdown signal"
    if [ -n "${BITCOIND_PID:-}" ] && kill -0 "$BITCOIND_PID" 2>/dev/null; then
        echo "[entrypoint] Stopping bitcoind gracefully via bitcoin-cli..."
        bitcoin-cli -datadir="${BITCOIN_DATA}" "${NETWORK_FLAG:-}" stop 2>/dev/null || true
        echo "[entrypoint] Waiting for bitcoind to exit..."
        wait "$BITCOIND_PID" 2>/dev/null || true
    fi
    echo "[entrypoint] Shutdown complete"
    exit 0
}

# Trap signals for graceful shutdown
trap 'shutdown_handler' TERM INT HUP

# -----------------------------------------------------------------------------
# Determine network configuration
# -----------------------------------------------------------------------------
case "${BITCOIN_NETWORK}" in
    testnet)
        NETWORK_FLAG="-testnet"
        echo "[entrypoint] Starting in TESTNET mode"
        ;;
    regtest)
        NETWORK_FLAG="-regtest"
        echo "[entrypoint] Starting in REGTEST mode"
        ;;
    signet)
        NETWORK_FLAG="-signet"
        echo "[entrypoint] Starting in SIGNET mode"
        ;;
    mainnet|*)
        NETWORK_FLAG=""
        echo "[entrypoint] Starting in MAINNET mode"
        ;;
esac

# -----------------------------------------------------------------------------
# Build bitcoind arguments
# -----------------------------------------------------------------------------
if [ -n "${NETWORK_FLAG}" ]; then
    set -- "-datadir=${BITCOIN_DATA}" "-printtoconsole" "${NETWORK_FLAG}" "$@"
else
    set -- "-datadir=${BITCOIN_DATA}" "-printtoconsole" "$@"
fi

echo "[entrypoint] Starting bitcoind with args: $*"

# -----------------------------------------------------------------------------
# Start bitcoind
# Run in background to enable proper signal handling
# -----------------------------------------------------------------------------
bitcoind "$@" &
BITCOIND_PID=$!

# Wait for bitcoind process (allows signal handling to work)
wait "$BITCOIND_PID"
EXIT_CODE=$?

echo "[entrypoint] bitcoind exited with code: $EXIT_CODE"
exit $EXIT_CODE

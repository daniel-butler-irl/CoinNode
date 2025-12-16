#!/bin/sh
# =============================================================================
# Log IP Frequency Analyzer
# Parses web logs and outputs IP address counts sorted by frequency (descending)
# =============================================================================
set -e

# -----------------------------------------------------------------------------
# Usage: log-ip-freq.sh [logfile]
#   logfile - Path to log file (reads stdin if omitted)
#
# Expected log format:
#   [timestamp] <ip> <path> <verb> <user-agent>
#
# Example:
#   [29/Sep/2021:10:20:48+0100] 192.168.21.34 /healthz GET Mozilla/5.0 ...
# -----------------------------------------------------------------------------

input="${1:--}"

# Extract IP addresses (field 2), count occurrences, sort descending
# - /^\[/ ensures line starts with timestamp bracket (skips malformed lines)
# - NF >= 2 requires at least timestamp + IP
# - Final awk reformats from "count ip" to match expected output
awk '/^\[/ && NF >= 2 { print $2 }' "$input" | sort | uniq -c | sort -rn | awk '{ print $1, $2 }'

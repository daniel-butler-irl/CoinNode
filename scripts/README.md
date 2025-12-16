# Scripts

Utility scripts for CoinNode operations.

## Directory Structure

```
scripts/
├── sample.log      # Sample log file for testing
├── shell/          # Shell scripts
│   └── log-ip-freq.sh
└── python/         # Python scripts (managed with uv)
    └── log_ip_freq.py
```

## Shell Scripts

See [shell/README.md](shell/README.md) for shell script documentation.

## Python Scripts

See [python/README.md](python/README.md) for Python script documentation and setup instructions.

## Log IP Frequency Analyzer

Both shell and Python implementations parse web logs and output IP address frequency counts sorted descending.

### Usage

Shell:
```sh
./scripts/shell/log-ip-freq.sh scripts/sample.log
```

Python:
```sh
cd scripts/python && uv run log-ip-freq --file ../sample.log
```

### Expected Output

```
6 192.168.22.11
4 10.32.89.34
2 172.32.9.12
1 121.89.25.43
```

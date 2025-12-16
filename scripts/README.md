# Scripts

This directory contains utility scripts for development and operational tasks. Both shell and Python implementations are provided for the log analysis tool.

The shell script handles blank and malformed lines gracefully by filtering with awk. Only lines that start with a timestamp bracket and have at least two fields are processed, so malformed input does not affect the counts.

For the Python CLI tool, I chose Click over argparse. Click provides a simpler and more readable way to define command-line interfaces, with decorators that make the intent clear and reduce boilerplate. Unit tests are included for the aggregator function and CLI interface.

See [python/README.md](python/README.md) for Python setup and usage instructions.

See [shell/README.md](shell/README.md) for shell script documentation.

### Log IP Frequency Analyzer

Parses web logs and outputs IP address frequency counts sorted descending.

Shell:

```sh
./scripts/shell/log-ip-freq.sh scripts/sample.log
```

Python:

```sh
cd scripts/python && uv run log-ip-freq --file ../sample.log
```

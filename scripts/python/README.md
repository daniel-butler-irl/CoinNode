# Python Scripts

## log-ip-freq

Parses web logs and outputs IP address frequency counts sorted descending.

### Setup

```sh
cd scripts/python
uv sync
```

### Usage

With file argument:

```sh
uv run log-ip-freq --file ../sample.log
```

Or pipe from stdin:

```sh
cat ../sample.log | uv run log-ip-freq
```

### Expected Input Format

```
[timestamp] <ip> <path> <verb> <user-agent>
```

### Example Output

```
6 192.168.22.11
4 10.32.89.34
2 172.32.9.12
1 121.89.25.43
```

### Development

Lint and format:

```sh
uv run ruff check --fix
uv run ruff format
```

Run tests:

```sh
uv run pytest
```

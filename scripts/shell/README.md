# Shell Scripts

## log-ip-freq.sh

Parses web logs and outputs IP address frequency counts sorted descending.

### Usage

```sh
./scripts/shell/log-ip-freq.sh ../sample.log
```

Or pipe from stdin:

```sh
cat scripts/sample.log | ./scripts/shell/log-ip-freq.sh
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

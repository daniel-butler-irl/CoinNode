#!/usr/bin/env python3
"""Log IP Frequency Analyzer.

Parses web logs and outputs IP address counts sorted by frequency (descending).
"""

from collections import Counter

import click


def parse_log_lines(lines: list[str]) -> Counter[str]:
    """Extract IP addresses from log lines and count occurrences.

    Expected log format:
        [timestamp] <ip> <path> <verb> <user-agent>

    Lines must start with '[' and have at least 2 fields to be valid.

    Args:
        lines: List of log lines to parse.

    Returns:
        Counter of IP addresses.
    """
    ip_counter: Counter[str] = Counter()

    for line in lines:
        line = line.strip()
        if not line.startswith("["):
            continue

        fields = line.split()
        if len(fields) < 2:
            continue

        ip = fields[1]
        ip_counter[ip] += 1

    return ip_counter


def format_output(ip_counter: Counter[str]) -> str:
    """Format IP counts as 'count ip' lines sorted by frequency descending.

    Args:
        ip_counter: Counter of IP addresses.

    Returns:
        Formatted string with one 'count ip' per line.
    """
    sorted_ips = ip_counter.most_common()
    return "\n".join(f"{count} {ip}" for ip, count in sorted_ips)


@click.command()
@click.option(
    "--file",
    "input_file",
    type=click.File("r"),
    default="-",
    help="Path to log file. Reads from stdin if omitted.",
)
def main(input_file: click.utils.LazyFile) -> None:
    """Parse web logs and output IP address frequency counts."""
    lines = input_file.readlines()
    ip_counter = parse_log_lines(lines)

    if ip_counter:
        output = format_output(ip_counter)
        click.echo(output)


if __name__ == "__main__":
    main()

"""Tests for log_ip_freq module."""

from collections import Counter

import pytest
from click.testing import CliRunner
from log_ip_freq import format_output, main, parse_log_lines


class TestParseLogLines:
    """Tests for parse_log_lines function."""

    def test_valid_log_lines(self) -> None:
        """Test parsing valid log lines."""
        lines = [
            "[29/Sep/2021:10:20:48+0100] 192.168.22.11 /healthz GET Mozilla/5.0",
            "[29/Sep/2021:10:20:49+0100] 10.32.89.34 /api/status GET curl/7.68.0",
            "[29/Sep/2021:10:20:50+0100] 192.168.22.11 /healthz GET Mozilla/5.0",
        ]
        result = parse_log_lines(lines)
        assert result == Counter({"192.168.22.11": 2, "10.32.89.34": 1})

    def test_skips_malformed_lines(self) -> None:
        """Test that lines not starting with '[' are skipped."""
        lines = [
            "[29/Sep/2021:10:20:48+0100] 192.168.22.11 /healthz GET Mozilla/5.0",
            "malformed line without proper format",
            "",
            "[29/Sep/2021:10:20:49+0100] 10.32.89.34 /api/status GET curl/7.68.0",
        ]
        result = parse_log_lines(lines)
        assert result == Counter({"192.168.22.11": 1, "10.32.89.34": 1})

    def test_skips_lines_with_insufficient_fields(self) -> None:
        """Test that lines with less than 2 fields are skipped."""
        lines = [
            "[29/Sep/2021:10:20:48+0100]",
            "[29/Sep/2021:10:20:49+0100] 192.168.22.11 /healthz GET",
        ]
        result = parse_log_lines(lines)
        assert result == Counter({"192.168.22.11": 1})

    def test_empty_input(self) -> None:
        """Test handling of empty input."""
        result = parse_log_lines([])
        assert result == Counter()

    def test_handles_whitespace(self) -> None:
        """Test that leading/trailing whitespace is handled."""
        lines = [
            "  [29/Sep/2021:10:20:48+0100] 192.168.22.11 /healthz GET  \n",
        ]
        result = parse_log_lines(lines)
        assert result == Counter({"192.168.22.11": 1})


class TestFormatOutput:
    """Tests for format_output function."""

    def test_format_sorted_by_frequency(self) -> None:
        """Test output is sorted by frequency descending."""
        counter = Counter({"192.168.22.11": 6, "10.32.89.34": 4, "172.32.9.12": 2})
        result = format_output(counter)
        lines = result.split("\n")
        assert lines[0] == "6 192.168.22.11"
        assert lines[1] == "4 10.32.89.34"
        assert lines[2] == "2 172.32.9.12"

    def test_format_empty_counter(self) -> None:
        """Test formatting empty counter."""
        result = format_output(Counter())
        assert result == ""


class TestCLI:
    """Tests for CLI interface."""

    def test_file_input(self, tmp_path: pytest.TempPathFactory) -> None:
        """Test reading from file via --file flag."""
        log_file = tmp_path / "test.log"
        log_file.write_text(
            "[29/Sep/2021:10:20:48+0100] 192.168.22.11 /healthz GET Mozilla/5.0\n"
            "[29/Sep/2021:10:20:49+0100] 192.168.22.11 /api/status GET curl/7.68.0\n"
            "[29/Sep/2021:10:20:50+0100] 10.32.89.34 /healthz GET Mozilla/5.0\n"
        )

        runner = CliRunner()
        result = runner.invoke(main, ["--file", str(log_file)])

        assert result.exit_code == 0
        assert "2 192.168.22.11" in result.output
        assert "1 10.32.89.34" in result.output

    def test_stdin_input(self) -> None:
        """Test reading from stdin."""
        input_data = (
            "[29/Sep/2021:10:20:48+0100] 192.168.22.11 /healthz GET Mozilla/5.0\n"
            "[29/Sep/2021:10:20:49+0100] 10.32.89.34 /api/status GET curl/7.68.0\n"
        )

        runner = CliRunner()
        result = runner.invoke(main, input=input_data)

        assert result.exit_code == 0
        assert "1 192.168.22.11" in result.output
        assert "1 10.32.89.34" in result.output

    def test_empty_file(self, tmp_path: pytest.TempPathFactory) -> None:
        """Test handling empty file."""
        log_file = tmp_path / "empty.log"
        log_file.write_text("")

        runner = CliRunner()
        result = runner.invoke(main, ["--file", str(log_file)])

        assert result.exit_code == 0
        assert result.output == ""

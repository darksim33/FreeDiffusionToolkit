import pytest
from freediffusiontoolkit.cmd_interface import run
from pathlib import Path


def test_cmd_help(capsys):
    run(["-h"])
    captured = capsys.readouterr()
    assert "Usage:" in captured.out


def test_cmd_run():
    run(["run", "0,100", "6", "Siemens", "test.dvs"])
    assert Path(r"test.dvs").is_file()
    Path(r"test.dvs").unlink()

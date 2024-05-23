import pytest
import random
import numpy as np
from pathlib import Path
from freediffusiontoolkit import FreeDiffusionTool
from freediffusiontoolkit.free_diffusion_tools import run


@pytest.fixture
def vector_file_siemens():
    yield Path(r".test_DiffVector.dvs")
    if Path(r".test_DiffVector.dvs").is_file():
        Path(r".test_DiffVector.dvs").unlink()


@pytest.fixture
def free_diffusion_tool():
    return FreeDiffusionTool(
        np.linspace(0, random.randint(750, 1500), random.randint(20, 64)),
        random.randint(1, 15),
        "Siemens",
    )


def test_get_vectors(free_diffusion_tool):
    vectors = free_diffusion_tool.get_diffusion_vectors()
    assert vectors.shape == (
        free_diffusion_tool.n_dims * len(free_diffusion_tool.b_values),
        3,
    )
    assert np.mean(vectors[0 : free_diffusion_tool.n_dims, :]) == 0


def test_save_file_siemens_ve11c(free_diffusion_tool, vector_file_siemens):
    free_diffusion_tool.save(vector_file_siemens)
    assert vector_file_siemens.is_file()


def test_terminal_help(capsys):
    run(["-h"])
    captured = capsys.readouterr()
    assert "Usage:" in captured.out


def test_terminal_run():
    run(["run", "0,100", "6", "Siemens", "test.dvs"])
    assert Path(r"test.dvs").is_file()
    Path(r"test.dvs").unlink()

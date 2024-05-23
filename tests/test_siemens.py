import pytest
import numpy as np
import random
from pathlib import Path
from freediffusiontoolkit import BasicSiemensTool, LegacySiemensTool


@pytest.fixture
def vector_file_siemens_basic():
    yield Path(r".test_DiffVector.dvs")
    if Path(r".test_DiffVector.dvs").is_file():
        Path(r".test_DiffVector.dvs").unlink()


@pytest.fixture
def vector_file_siemens_legacy():
    yield Path("DiffusionVectors.txt")
    if Path("DiffusionVectors.txt").is_file():
        Path("DiffusionVectors.txt").unlink()


@pytest.fixture
def free_diffusion_tool_siemens_basic():
    return BasicSiemensTool(
        np.linspace(0, random.randint(750, 1500), random.randint(20, 64)),
        random.randint(1, 15),
    )


@pytest.fixture
def free_diffusion_tool_siemens_legacy():
    return LegacySiemensTool(
        np.linspace(0, random.randint(750, 1500), random.randint(20, 64)),
        random.randint(1, 15),
    )


def test_save_file_siemens_basic_save(
    free_diffusion_tool_siemens_basic, vector_file_siemens_basic
):
    free_diffusion_tool_siemens_basic.save(vector_file_siemens_basic)
    assert vector_file_siemens_basic.is_file()


def test_load_file_siemens_legacy_save(
    free_diffusion_tool_siemens_legacy, vector_file_siemens_legacy
):
    free_diffusion_tool_siemens_legacy.save(vector_file_siemens_legacy)
    assert vector_file_siemens_legacy.is_file()

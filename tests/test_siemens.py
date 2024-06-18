import pytest
import numpy as np
import random
from pathlib import Path
from freediffusiontoolkit import BasicSiemensTool, LegacySiemensTool


@pytest.fixture
def vector_filename_siemens_basic():
    yield Path("test_DiffVector.dvs")
    if Path("test_DiffVector.dvs").is_file():
        Path("test_DiffVector.dvs").unlink()


@pytest.fixture
def vector_filename_siemens_legacy():
    yield Path("DiffusionVectors.txt")
    if Path("DiffusionVectors.txt").is_file():
        Path("DiffusionVectors.txt").unlink()


@pytest.fixture
def free_diffusion_tool_siemens_basic():
    return BasicSiemensTool(
        np.linspace(0, random.randint(750, 1500), random.randint(20, 64)),
        random.randint(3, 15),
    )


@pytest.fixture
def free_diffusion_tool_siemens_legacy():
    return LegacySiemensTool(
        np.linspace(0, random.randint(750, 1500), random.randint(20, 64)),
        random.randint(3, 15),
    )


@pytest.fixture
def vector_file_siemens_basic(
    vector_filename_siemens_basic, free_diffusion_tool_siemens_basic
):
    free_diffusion_tool_siemens_basic.save(vector_filename_siemens_basic)
    yield vector_filename_siemens_basic
    if Path(vector_filename_siemens_basic).is_file():
        vector_filename_siemens_basic.unlink()


def test_basic_save(free_diffusion_tool_siemens_basic, vector_filename_siemens_basic):
    free_diffusion_tool_siemens_basic.save(vector_filename_siemens_basic)
    assert vector_filename_siemens_basic.is_file()


def test_basic_load(vector_file_siemens_basic, free_diffusion_tool_siemens_basic):
    free_diffusion_tool_siemens_basic.load(vector_file_siemens_basic)


def test_legacy_save(
    free_diffusion_tool_siemens_legacy, vector_filename_siemens_legacy
):
    free_diffusion_tool_siemens_legacy.save(vector_filename_siemens_legacy)
    assert vector_filename_siemens_legacy.is_file()

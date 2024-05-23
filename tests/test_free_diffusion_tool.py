import pytest
import random
import numpy as np
from pathlib import Path
from freediffusiontoolkit import FreeDiffusionTool


@pytest.fixture
def free_diffusion_tool():
    return FreeDiffusionTool(
        np.linspace(0, random.randint(750, 1500), random.randint(20, 64)),
        random.randint(1, 15),
    )


def test_get_vectors(free_diffusion_tool):
    vectors = free_diffusion_tool.get_diffusion_vectors()
    assert vectors.shape == (
        free_diffusion_tool.n_dims * len(free_diffusion_tool.b_values),
        3,
    )
    assert np.mean(vectors[0 : free_diffusion_tool.n_dims, :]) == 0

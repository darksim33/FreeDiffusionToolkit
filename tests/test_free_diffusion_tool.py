import pytest
import random
import numpy as np
from pathlib import Path
from freediffusiontoolkit import FreeDiffusionTool


def compare_vectors(vector1, vector2, scaling):
    assert vector1.all() == (vector2 * scaling).all()


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


def test_get_vectors_3dims():
    diff_tool = FreeDiffusionTool([0, 500, 1000], 3)
    vectors = diff_tool.get_diffusion_vectors()
    assert vectors.shape == (len(diff_tool.b_values) * diff_tool.n_dims, 3)
    compare_vectors(
        vectors[diff_tool.n_dims : 2 * diff_tool.n_dims, :],
        vectors[diff_tool.n_dims * 2 :, :],
        diff_tool.b_values[-2] / diff_tool.b_values[-1],
    )


def test_get_vector_4dims():
    diff_tool = FreeDiffusionTool([0, 500, 1000], 4)
    vectors = diff_tool.get_diffusion_vectors()
    assert vectors.shape == (len(diff_tool.b_values) * diff_tool.n_dims, 3)
    compare_vectors(
        vectors[diff_tool.n_dims : 2 * diff_tool.n_dims, :],
        vectors[diff_tool.n_dims * 2 :, :],
        diff_tool.b_values[-2] / diff_tool.b_values[-1],
    )

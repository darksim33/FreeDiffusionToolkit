import pytest
from freediffusiontoolkit.free_diffusion_tools import FreeDiffusionTool
from freediffusiontoolkit.vector_ploter import plot_vectors


def test_vector_plotter_n_dims_3():
    diff_tool = FreeDiffusionTool([1000], 3)
    vectors = diff_tool.get_diffusion_vectors()
    plot_vectors(vectors)
    assert True


def test_vector_plotter_n_dims_3_inverted():
    diff_tool = FreeDiffusionTool([1000], 3)
    vectors = diff_tool.get_diffusion_vectors()
    plot_vectors(vectors, True)
    assert True


def test_vector_plotter_n_dims_4():
    diff_tool = FreeDiffusionTool([1000], 4)
    vectors = diff_tool.get_diffusion_vectors()
    plot_vectors(vectors)
    assert True


def test_vector_plotter_n_dims_6():
    diff_tool = FreeDiffusionTool([1000], 6)
    vectors = diff_tool.get_diffusion_vectors()
    plot_vectors(vectors)
    assert True


def test_vector_plotter_n_dims_7():
    diff_tool = FreeDiffusionTool([1000], 7)
    vectors = diff_tool.get_diffusion_vectors()
    plot_vectors(vectors, True)
    assert True


def test_vector_plotter_multi_b():
    diff_tool = FreeDiffusionTool([0, 500, 1000], 4)
    vectors = diff_tool.get_diffusion_vectors()
    plot_vectors(vectors)
    assert True

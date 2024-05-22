import sys
from abc import abstractmethod
import numpy as np
from pathlib import Path
from datetime import datetime


class FreeDiffusionTool:
    def __init__(
        self,
        b_values: list | np.ndarray = np.array([0, 1000]),
        n_dims: int | None = 3,
        vendor: str | None = None,
        **kwargs,
    ):
        self.options = kwargs
        self.b_values = b_values
        self.n_dims = n_dims

        self.vendor = vendor

    # @property
    # def vendor(self):
    #     """Handles different supported vendors."""
    #     return self._vendor
    #
    # @vendor.setter
    # def vendor(self, vendor):
    #     if vendor not in self.supported_vendors:
    #         raise ValueError(
    #             "The selected vendor is not supported. Check documentation for supported ones."
    #         )
    #     self._vendor = vendor

    def get_diffusion_vectors(self) -> np.ndarray:
        """Calculate the diffusion vectors for the given number of dimensions and b_values."""
        diffusion_vectors = np.array([])

        # get equally spaced vectors
        phi = np.linspace(0, 2 * np.pi, self.n_dims)
        theta = np.linspace(0, np.pi / 2, self.n_dims)

        for b_value in self.b_values:
            # calculate vector of directions
            vectors = np.array(
                [
                    np.sin(theta) * np.cos(phi),
                    np.sin(theta) * np.sin(phi),
                    np.cos(theta),
                ]
            ).T

            # Apply b_values to vector file as relative length
            scaling = b_value / self.b_values[-1]

            if diffusion_vectors.size:
                diffusion_vectors = np.concatenate(
                    (diffusion_vectors, vectors * scaling)
                )
            else:
                diffusion_vectors = vectors * scaling

        return diffusion_vectors

    @abstractmethod
    def save(self, diffusion_vector_file: Path) -> None:
        pass

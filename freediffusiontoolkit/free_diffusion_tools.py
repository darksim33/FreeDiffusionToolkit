from abc import abstractmethod
from pathlib import Path

import numpy as np
from qspace.sampling import multishell as ms


class FreeDiffusionTool:
    def __init__(
        self,
        b_values: list | np.ndarray = np.array([0, 1000]),
        n_dims: int | None = 3,
        **kwargs,
    ):
        self.options = kwargs
        self.b_values = b_values
        self.n_dims = n_dims
        self.vectors = None
        self._scale_by_value = kwargs.get("scale_by_value", None)

    @property
    def vectors(self):
        if self._vectors is None:
            self._vectors = self.get_diffusion_vectors()
        return self._vectors

    @vectors.setter
    def vectors(self, vectors: np.ndarray):
        self._vectors = vectors

    @property
    def scale_by_value(self):
        return self._scale_by_value

    @scale_by_value.setter
    def scale_by_value(self, value):
        self._scale_by_value = value

    def get_basis_vectors(self) -> np.ndarray:
        """Calculate Basis vectors according to qspace from E. Caruyer"""
        nb_shells = 1
        points_per_shell = [self.n_dims]
        # Groups of shells and coupling weights
        shell_groups = [[i] for i in range(nb_shells)]
        shell_groups.append(list(range(nb_shells)))  # range(nb_shells)
        alphas = np.ones(len(shell_groups))
        weights = ms.compute_weights(nb_shells, points_per_shell, shell_groups, alphas)

        # Where the optimized sampling scheme is computed
        points = ms.optimize(nb_shells, points_per_shell, weights, max_iter=1000)

        return points

    def get_diffusion_vectors(self, scale_by_value: int | None = None) -> np.ndarray:
        """
        Calculate the diffusion vectors for the given number of dimensions and b_values.

        Parameters:
            scale_by_value: int
                Select b_value for scaling the vector file if you don't want to use the highest.
        """
        if scale_by_value is None:
            scale_by_value = self._scale_by_value

        diffusion_vectors = np.array([])

        vectors = self.get_basis_vectors()

        for b_value in self.b_values:

            # Apply b_values to vector file as relative length
            if not scale_by_value:
                scaling = b_value / self.b_values[-1]
            else:
                scaling = b_value / scale_by_value

            if diffusion_vectors.size:
                diffusion_vectors = np.concatenate(
                    (diffusion_vectors, vectors * scaling)
                )
            else:
                diffusion_vectors = vectors * scaling

        return diffusion_vectors

    @abstractmethod
    def construct_header(self, filename: Path):
        pass

    def write(
        self, filename: Path, header: list, diffusion_vectors: list | np.ndarray
    ) -> None:
        with filename.open("w") as file:
            # write header to file
            for line in header:
                file.write(line + self.options.get("newline", "\n"))

            # write values to file
            for row_idx, row in enumerate(diffusion_vectors):
                file.write(
                    self.vector_to_string(row_idx, row)
                    + self.options.get("newline", "\n")
                )

    def save(self, filename: Path) -> None:
        # get Header
        header = self.construct_header(filename=filename)
        # get diffusion values
        diffusion_vectors = self.get_diffusion_vectors(
            scale_by_value=self.scale_by_value
        )
        # save to file
        self.write(filename, header, diffusion_vectors)

    @abstractmethod
    def load(self, diffusion_vector_file: Path) -> None:
        pass

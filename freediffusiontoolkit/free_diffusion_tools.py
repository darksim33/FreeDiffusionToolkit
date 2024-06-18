from abc import abstractmethod
import numpy as np
from pathlib import Path
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

    @property
    def vectors(self):
        if self._vectors is None:
            self._vectors = self.get_diffusion_vectors()
        return self._vectors

    @vectors.setter
    def vectors(self, vectors: np.ndarray):
        self._vectors = vectors

    def get_basis_vectors(self) -> np.ndarray:
        """Calculate Basis vectors according to qspace from E. Caruyer"""
        nb_shells = 1
        points_per_shell = [self.n_dims]
        # Groups of shells and coupling weights
        shell_groups = [[i] for i in range(nb_shells)]
        shell_groups.append(range(nb_shells))  # range(nb_shells)
        alphas = np.ones(len(shell_groups))
        weights = ms.compute_weights(nb_shells, points_per_shell, shell_groups, alphas)

        # Where the optimized sampling scheme is computed
        points = ms.optimize(nb_shells, points_per_shell, weights, max_iter=1000)

        return points

    def get_diffusion_vectors(self) -> np.ndarray:
        """Calculate the diffusion vectors for the given number of dimensions and b_values."""
        diffusion_vectors = np.array([])

        vectors = self.get_basis_vectors()

        for b_value in self.b_values:

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

    @abstractmethod
    def load(self, diffusion_vector_file: Path) -> None:
        pass

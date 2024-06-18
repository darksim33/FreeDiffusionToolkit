from abc import abstractmethod
import numpy as np
from pathlib import Path


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

    def get_diffusion_vectors(self) -> np.ndarray:
        """Calculate the diffusion vectors for the given number of dimensions and b_values."""
        diffusion_vectors = np.array([])
        vectors = None

        if self.n_dims == 3:
            vectors = np.eye(3)
        elif self.n_dims == 4:
            vectors = np.array(
                [
                    [1, 1, 1],
                    [-1, -1, 1],
                    [-1, 1, -1],
                    [1, -1, -1],
                ]
            ) / np.sqrt(3)
        elif self.n_dims == 6:
            """
            -0.7070447104249349 -0.7070447097001022 -0.009368989583632227 -0.009368990308466175 -0.6976757201164692 -0.7164137000085679
            0.6931899200454785 -0.689239614562717 -0.8402726226234002 0.5421569119847954 0.15103300806068373 -0.14708270257792092
            -0.13991251626449683 0.15822936580336597 -0.5420831501751135 -0.8402250322429763 0.7003125159784791 -0.6819956664396106
            """
            # Siemens DTI variant
            vectors = np.array(
                [
                    [-0.7070447104249349, 0.6931899200454785, -0.13991251626449683],
                    [-0.7070447097001022, -0.689239614562717, 0.15822936580336597],
                    [-0.009368989583632227, -0.8402726226234002, -0.5420831501751135],
                    [-0.009368990308466175, 0.5421569119847954, -0.8402250322429763],
                    [-0.6976757201164692, 0.15103300806068373, 0.7003125159784791],
                    [-0.7164137000085679, -0.14708270257792092, -0.6819956664396106],
                ]
            )

            pass

        elif self.n_dims > 7:
            # get equally spaced vectors
            phi = np.linspace(0, 2 * np.pi, self.n_dims)
            theta = np.linspace(0, np.pi / 2, self.n_dims)
            # calculate vector of directions
            vectors = np.array(
                [
                    np.sin(theta) * np.cos(phi),
                    np.sin(theta) * np.sin(phi),
                    np.cos(theta),
                ]
            ).T
        else:
            raise ValueError(f"Invalid number of dimensions {self.n_dims}")

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

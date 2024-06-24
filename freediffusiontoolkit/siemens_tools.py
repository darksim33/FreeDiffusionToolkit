from datetime import datetime
from pathlib import Path

import numpy as np

from .free_diffusion_tools import FreeDiffusionTool


class BasicSiemensTool(FreeDiffusionTool):
    def __init__(
        self,
        b_values: list | np.ndarray = np.array([0, 1000]),
        n_dims: int | None = 3,
        **kwargs,
    ):
        super().__init__(b_values, n_dims, **kwargs)

    def get_basis_vectors(self) -> np.ndarray:
        if self.n_dims == 3:
            points = np.eye(3)
        elif self.n_dims == 4:
            points = np.array(
                [
                    [1, 1, 1],
                    [-1, -1, 1],
                    [-1, 1, -1],
                    [1, -1, -1],
                ]
            ) / np.sqrt(3)
        elif self.n_dims == 6:
            points = np.array(
                [
                    [-0.7070447104249349, 0.6931899200454785, -0.13991251626449683],
                    [-0.7070447097001022, -0.689239614562717, 0.15822936580336597],
                    [-0.009368989583632227, -0.8402726226234002, -0.5420831501751135],
                    [-0.009368990308466175, 0.5421569119847954, -0.8402250322429763],
                    [-0.6976757201164692, 0.15103300806068373, 0.7003125159784791],
                    [-0.7164137000085679, -0.14708270257792092, -0.6819956664396106],
                ]
            )
        else:
            points = super().get_basis_vectors()
        return points

    def construct_header(
        self,
        filename: Path = None,
        n_dims: int = 3,
        b_values: list | np.ndarray | tuple = (0, 1000),
    ) -> list:
        """
        Create a header string for the diffusion vector file.

        Parameters
        n_dims: int
            Number of diffusion vector directions.
        b_values: list | np.ndarray
            An array containing the b values used for the diffusion vector file.
        kwargs: dict
            Options are explained in parent method documentation.
        """
        # This is the total number of applied dimensions
        n_directions = len(b_values) * n_dims

        head = list()
        head.append(
            r"# -----------------------------------------------------------------------------"
        )

        if filename is not None:
            if not isinstance(filename, Path):
                filename = Path(filename)
            filename = filename.name
        else:
            filename = "MyVectorSet.dvs"
        default_path = self.options.get(
            "default_path", r"C:\\Medcom\\MriCustomer\\seq\\DiffusionVectorSets\\"
        )
        head.append("# File: " + default_path + filename)

        now = datetime.now()
        current_time = now.strftime("%a %b %d %H:%M:%S %Y")
        head.append(f"# Date: {current_time}")

        description = self.options.get(
            "description", "Vector file for Siemens 'free' diffusion mode."
        )
        head.append(f"# Description: {description}")
        head.append(f"b-values: {b_values}")
        head.append(f"number dimensions: {n_dims}")
        comment = self.options.get("Comment", None)
        if comment:
            head.append(f"Comment: {comment}")

        head.append(
            r"# -----------------------------------------------------------------------------"
        )
        # Calculate the correct number of directions
        head.append(f"[directions={n_directions * len(b_values)}]")

        coordinate_system = self.options.get("CoordinateSystem", "xyz")
        head.append(f"CoordinateSystem = {coordinate_system}")

        normalisation = self.options.get("Normalisation", "none")
        head.append(f"Normalisation = {normalisation}")
        # NOTE: There is an option to add a comment here. "comment = example text"
        return head

    def save(self, filename: Path = "") -> None:
        """
        Write vector file for Siemens.

        Supports VE11c but might support other software version.
        Recommended file suffix is .dvs

        Parameters
        filename: Path
            Pathlib Path to the diffusion vector file.

        options: dict
            Several options to modify the header information.
                Description: str
                    Description of the diffusion vector file.
                CoordinateSystem: str = "xyz"
                    Coordinate System used by the scaner (?)
                Normalisation: str = "maximum", "none"
                    Normalisation mode used by the scaner (?)
                Comment: str
                    Further information and comments about the diffusion vector file.
                Newline: str = "\n", "\r\n" for legacy

        """
        header = self.construct_header(filename=filename)

        # get diffusion values
        diffusion_vectors = self.get_diffusion_vectors()

        self.write(filename, header, diffusion_vectors)

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

    @staticmethod
    def vector_to_string(
        index: int, vector: np.ndarray | list, decimals: int = 6
    ) -> str:
        """Siemens style vector conversion."""
        return (
            f"Vector[{index}] = ("
            f"{vector[0]: .{decimals}f},"
            f"{vector[1]: .{decimals}f},"
            f"{vector[2]: .{decimals}f})"
        )

    def load(self, filename: Path) -> None:
        vector_list = list()

        def process_vector_line(text: str) -> tuple:
            text = text.strip()
            components = text.split(" = ")
            position = components[0].replace("Vector[", "").replace("]", "")
            vector = (
                components[1]
                .replace("(", "")
                .replace(")", "")
                .replace(" ", "")
                .split(",")
            )
            vector = [np.float64(i) for i in vector]
            return position, vector

        with filename.open("r") as file:
            for line in file:

                # Read data
                if not line.startswith("#"):
                    if line.startswith("Vector"):
                        vector_list.append(process_vector_line(line)[1])

        self.vectors = np.array(vector_list)


class LegacySiemensTool(BasicSiemensTool):
    def __init__(self, b_values: list | np.ndarray, n_dims: int, **kwargs):
        super().__init__(b_values, n_dims, **kwargs)
        self.options["newline"] = "\r\n"
        self.options["default_path"] = r"C:\\Medcom\\MriCustomer\\seq\\"

    def save(self, filename: Path = Path("DiffusionVectors.txt"), **options: dict):
        """
        Write vector file for Siemens (legacy).

        Supports VB17c but might support other software version.
        Filename should be DiffusionVectors.txt since this is the supported filename.

        Parameters
        filename: Path
            Pathlib Path to the diffusion vector file.

        options: dict
            Several options to modify the header information.
                Description: str
                    Description of the diffusion vector file.
                CoordinateSystem: str = "xyz"
                    Coordinate System used by the scaner (?)
                Normalisation: str = "maximum", "none"
                    Normalisation mode used by the scaner (?)
                Comment: str
                    Further information und comments about the diffusion vector file.
                Newline: str = "\r\n" for legacy

        """
        header = self.construct_header(filename=filename)
        for idx, head in enumerate(header):
            if head.startswith("[directions="):
                header[idx] = head.replace("[directions=", "")

        self.write(filename, header, self.vectors)

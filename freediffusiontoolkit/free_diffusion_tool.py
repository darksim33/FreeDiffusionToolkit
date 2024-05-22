import sys

import numpy as np
from pathlib import Path
from datetime import datetime


class FreeDiffusionTool:
    def __init__(
        self,
        b_values: list | np.ndarray = np.array([0, 1000]),
        n_dims: int | None = 3,
        vendor: str | None = "Siemens_VE11c",
        **kwargs,
    ):
        self.b_values = b_values
        self.n_dims = n_dims

        self.supported_vendors = [
            "Siemens",
        ]

        self.vendor = vendor

    @property
    def vendor(self):
        """Handles different supported vendors."""
        return self._vendor

    @vendor.setter
    def vendor(self, vendor):
        if vendor not in self.supported_vendors:
            raise ValueError(
                "The selected vendor is not supported. Check documentation for supported ones."
            )
        self._vendor = vendor

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

    def save(self, diffusion_vector_file: Path, **kwargs: dict) -> None:
        """Handles saving the diffusion vector file for different vendors."""
        if self.vendor in ["Siemens", "siemens"]:
            self.write_siemens(diffusion_vector_file, **kwargs)

    def write_siemens(self, diffusion_vector_file: Path = "", **options: dict) -> None:
        """
        Write vector file for Siemens.

        Supports VB17c and VE11c but might support other software version.
        Recommended file suffix for VE11 is .dvs
        For VB17c the filename should be DiffusionVectors.txt

        Parameters
        diffusion_vector_file: Path
            Pathlib Path to the diffusion vector file.

        options: dict
            Several options to modify the header information.
                description: str
                    Description of the diffusion vector file.
                CoordinateSystem: str = "xyz"
                    Coordinate System used by the scaner (?)
                Normalisation: str = "maximum"
                    Normalisation mode used by the scaner (?)
                Comment: str
                    Further information and comments about the diffusion vector file.

        """

        def construct_header(n_dims: int, **kwargs) -> list:
            """
            Create a header string for the diffusion vector file.

            Parameters
            n_dims: int
                Number of diffusion vector directions.
            kwargs: dict
                Options are explained in parent method documentation.
            """
            head = list()
            now = datetime.now()

            current_time = now.strftime("%a %b %d %H:%M:%S %Y")

            # load optional settings
            filename = kwargs.get("filename", "MyVectorSet.dvs")
            if isinstance(filename, Path):
                filename = filename.name

            description = kwargs.get(
                "description", "Vector file for Siemens 'free' diffusion mode."
            )
            coordinate_system = kwargs.get("CoordinateSystem", "xyz")
            normalisation = kwargs.get("Normalisation", "maximum")
            # comment = kwargs.get("Comment", "my diffusion vector set")

            # head.append(
            #     r"# -----------------------------------------------------------------------------"
            # )
            # head.append(r"# Copyright (C) SIEMENS AG 2011 All Rights Reserved.\ ")
            head.append(
                r"# -----------------------------------------------------------------------------"
            )
            # head.append(r"# ")
            # head.append(r"# Project: NUMARIS/4")
            head.append(
                f"# File: C:\\Medcom\\MriCustomer\\seq\\DiffusionVectorSets\\{filename}"
            )
            head.append(f"# Date: {current_time}")
            # head.append("#")
            head.append(f"# Description: {description}")
            if kwargs.get("b_values", None) is not None:
                head.append(f"b_values: {b_values}")

            head.append(
                r"# -----------------------------------------------------------------------------"
            )
            head.append(f"[directions={n_dims}]")
            head.append(f"CoordinateSystem = {coordinate_system}")
            head.append(f"Normalisation = {normalisation}")

            # if kwargs.get("b_values", None) is not None:
            #     b_values = kwargs.get("b_values")
            #     head.append(f"Comment = {comment}; b_values: {b_values}")
            # else:
            #     head.append(f"Comment = {comment}")
            return head

        def vector_to_string(
            index: int, vector: np.ndarray | list, decimals: int = 6
        ) -> str:
            """Siemens style vector conversion."""
            return (
                f"Vector[{index}] = ("
                f"{vector[0]: .{decimals}f},"
                f"{vector[1]: .{decimals}f},"
                f"{vector[2]: .{decimals}f})"
                f"\n"
            )

        header = construct_header(
            self.n_dims, filename=diffusion_vector_file, **options
        )

        with diffusion_vector_file.open("w") as file:
            # write header to file
            for line in header:
                file.write(line + "\n")

            # get diffusion values
            diffusion_vectors = self.get_diffusion_vectors()
            # write values to file
            for row_idx, row in enumerate(diffusion_vectors):
                file.write(vector_to_string(row_idx, row))


def run(
    args: list = None,
    # b_values: list = None,
    # n_dims: int = None,
    # vendor: str = None,
    # filename: str | Path = None,
    # **options,
):
    """Handles script execution for extern usage. Options are explained in vendor method documentation."""
    if args is None:
        args = sys.argv

    opts = [opt for opt in args if opt.startswith("-")]
    args = [arg for arg in args if not arg.startswith("-")]

    if "-h" in opts or "--help" in opts:
        print(
            "\n"
            "FreeDiffusionToolkit for diffusion vector file creation.\n"
            "Usage:\n"
            "  create_vector_file <b_values> <n_dims> <vendor> <filename> [options]\n>"
            "\n"
            "Parameters:\n"
            "   b_values: list              Values used for scaling the directions.\n"
            "                               Example: '0,5,10' Passed as string without brackets.\n"
            "   n_dims: int                 Number of dimensions used.\n"
            "   vendor: str                 Specifying the selected Vendor. For more information see documentation.\n"
            "   filename: str               Output filename with ending.\n\n"
            "General Options:\n"
            "   -h, --help                  Show help.\n"
        )
        return

    if len(args) < 4:
        TypeError("Not enough input arguments.")
    elif len(args) < 5:
        args.append((Path.home().resolve() / "DiffusionVectors.txt").__str__())

    b_values = [int(val) for val in args[1].replace(",", " ").split()]
    n_dims = int(args[2])
    vendor = args[3]
    filename = Path(args[4])

    free_diffusion_tool = FreeDiffusionTool(b_values, n_dims, vendor)
    free_diffusion_tool.save(filename)

import sys
from pathlib import Path
from .siemens_tools import LegacySiemensTool, BasicSiemensTool


def run(
    args: list = None,
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
            "  create_vector_file <b_values> <n_dims> <vendor> <filename> [options]\n"
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

    b_values = [float(val) for val in args[1].replace(",", " ").split()]
    n_dims = int(args[2])
    vendor = args[3]
    filename = Path(args[4])

    # free_diffusion_tool = FreeDiffusionTool(b_values, n_dims, vendor)
    free_diffusion_tool = vendor_handler(vendor, b_values, n_dims)
    free_diffusion_tool.save(filename)


def vendor_handler(vendor: str, b_values: list, n_dims: int):
    if "Siemens" or "siemens" in vendor:
        if "VB11" in vendor:
            free_diffusion_tool = LegacySiemensTool(b_values, n_dims)
        else:
            free_diffusion_tool = BasicSiemensTool(b_values, n_dims)
    else:
        raise ValueError(
            "The selected vendor is not supported. Check documentation for supported ones."
        )
    return free_diffusion_tool

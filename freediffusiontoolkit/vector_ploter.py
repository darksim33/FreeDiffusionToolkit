import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch
from mpl_toolkits.mplot3d import Axes3D
import numpy as np


def plot_vectors(vectors: np.array, show_inverted: bool = False):
    fig = plt.figure()
    ax = fig.add_subplot(111, projection="3d")

    if not show_inverted:
        x = y = z = np.zeros((vectors.shape[0],))
        u = np.squeeze(vectors[:, 0])
        v = np.squeeze(vectors[:, 1])
        w = np.squeeze(vectors[:, 2])
        color = ["C0"] * vectors.shape[0]
    else:
        x = y = z = np.zeros((vectors.shape[0] * 2,))
        u = np.concatenate((np.squeeze(vectors[:, 0]), np.squeeze(vectors[:, 0]) * -1))
        v = np.concatenate((np.squeeze(vectors[:, 1]), np.squeeze(vectors[:, 1]) * -1))
        w = np.concatenate((np.squeeze(vectors[:, 2]), np.squeeze(vectors[:, 2]) * -1))
        color = ["C0"] * vectors.shape[0] + ["C1"] * vectors.shape[0]
    ax.quiver(x, y, z, u, v, w, color=color, linewidth=1)

    ax.set_xlim([-1, 1])
    ax.set_ylim([-1, 1])
    ax.set_zlim([-1, 1])
    plt.show()

import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import numpy as np


def plot_vectors(vectors: np.array):

    x = y = z = np.zeros((vectors.shape[0],))

    fig = plt.figure()
    ax = fig.add_subplot(111, projection="3d")
    ax.quiver(
        x,
        y,
        z,
        np.squeeze(vectors[:, 0]),
        np.squeeze(vectors[:, 1]),
        np.squeeze(vectors[:, 2]),
    )
    ax.set_xlim([-1, 1])
    ax.set_ylim([-1, 1])
    ax.set_zlim([-1, 1])
    plt.show()

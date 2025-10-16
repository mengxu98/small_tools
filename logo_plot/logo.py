# -*- coding: utf-8 -*-
"""
Draw SPAN logo: Spatially-Aware gene regulatory Network inference
pip install matplotlib networkx numpy
"""

import numpy as np
import networkx as nx
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.patheffects

# ---------- arguments ----------
rng = np.random.default_rng(42)
n_nodes = 10  # nodes number
grid_size = 2  # slightly smaller cube size
blue_main = "#4c6b8a"
blue_light = "#9aa9b7"
blue_bg = "#d0d5db"
figsize = (6, 6)  # figure size
dpi = 300
svg_path = "SPAN_logo.svg"
pdf_path = "SPAN_logo.pdf"

# ---------- generate network ----------
G = nx.random_geometric_graph(n_nodes, 0.18, seed=42)  # 增加连接半径
# optimize node distribution, make nodes further from center
pos_3d = {}
center = grid_size / 2
for i in G.nodes():
    # distribute nodes more evenly inside the cube, but avoid too close to center
    while True:
        x = rng.uniform(0.3, grid_size - 0.3)
        y = rng.uniform(0.3, grid_size - 0.3)
        z = rng.uniform(0.3, grid_size - 0.3)
        # ensure nodes are at least 0.8 units away from center
        dist_from_center = np.sqrt(
            (x - center) ** 2 + (y - center) ** 2 + (z - center) ** 2
        )
        if dist_from_center > 0.8:  # at least 0.8 units away from center
            pos_3d[i] = (x, y, z)
            break

# ---------- canvas ----------
fig = plt.figure(figsize=figsize, dpi=dpi)
ax = fig.add_subplot(111, projection="3d")
ax.set_box_aspect([1, 1, 1])
ax.set_facecolor("none")
fig.patch.set_facecolor("none")
ax.axis("off")

# ---------- draw space grid ----------
# only draw 9 edges of the cube that are visible, hide the other 3 edges, thicken the lines
# bottom 4 edges (all visible)
ax.plot([0, grid_size], [0, 0], [0, 0], color=blue_bg, lw=1.8, alpha=0.6)
ax.plot(
    [0, grid_size], [grid_size, grid_size], [0, 0], color=blue_bg, lw=1.8, alpha=0.6
)
ax.plot([0, 0], [0, grid_size], [0, 0], color=blue_bg, lw=1.8, alpha=0.6)
ax.plot(
    [grid_size, grid_size], [0, grid_size], [0, 0], color=blue_bg, lw=1.8, alpha=0.6
)
# top 2 edges (only draw the front ones)
ax.plot(
    [0, grid_size], [0, 0], [grid_size, grid_size], color=blue_bg, lw=1.8, alpha=0.6
)
ax.plot(
    [0, 0], [0, grid_size], [grid_size, grid_size], color=blue_bg, lw=1.8, alpha=0.6
)
# 3 vertical edges (only draw the front ones)
ax.plot([0, 0], [0, 0], [0, grid_size], color=blue_bg, lw=1.8, alpha=0.6)
ax.plot(
    [grid_size, grid_size], [0, 0], [0, grid_size], color=blue_bg, lw=1.8, alpha=0.6
)
ax.plot(
    [0, 0], [grid_size, grid_size], [0, grid_size], color=blue_bg, lw=1.8, alpha=0.6
)

# ---------- draw center circle ----------
center_x, center_y, center_z = grid_size / 2, grid_size / 2, grid_size / 2
center_size = 300  # ensure the center circle is the largest
# center circle halo
ax.scatter(
    center_x,
    center_y,
    center_z,
    s=center_size * 2.5,
    color=blue_light,
    alpha=0.18,
    edgecolor="none",
)
# center circle
ax.scatter(
    center_x,
    center_y,
    center_z,
    s=center_size,
    color=blue_main,
    alpha=0.95,
    edgecolors="white",
    linewidths=1.2,
)

# ---------- draw nodes ----------
sizes = [180 + 120 * G.degree(n) for n in G.nodes()]


# generate low saturation random colors
def generate_low_saturation_color():
    # generate HSV color, fixed saturation 0.3-0.5, brightness 0.6-0.8
    h = rng.uniform(0, 360)  # hue
    s = rng.uniform(0.3, 0.5)  # low saturation
    v = rng.uniform(0.6, 0.8)  # medium brightness
    # convert to RGB
    import colorsys

    r, g, b = colorsys.hsv_to_rgb(h / 360, s, v)
    return (r, g, b)


for node, (x, y, z) in pos_3d.items():
    # generate random low saturation color for each node
    node_color = generate_low_saturation_color()
    # halo
    ax.scatter(
        x, y, z, s=sizes[node] * 2.5, color=node_color, alpha=0.2, edgecolor="none"
    )
    # solid node
    ax.scatter(
        x,
        y,
        z,
        s=sizes[node],
        color=node_color,
        alpha=0.9,
        edgecolors="white",
        linewidths=1.0,
    )

# ---------- draw edges ----------
# increase network connections, make other nodes also have connections
for e in G.edges():
    x1, y1, z1 = pos_3d[e[0]]
    x2, y2, z2 = pos_3d[e[1]]
    # calculate connection length, relax distance limit
    dist = np.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2 + (z1 - z2) ** 2)
    if dist < 2.5:  # relax distance limit, increase connection number
        ax.plot([x1, x2], [y1, y2], [z1, z2], color=blue_light, lw=1.6, alpha=0.5)

# ---------- draw center circle to other nodes edges ----------
# increase center circle to other nodes connections
connected_nodes = list(pos_3d.keys())[:8]  # increase to connect 8 nodes
for node in connected_nodes:
    x, y, z = pos_3d[node]
    ax.plot(
        [center_x, x], [center_y, y], [center_z, z], color=blue_light, lw=1.6, alpha=0.4
    )

# ---------- write text ----------
# put SPAN text on the bottom face of the cube
text_x = grid_size * 0.5  # bottom center X coordinate
text_y = grid_size * 0.5  # bottom center Y coordinate
text_z = 0  # bottom center Z coordinate

ax.text(
    text_x,
    text_y,
    text_z,
    "SPAN",
    fontsize=32,
    fontweight="bold",
    color="white",
    fontfamily="DejaVu Sans",
    path_effects=[
        matplotlib.patheffects.withStroke(linewidth=3, foreground=(0, 0, 0, 0.3))
    ],
    ha="center",
    va="center",
)  # ensure text is centered

# ---------- view ----------
ax.view_init(elev=35, azim=45)  # adjust view to make cube vertices overlap

# ---------- save ----------
plt.savefig(svg_path, transparent=True, bbox_inches="tight", pad_inches=0)
plt.savefig(pdf_path, transparent=True, bbox_inches="tight", pad_inches=0)
plt.close()
print("SPAN logo saved →", svg_path, "and", pdf_path)

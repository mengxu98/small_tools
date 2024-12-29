'''
Text Animation GIF Generator

This script generates an animated GIF with moving text effects.
The animation shows a fixed title at the top and multiple text items
moving horizontally across the screen.

Features:
- Fixed title text at the top
- Multiple text items moving horizontally
- Random colors and sizes for moving text
- Smooth continuous movement
- Configurable text content, colors, and animation parameters

Usage:
1. Configure the parameters in the CONFIG section below
2. Run the script to generate a GIF file
3. The output will be saved as 'travel_wishes.gif'
'''

import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from PIL import Image
import random
import numpy as np
from matplotlib.font_manager import FontProperties

# ============ CONFIG ============
# Canvas settings
CANVAS_SIZE = (6, 6)  # Width, Height in inches
BACKGROUND_COLOR = 'black'

# Title settings
TITLE_TEXT = "我想去"
TITLE_CONFIG = {
    'position': (0.5, 0.8),  # x, y coordinates (0-1)
    'color': 'white',
    'fontsize': 40,
    'weight': 'bold'
}

# Moving text content
TEXTS = [
    "滑雪", "看星空", "日本", "长白山", "禾木", 
    "沙漠", "草原", "大雪", "台北", "极光", 
    "西藏", "新疆", "青海湖", "张家界", "冲浪"
]

# Visual settings
COLORS = ['white', 'lightgray', 'pink', 'yellow', 'lightblue', 'lightgreen']
FONT_SIZES = [20, 25, 30]

# Animation settings
MOVEMENT_SPEED = (0.01, 0.02)  # Min and max speed
FRAME_COUNT = 200
INTERVAL = 50  # Milliseconds between frames
FPS = 20

# Text movement area
TEXT_AREA = {
    'x_range': (-0.2, 1.2),  # Visible area plus overflow
    'y_range': (0.1, 0.6)    # Vertical range for moving text
}

# ============ IMPLEMENTATION ============
# Set Chinese font
plt.rcParams['font.sans-serif'] = ['PingFang HK']
plt.rcParams['axes.unicode_minus'] = False

# Initialize canvas
fig, ax = plt.subplots(figsize=CANVAS_SIZE)
ax.set_xlim(*TEXT_AREA['x_range'])
ax.set_ylim(0, 1)
ax.axis('off')
fig.patch.set_facecolor(BACKGROUND_COLOR)

# Create title
title = ax.text(
    TITLE_CONFIG['position'][0],
    TITLE_CONFIG['position'][1],
    TITLE_TEXT,
    color=TITLE_CONFIG['color'],
    fontsize=TITLE_CONFIG['fontsize'],
    weight=TITLE_CONFIG['weight'],
    ha='center',
    va='center'
)

class MovingText:
    """Class to manage properties of each moving text item"""
    def __init__(self, text, y_pos):
        self.text = text
        self.x_pos = random.uniform(*TEXT_AREA['x_range'])
        self.y_pos = y_pos
        self.speed = random.uniform(*MOVEMENT_SPEED)
        self.direction = 1 if random.random() > 0.5 else -1
        self.color = random.choice(COLORS)
        self.size = random.choice(FONT_SIZES)

# Create text objects
text_objects = []
y_positions = np.linspace(
    TEXT_AREA['y_range'][0],
    TEXT_AREA['y_range'][1],
    len(TEXTS)
)

for text, y_pos in zip(TEXTS, y_positions):
    text_obj = MovingText(text, y_pos)
    txt = ax.text(
        text_obj.x_pos,
        text_obj.y_pos,
        text,
        color=text_obj.color,
        fontsize=text_obj.size,
        ha='center',
        va='center',
        alpha=0.0
    )
    text_objects.append((txt, text_obj))

def update(frame):
    """Animation update function"""
    # Keep title text constant
    title.set_alpha(1.0)
    
    # Update scrolling text
    for txt, text_obj in text_objects:
        # Update alpha (opacity)
        txt.set_alpha(min(1.0, frame / 10))
        
        # Update position
        text_obj.x_pos += text_obj.speed * text_obj.direction
        
        # Reset position when text moves out of view
        if text_obj.direction > 0 and text_obj.x_pos > TEXT_AREA['x_range'][1]:
            text_obj.x_pos = TEXT_AREA['x_range'][0]
            text_obj.color = random.choice(COLORS)
            txt.set_color(text_obj.color)
        elif text_obj.direction < 0 and text_obj.x_pos < TEXT_AREA['x_range'][0]:
            text_obj.x_pos = TEXT_AREA['x_range'][1]
            text_obj.color = random.choice(COLORS)
            txt.set_color(text_obj.color)
            
        # Update text position
        txt.set_position((text_obj.x_pos, text_obj.y_pos))

# Create and save animation
anim = FuncAnimation(fig, update, frames=FRAME_COUNT, interval=INTERVAL)
anim.save('travel_wishes.gif', writer='pillow', fps=FPS)
plt.close(fig)
print("GIF saved as travel_wishes.gif")

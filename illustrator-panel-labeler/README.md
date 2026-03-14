# Illustrator Panel Labeler

An automation script for Adobe Illustrator that automatically aligns selected objects and adds alphabetical labels (A, B, C, D...).

**[中文版](README_CN.md) README**

![Example](fig.svg)

## Features

- **Smart Alignment**: Automatically identifies row and column relationships of objects and aligns them to a grid
  - First align columns (horizontally): Objects in the same column align to the leftmost position
  - Then align rows (vertically): Objects in the same row align to the topmost position
- **Auto Labeling**: Automatically adds alphabetical labels (A, B, C, D...) in top-to-bottom, left-to-right order
- **Flexible Control**: Separate control for alignment and labeling functions, supports step-by-step execution
- **Smart Grouping**: Automatically identifies row and column relationships based on object center points

## Installation

1. Open Adobe Illustrator
2. Copy the `illustrator-panel-labeler.jsx` file to one of the following directories:
   - **Windows**: `C:\Program Files\Adobe\Adobe Illustrator [version]\Presets\[language]\Scripts\`
   - **macOS**: `/Applications/Adobe Illustrator [version]/Presets/[language]/Scripts/`
3. Restart Illustrator (or run `File > Scripts > Other Script...` to directly select the file)

## Usage

### Basic Usage

1. Open or create a document in Illustrator
2. Select the objects you want to align and label (can be multiple objects or groups)
3. Run the script:
   - **Method 1**: `File > Scripts > illustrator-panel-labeler`
   - **Method 2**: `File > Scripts > Other Script...`, then select `illustrator-panel-labeler.jsx`
4. The script will automatically perform alignment and labeling

### Step-by-Step Execution

If you need to execute step by step (align first, check the result, then add labels), you can modify the control variables in the script:

```javascript
// Step control: set to true to align objects, false to skip alignment
var doAlign = true;   // Set to false to skip alignment
// Step control: set to true to add labels, false to skip labeling
var doLabel = true;   // Set to false to skip labeling
```

**Example Workflow**:
1. First run: Set `doAlign = true; doLabel = false;` - Only perform alignment
2. Check the alignment result
3. Second run: Set `doAlign = false; doLabel = true;` - Only add labels

## Configuration Options

You can customize the following parameters in the `settings` section of the script:

```javascript
// ===== settings =====
var fontSize = 20;     // Label font size (unit: pt)
var dx = 1;            // Label horizontal offset (unit: pt, positive = right)
var dy = 1;            // Label vertical offset (unit: pt, positive = down)
var startCharCode = "A".charCodeAt(0);  // Starting letter (A, B, C...)
```

### Parameter Description

- **fontSize**: Font size of label text, default 20pt
- **dx**: Horizontal offset of label relative to object's top-left corner, default 1pt (to the right)
- **dy**: Vertical offset of label relative to object's top-left corner, default 1pt (downward)
- **startCharCode**: Starting letter for labels, default "A"

> **Tip**: If the label position is incorrect, you can adjust the `dx` and `dy` values. For example, if labels should be below objects, change `dy` to a positive value.

## How It Works

### Alignment Algorithm

1. **Collect Object Information**: Read geometric bounds (position, size, center point) of all selected objects
2. **Group Identification**:
   - **Row Grouping**: Based on object center Y coordinates, if the distance between two objects' center Y ≤ half of the smaller object's height, they are considered in the same row
   - **Column Grouping**: Based on object center X coordinates, if the distance between two objects' center X ≤ half of the smaller object's width, they are considered in the same column
3. **Execute Alignment**:
   - First align columns: All objects in the same column align to the left edge of the leftmost object
   - Then align rows: All objects in the same row align to the top edge of the topmost object

### Labeling Algorithm

1. **Sorting**: Sort objects in top-to-bottom, left-to-right order
   - First sort by top value from large to small (larger top = higher on screen)
   - If top values are similar (within tolerance), sort by left value from small to large
2. **Grouping**: Group objects with similar top values into the same row
3. **Labeling**: Add alphabetical labels (A, B, C, D...) to each object in order

## Notes

1. **Object Selection**: Make sure you have selected the objects to process before running the script
2. **Object Types**: The script supports various object types (paths, groups, compound paths, etc.)
3. **Locked Objects**: Locked objects cannot be moved, ensure objects are not locked
4. **Font Requirements**: The script automatically searches for Arial font. If Arial is not available, it will use the first font containing "Arial"
5. **Coordinate System**: Illustrator uses a coordinate system where Y-axis positive direction is downward. The script handles this correctly.

## FAQ

### Q: Objects are not aligned?

A: Check the following:
- Ensure objects are not locked
- Check if objects are correctly grouped (whether center point distances of objects in the same row/column are within tolerance)
- Try executing only the alignment step first (`doAlign = true; doLabel = false;`) to check the result

### Q: Label order is incorrect?

A: Label order is based on object top and left values. If the order is incorrect, it might be:
- Object position identification error
- Try aligning objects first, then adding labels

### Q: Label position is incorrect?

A: Adjust the `dx` and `dy` parameters in the script:
- `dx` controls horizontal position (positive = right, negative = left)
- `dy` controls vertical position (positive = down, negative = up)

### Q: How to change the starting letter for labels?

A: Modify the `startCharCode` parameter:
```javascript
var startCharCode = "A".charCodeAt(0);  // Start from A
// or
var startCharCode = "1".charCodeAt(0);  // Start from number 1 (requires adjusting subsequent logic)
```

## License

Please see the [LICENSE](LICENSE) file for license information.

## Contributing

Issues and Pull Requests are welcome!

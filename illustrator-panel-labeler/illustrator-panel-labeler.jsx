#target illustrator

  (function () {
    if (app.documents.length === 0) { alert("No document open."); return; }
    var doc = app.activeDocument;
    var sel = doc.selection;
    if (!sel || sel.length === 0) { alert("Select panels (objects/groups) first."); return; }

    // ===== settings =====
    var fontSize = 20;     // pt
    var dx = 1;            // left inset (pt)
    var dy = 1;            // top inset  (pt)
    var startCharCode = "A".charCodeAt(0);

    // Step control: set to true to align objects, false to skip alignment
    var doAlign = true;
    // Step control: set to true to add labels, false to skip labeling
    var doLabel = true;
    // ====================

    function getArialFont() {
      var candidates = ["ArialMT", "Arial", "Arial-Regular", "Arial Bold", "Arial-BoldMT"];
      for (var i = 0; i < candidates.length; i++) {
        try { return app.textFonts.getByName(candidates[i]); } catch (e) { }
      }
      // fallback scan
      for (var j = 0; j < app.textFonts.length; j++) {
        var f = app.textFonts[j];
        if ((f.name && f.name.indexOf("Arial") >= 0) || (f.family && f.family.indexOf("Arial") >= 0)) return f;
      }
      return null;
    }
    var arialFont = getArialFont();

    // Collect panels with full geometric information
    var panels = [];
    for (var k = 0; k < sel.length; k++) {
      var gb = sel[k].geometricBounds; // [L, T, R, B]
      var left = gb[0];
      var top = gb[1];
      var right = gb[2];
      var bottom = gb[3];
      var width = right - left;
      var height = bottom - top;
      var centerX = (left + right) / 2;
      var centerY = (top + bottom) / 2;
      panels.push({
        obj: sel[k],
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        width: width,
        height: height,
        centerX: centerX,
        centerY: centerY
      });
    }

    // Group panels into rows based on center point
    // Two objects are in the same row if the distance between their center Y coordinates
    // is less than or equal to half of the smaller object's height
    var rows = [];
    var processed = [];

    for (var i = 0; i < panels.length; i++) {
      if (processed[i]) continue;

      var row = [panels[i]];
      processed[i] = true;

      // Iteratively add objects to the row until no more can be added
      var changed = true;
      while (changed) {
        changed = false;
        for (var j = 0; j < panels.length; j++) {
          if (processed[j]) continue;

          // Check if this object belongs to the current row
          var belongsToRow = false;
          for (var k = 0; k < row.length; k++) {
            var centerYDiff = Math.abs(panels[j].centerY - row[k].centerY);
            var minHeight = Math.min(panels[j].height, row[k].height);

            // If center distance <= half of smaller object's height, they are in the same row
            if (centerYDiff <= minHeight / 2) {
              belongsToRow = true;
              break;
            }
          }

          if (belongsToRow) {
            row.push(panels[j]);
            processed[j] = true;
            changed = true;
          }
        }
      }

      // Sort row by left position
      row.sort(function (a, b) { return a.left - b.left; });
      rows.push(row);
    }

    // Sort rows by top position (highest first)
    rows.sort(function (a, b) {
      return b[0].top - a[0].top;
    });

    // Align objects: each row to the highest top (smallest top value = highest on screen), each column to the leftmost left
    // In Illustrator, Y axis goes downward, so smaller top = higher on screen
    // First, find the smallest top (highest position) for each row
    var rowMaxTops = [];
    for (var r = 0; r < rows.length; r++) {
      var minTop = rows[r][0].top;
      for (var p = 1; p < rows[r].length; p++) {
        if (rows[r][p].top < minTop) minTop = rows[r][p].top;
      }
      rowMaxTops[r] = minTop; // Smallest top = highest position on screen
    }

    // Group into columns based on center point
    var allPanels = [];
    for (var r = 0; r < rows.length; r++) {
      for (var p = 0; p < rows[r].length; p++) {
        allPanels.push(rows[r][p]);
      }
    }

    var columns = [];
    var colProcessed = [];

    for (var i = 0; i < allPanels.length; i++) {
      if (colProcessed[i]) continue;

      var col = [allPanels[i]];
      colProcessed[i] = true;

      // Iteratively add objects to the column until no more can be added
      var changed = true;
      while (changed) {
        changed = false;
        for (var j = 0; j < allPanels.length; j++) {
          if (colProcessed[j]) continue;

          // Check if this object belongs to the current column
          var belongsToCol = false;
          for (var k = 0; k < col.length; k++) {
            var centerXDiff = Math.abs(allPanels[j].centerX - col[k].centerX);
            var minWidth = Math.min(allPanels[j].width, col[k].width);

            // If center distance <= half of smaller object's width, they are in the same column
            if (centerXDiff <= minWidth / 2) {
              belongsToCol = true;
              break;
            }
          }

          if (belongsToCol) {
            col.push(allPanels[j]);
            colProcessed[j] = true;
            changed = true;
          }
        }
      }

      col.sort(function (a, b) { return b.top - a.top; });
      columns.push(col);
    }

    // Calculate min left for each column
    var colMinLefts = [];
    for (var c = 0; c < columns.length; c++) {
      var minLeft = columns[c][0].left;
      for (var p = 1; p < columns[c].length; p++) {
        if (columns[c][p].left < minLeft) minLeft = columns[c][p].left;
      }
      colMinLefts.push(minLeft);
    }

    // Create mapping from panel object to its row and column indices
    var panelToRow = {};
    var panelToCol = {};

    for (var r = 0; r < rows.length; r++) {
      for (var p = 0; p < rows[r].length; p++) {
        panelToRow[rows[r][p].obj] = r;
      }
    }

    for (var c = 0; c < columns.length; c++) {
      for (var p = 0; p < columns[c].length; p++) {
        panelToCol[columns[c][p].obj] = c;
      }
    }

    // ===== STEP 1: Align objects =====
    if (doAlign) {
      // Align objects: first align columns horizontally, then align rows vertically
      // This order ensures column alignment doesn't affect row alignment

      // Step 1: Align columns first (horizontal alignment)
      // Re-read all current positions
      for (var i = 0; i < panels.length; i++) {
        var gb = panels[i].obj.geometricBounds;
        panels[i].left = gb[0];
        panels[i].top = gb[1];
        panels[i].right = gb[2];
        panels[i].bottom = gb[3];
        panels[i].centerX = (gb[0] + gb[2]) / 2;
        panels[i].centerY = (gb[1] + gb[3]) / 2;
        panels[i].width = gb[2] - gb[0];
        panels[i].height = gb[3] - gb[1];
      }

      // Re-group into columns based on current centerX positions
      var currentColumns = [];
      var colProcessed = [];

      for (var i = 0; i < panels.length; i++) {
        if (colProcessed[i]) continue;

        var col = [panels[i]];
        colProcessed[i] = true;

        // Find all objects in the same column
        var changed = true;
        while (changed) {
          changed = false;
          for (var j = 0; j < panels.length; j++) {
            if (colProcessed[j]) continue;

            var belongsToCol = false;
            for (var k = 0; k < col.length; k++) {
              var centerXDiff = Math.abs(panels[j].centerX - col[k].centerX);
              var minWidth = Math.min(panels[j].width, col[k].width);
              if (centerXDiff <= minWidth / 2) {
                belongsToCol = true;
                break;
              }
            }

            if (belongsToCol) {
              col.push(panels[j]);
              colProcessed[j] = true;
              changed = true;
            }
          }
        }

        currentColumns.push(col);
      }

      // Align each column to the leftmost left
      for (var c = 0; c < currentColumns.length; c++) {
        if (currentColumns[c].length < 2) continue;

        // Find the leftmost left in this column
        var minLeft = currentColumns[c][0].left;
        for (var p = 1; p < currentColumns[c].length; p++) {
          if (currentColumns[c][p].left < minLeft) minLeft = currentColumns[c][p].left;
        }

        // Align all objects in this column to minLeft
        for (var p = 0; p < currentColumns[c].length; p++) {
          var panel = currentColumns[c][p];
          var gb = panel.obj.geometricBounds;
          var currentLeft = gb[0];
          var deltaX = minLeft - currentLeft;

          if (Math.abs(deltaX) > 0.01) {
            panel.obj.translate(deltaX, 0);
          }
        }
      }

      // Step 2: Align rows (vertical alignment) after column alignment
      // Re-read all positions after column alignment
      for (var i = 0; i < panels.length; i++) {
        var gb = panels[i].obj.geometricBounds;
        panels[i].left = gb[0];
        panels[i].top = gb[1];
        panels[i].right = gb[2];
        panels[i].bottom = gb[3];
        panels[i].centerX = (gb[0] + gb[2]) / 2;
        panels[i].centerY = (gb[1] + gb[3]) / 2;
        panels[i].width = gb[2] - gb[0];
        panels[i].height = gb[3] - gb[1];
      }

      // Re-group into rows based on current top positions
      // Use a more lenient tolerance to ensure objects in the same row are grouped together
      var currentRows = [];
      var rowProcessed = [];

      for (var i = 0; i < panels.length; i++) {
        if (rowProcessed[i]) continue;

        var row = [panels[i]];
        rowProcessed[i] = true;
        var rowTop = panels[i].top;

        // Find all objects in the same row using iterative grouping based on top position
        // Use a tolerance based on average height
        var avgHeight = 0;
        for (var h = 0; h < panels.length; h++) {
          avgHeight += panels[h].height;
        }
        avgHeight = avgHeight / panels.length;
        var rowTolerance = Math.max(avgHeight * 0.8, 20); // Use 80% of average height or 20pt, whichever is larger

        var changed = true;
        while (changed) {
          changed = false;
          for (var j = 0; j < panels.length; j++) {
            if (rowProcessed[j]) continue;

            // Check if this object belongs to the current row
            var belongsToRow = false;
            for (var k = 0; k < row.length; k++) {
              // Use top position difference
              var topDiff = Math.abs(panels[j].top - row[k].top);
              // Also check centerY as a secondary criterion
              var centerYDiff = Math.abs(panels[j].centerY - row[k].centerY);
              var minHeight = Math.min(panels[j].height, row[k].height);
              
              // More lenient condition: either top is close OR centerY is close
              if (topDiff <= rowTolerance || centerYDiff <= minHeight) {
                belongsToRow = true;
                break;
              }
            }

            if (belongsToRow) {
              row.push(panels[j]);
              rowProcessed[j] = true;
              changed = true;
            }
          }
        }

        currentRows.push(row);
      }

      // Align each row to the smallest top (highest position)
      var alignedCount = 0;
      var skippedRows = 0;
      for (var r = 0; r < currentRows.length; r++) {
        if (currentRows[r].length < 2) {
          skippedRows++;
          continue;
        }

        // Re-read positions for this row to ensure accuracy
        var rowTops = [];
        for (var p = 0; p < currentRows[r].length; p++) {
          var gb = currentRows[r][p].obj.geometricBounds;
          rowTops.push(gb[1]);
        }

        // Find the smallest top in this row
        var minTop = rowTops[0];
        for (var p = 1; p < rowTops.length; p++) {
          if (rowTops[p] < minTop) minTop = rowTops[p];
        }

        // Align all objects in this row to minTop
        for (var p = 0; p < currentRows[r].length; p++) {
          var panel = currentRows[r][p];
          var gb = panel.obj.geometricBounds;
          var currentTop = gb[1];
          var deltaY = minTop - currentTop;

          if (Math.abs(deltaY) > 0.01) {
            try {
              // Move the object
              panel.obj.translate(0, deltaY);
              alignedCount++;

              // Verify alignment worked
              var newGb = panel.obj.geometricBounds;
              var actualNewTop = newGb[1];

              // If not aligned correctly, try again with correction
              if (Math.abs(actualNewTop - minTop) > 0.1) {
                var correction = minTop - actualNewTop;
                panel.obj.translate(0, correction);
              }
            } catch (e) {
              // If translate fails, skip this object
            }
          }
        }
      }

      alert("Alignment completed: " + panels.length + " objects processed, " + currentRows.length + " rows found, " + skippedRows + " single-object rows skipped, " + alignedCount + " objects aligned vertically (columns first, then rows).");
    }

    // ===== STEP 2: Add labels =====
    if (doLabel) {
      // Use the same sorting method as the original script
      // Row tolerance for determining same row
      var rowTol = 30; // pt

      // Collect all panels with current positions (after alignment if done)
      var panelsForLabel = [];
      for (var i = 0; i < panels.length; i++) {
        var gb = panels[i].obj.geometricBounds;
        panelsForLabel.push({
          obj: panels[i].obj,
          left: gb[0],
          top: gb[1]
        });
      }

      // 1) Sort by top from large to small (top to bottom), then by left (left to right)
      panelsForLabel.sort(function (a, b) {
        var yDiff = b.top - a.top; // top bigger = higher (in Illustrator, larger top means higher on screen)
        if (Math.abs(yDiff) > rowTol) return yDiff;
        return a.left - b.left;    // Same row: left to right
      });

      // 2) Group into rows and ensure strict left to right within each row
      var ordered = [];
      var i = 0;
      while (i < panelsForLabel.length) {
        var rowTop = panelsForLabel[i].top;
        var row = [panelsForLabel[i]];
        i++;
        while (i < panelsForLabel.length && Math.abs(panelsForLabel[i].top - rowTop) <= rowTol) {
          row.push(panelsForLabel[i]);
          i++;
        }
        row.sort(function (a, b) { return a.left - b.left; }); // Within row: left to right
        for (var r = 0; r < row.length; r++) ordered.push(row[r]);
      }

      // 3) Label
      for (var n = 0; n < ordered.length; n++) {
        var p = ordered[n];
        var tf = doc.textFrames.pointText([p.left + dx, p.top - dy]);
        tf.contents = String.fromCharCode(startCharCode + n);

        var ca = tf.textRange.characterAttributes;
        ca.size = fontSize;
        if (arialFont) ca.textFont = arialFont;
      }

      alert("Labeling completed: labeled " + ordered.length + " panels (row-wise left to right) in Arial.");
    }

    if (!doAlign && !doLabel) {
      alert("Both alignment and labeling are disabled. Please enable at least one step.");
    }
  })();

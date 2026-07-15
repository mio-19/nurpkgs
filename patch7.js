const fs = require('fs');
let code = fs.readFileSync('by-name/om/omnimux/src/src/App.tsx', 'utf8');

// Remove ghost element
code = code.replace(
  /<div id="drag-ghost-element"[\s\S]*?\/>\n\s*/,
  ""
);

// Replace the drag props with mouse props
code = code.replace(
  /draggable\s+onDragStart=\{[\s\S]*?\}\s+onDragOver=\{[\s\S]*?\}\s+onDrop=\{[\s\S]*?\}\s+onDragEnd=\{[\s\S]*?\}/,
  `onMouseDown={() => {
                  draggedTabIndex.current = index;
                }}
                onMouseEnter={(e) => {
                  if (e.buttons !== 1) {
                    draggedTabIndex.current = null;
                    return;
                  }
                  if (draggedTabIndex.current !== null && draggedTabIndex.current !== index) {
                    const newTabs = [...tabs];
                    const [removed] = newTabs.splice(draggedTabIndex.current, 1);
                    newTabs.splice(index, 0, removed);
                    setTabs(newTabs);
                    draggedTabIndex.current = index;
                  }
                }}`
);

fs.writeFileSync('by-name/om/omnimux/src/src/App.tsx', code);

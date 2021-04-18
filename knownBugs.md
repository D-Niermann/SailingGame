# Known Bugs

1. Cannonballs hit check if items are placed directly behind doesn't reset to new item because it never left the old item
2. item placement strange, _ready() is called when placed and on_placement() also. But AI ships need that call when loaded in
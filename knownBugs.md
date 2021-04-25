# Known Bugs

1. Cannonballs hit check if items are placed directly behind doesn't reset to new item because it never left the old item
2. item placement strange, _ready() is called when placed and on_placement() also. But AI ships need that call when loaded in
3. Loading NPC Ships causes the game to freeze for some frames -> optimize scripts that are attached to ship
4. In shopping, toggle() method gets called every frame when clicked on item and deselected (and shop is closed i think)
5. gear needs to better refer to the economy gear list - dont make vars for constants in the dict
6. CannonInfoBox and HumanInfoBox bugs when deactivating the box or so, code lines disabled for now, error says thing is null although explicit null check is done right before the line
7. Wehn buying more than 10 cannons ( 10 is the max amount of the shop) it still has a hologram on mouse and when then placing the 11th it crashes
8. WaterShader strange graphical oscillations - the original does also do that. Only on big wave tops, maybe change foam texture tiling or something


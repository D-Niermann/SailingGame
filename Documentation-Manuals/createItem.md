# How to create a new item

## In the editor

1. Create a New folder in a fitting directory under ObjectNodes/Items, each Item should have its own, self-contained folder. All ressources needed to create this item should go into that folder
2. Create a Scene with a KinematicBody Node as root with a box collider, size of collider will be set automatically
3. Add a sprite and set to y axis, lift it up a bit, check for the right dimensions (put the new item in the scaleTestScene for that). Set the Sprite to opaque-prepass, and shaded
4. Attach Script to the KinematicBody Node, create a new script for that
5. If the item should throw 3d Shadow, attach a shadow only mesh



## In Scripts

1. In the newly created item Script, set the extents to

   ```
   extends "res://ObjectNodes/Items/BaseItem.gd"
   ```

   This enables basic item functionality

2. In Economy, in the 'goods' dictionary, define the item parameters by adding a new key which is set to your item name and then copy and paste all keys needed for the item dictionary from another item. set the values to your liking

3. In Econonmy, in the "malls" dictionary, select your malls where the new item should be available and add the item name and the amount

4. If the new Item also contains new goods like some fruit or so, this needs to be added in the consumables dicitonary (in economy.gd) 

## In Editor again

1. In the item scene node, put in your chosen item name into the databaseName field

### Basics are Finished!

Now you can add an Info box and drag the source to the info box variable for that item
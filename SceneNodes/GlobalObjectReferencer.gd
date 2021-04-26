extends Node

"""
This Script references common and often referenced objects like camera, playerShip, ocean and so on.
All other scripts should use this one to refer to objects.

This allows to quickly change references if names, groups or paths of objects change.
"""

var ocean       = null # reference to ocean, the object itself will set this variable when ready
var playerShip  = null # reference to playerShip, the object itself will set this variable when ready
var camera      = null # reference to camera, the object itself will set this variable when ready
var viewport    = null # ref to viewport, set in terminal.gd
var crewManager = null # ref to CrewMaanager, (ssumes it will be a singleton so dont copy on NPC ships)
var shopping    = null # ref to shopping.gd, shopping.gd sets this in its ready() function

## .. add more stuff here

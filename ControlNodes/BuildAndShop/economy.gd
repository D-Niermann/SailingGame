extends Node


# Declare member variables here.
var money: float = 10000
const dropPower: float = 0.125 # bigger values make changes in price due to abundance of an item more drastical
const minCurrency: float = 1.0 # smallest possible money unit, like one cent
var malls: Dictionary = {
	"bananaTown": {
		"capacity": Vector2(0, 100),
		"consumption": 0,
		"grows": {"banana": 2.0},
		"goods": {"banana": 10, "apple": INF, "CannonLarge" : 10, "WallLong" : 100, "LightSmall":5, "GunpowderBarrel" : 20},
		"white": ["food", "gear"],
		"black": ["drug"],
		"money": 1000,
		"part": Vector3(0, 0, 9),
		"loci": Vector3.ZERO
	},
	"appleCity": {
		"capacity": Vector2(0, 100),
		"consumption": 0,
		"grows": {"apple": 1.0},
		"goods": {},
		"white": ["food"],
		"black": [],
		"money": 1000,
		"part": Vector3(4, 0, 4),
		"loci": Vector3.ZERO
	}
}
# when adding new parameters/keys, also add them into BaseItem.fetchDictParams()
const TG_WEAPONS = "tgWeapons" # are strings ok or int better? int = more performance?
const TG_NAVIGATION = "tgNavigation"
const TG_UTILITY = "tgUtility"
const TG_RELAX = "tgRelax"

const IG_GUNPOWDER = "igGunpowder" # gunpowder barrels
const IG_AMMO = "igAmmo" # ammo barrels
const IG_FOOD = "igFood" # foodbarrels
const IG_UTILITY = "igUtils" # repairs, stores woods planks, ropes, tools and so on
const IG_GEAR = "igGear" # no storage items like cannons, table and so on - these typically make the requests and have fixed jobs

var goods: Dictionary = { # TODO: RENAME INTO GEAR or ITEMS, this list is not about goods
	"banana"     : {"type": "food", "size": Vector3(2,1, 1), "penetrationFactor": 0.9, "IG": IG_FOOD, "jobs": {}, "maxHealth": 1, "isCannon" : false, "price": 10, "weight": 1.0, "res": "res://ControlNodes/BuildAndShop/exampleItem.tscn", "icon": "res://icon.png"},
	
	"apple"      : {"type": "food", "size": Vector3(2,1, 1), "penetrationFactor": 0.9, "IG": IG_FOOD, "jobs": {}, "maxHealth": 1, "isCannon" : false, "price": 10, "weight": 1.0, "res": "res://ControlNodes/BuildAndShop/exampleItem.tscn", "icon": "res://icon.png"},
	
	"CannonLarge": {"type": "gear", "size": Vector3(3,1, 2), "penetrationFactor": 0.3, "IG" : IG_GEAR,  
					"jobs": {"Gunner1": {"posOffset":Vector3(0,0,0.1), "TG": TG_WEAPONS, "priority" : 0}, 
							"Gunner2": {"posOffset":Vector3(0,0,-0.1), "TG": TG_WEAPONS, "priority" : 1}},
					"maxHealth": 60, "isCannon" : true, "price": 10, "weight": 10.0, "res": "res://ObjectNodes/Items/Cannon/CannonItem.tscn", "icon": "res://ObjectNodes/Items/Cannon/cannon.png"},
	
	"GunpowderBarrel": {"type": "gear", "size": Vector3(1,1, 1), "penetrationFactor": 0.3, "IG" : IG_GUNPOWDER,  
						"jobs": {},
						"maxHealth": 60, "isCannon" : true, "price": 5, "weight": 1.0, "res": "res://ObjectNodes/Items/Barrels/GunpowderBarrel/GunpowderBarrel.tscn", "icon": "res://ObjectNodes/Items/Barrels/GunpowderBarrel/barrel.png"},

	"WallLong"   : {"type": "gear", "size": Vector3(1,2, 3), "penetrationFactor": 0.6, "IG" : IG_GEAR, "jobs": {}, "maxHealth": 50, "isCannon" : false, "price": 1, "weight": 1.0, "res": "res://ObjectNodes/Items/Walls/WallLong.tscn", "icon": "res://ObjectNodes/Items/Walls/Sprites/Wall.png"},

	## TODO: set up these parameters
	"OuterHullWall"   : {"type": "gear", "size": Vector3(1,2, 3), "penetrationFactor": 0.6, "IG" : IG_GEAR, "jobs": {}, "maxHealth": 50, "isCannon" : false, "price": 1, "weight": 1.0, "res": " ", "icon": " "},
	"OuterHullWall3m"   : {"type": "gear", "size": Vector3(1,2, 3), "penetrationFactor": 0.6, "IG" : IG_GEAR, "jobs": {}, "maxHealth": 50, "isCannon" : false, "price": 1, "weight": 1.0, "res": " ", "icon": " "},
	
	"LightSmall" : {"type": "gear", "size": Vector3(1,1, 1), "penetrationFactor": 0.9, "IG" : IG_GEAR, "jobs": {}, "maxHealth": 3, "isCannon" : false, "price": 1, "weight": 1.0, "res": "res://ObjectNodes/Items/Lights/Light1.tscn", "icon": "res://ObjectNodes/Items/Walls/Sprites/Wall.png"}
}
# var types: Dictionary = { ## this could be auto generated?
# 	"food": ["banana", "apple"],
# 	"gear": ["CannonLarge", "WallLong", "LightSmall"]
# }
var cases: Dictionary = {
	"storm": {
		"banana": 0.5
	},
	"fire": {
		"apple": 0.5
	}
}


# Returns true if the given product can be purchased at the given place.
func canBuy(product: String, at: String):
	var mall = malls.get(at)
	if mall == null:
		return false
	var amount = mall["goods"].get(product)
	if amount == null || amount < 1:
		return false
	var good = goods.get(product)
	if good == null:
		return false
	var type = good["type"]
	if mall["black"].has(type):
		return false
	if !mall["white"].has(type):
		return false
	return true


# Returns true if the given product can be sold at the given place.
func canSell(product: String, at: String):
	var mall = malls.get(at)
	if mall == null:
		return false
	var good = goods.get(product)
	if good == null:
		return false
	var type = good["type"]
	if mall["black"].has(type):
		return false
	if !mall["white"].has(type):
		return false
	var price = getPrice(product, at)
	if mall["money"] < price:
		return false
	return true


# Returns size for the given product.
func getSize(of: String):
	return goods[of]["size"]


# Returns icon for the given product.
func getIcon(of: String):
	return goods[of]["icon"]


# Returns type for the given product.
func getType(of: String):
	return goods[of]["type"]


# Returns weight for the given product.
func getWeight(of: String):
	return goods[of]["weight"]

func getJobs(of: String):
	return goods[of]["jobs"]

	
func getIG(of: String):
	""" returns item group of given item name """
	return goods[of]["IG"]
	
	

# Returns price for the given product at the given place.
func getPrice(of: String, at: String):
	if !malls[at]["goods"].has(of):
		return 0
	else:
		var price: float = goods[of]["price"]
		var amount = getAmount(of, at)
		if amount != INF:
			price = price / max(1.0, pow(getAmount(of, at), dropPower))
		return max(minCurrency, price - fmod(price, minCurrency))


# Returns amount for the given product at the given place.
func getAmount(of: String, at: String):
	if !malls[at]["goods"].has(of):
		return 0
	else:
		return floor(malls[at]["goods"][of])


# Adds grows to goods, and consumes some.
func cycle():
	for mallKey in malls.keys():
		var total: float = 0.0
		var mall: Dictionary = malls[mallKey]
		var canStoreMore: bool = mall["capacity"].x < mall["capacity"].y
		for goodKey in mall["goods"].keys():
			# production
			if canStoreMore && mall["grows"].has(goodKey):
				mall["goods"][goodKey] += mall["grows"][goodKey]
			# consumption
			mall["goods"][goodKey] -= mall["consumption"]
			if mall["goods"][goodKey] <= 0:
				mall["goods"].erase(goodKey)
			else:
				total += mall["goods"][goodKey]
		mall["capacity"].x = total


# Runs a case on the given locations.
func runCase(case: String, at: PoolStringArray):
	var changes: Dictionary = cases[case]
	for mall in at:
		var current: Dictionary = malls[mall]["goods"]
		for key in changes.keys():
			if !current.has(key):
				continue
			var newAmount = current[key] * changes[key]
			newAmount -= fmod(newAmount, goods[key])

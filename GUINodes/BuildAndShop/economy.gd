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
		"goods": {"banana": 10, "apple": INF, "CannonLarge" : 10, "WallLong" : 100, "LightSmall":5},
		"white": ["food", "gear"],
		"black": ["drug"],
		"money": 1000,
		"part": Vector3(0, 0, 9)
	},
	"appleCity": {
		"capacity": Vector2(0, 100),
		"consumption": 0,
		"grows": {"apple": 1.0},
		"goods": {},
		"white": ["food"],
		"black": [],
		"money": 1000,
		"part": Vector3(4, 0, 4)
	}
}
# when adding new parameters/keys, also add them into BaseItem.fetchDictParams()
var goods: Dictionary = {
	"banana"     : {"type": "food", "size": Vector3(2,1, 1), "penetrationFactor": 0.9, "maxHealth": 1, "isCannon" : false, "price": 10, "weight": 1.0, "res": "res://GUINodes/BuildAndShop/exampleItem.tscn", "icon": "res://icon.png"},
	"apple"      : {"type": "food", "size": Vector3(2,1, 1), "penetrationFactor": 0.9, "maxHealth": 1, "isCannon" : false, "price": 10, "weight": 1.0, "res": "res://GUINodes/BuildAndShop/exampleItem.tscn", "icon": "res://icon.png"},
	"CannonLarge": {"type": "gear", "size": Vector3(3,1, 2), "penetrationFactor": 0.3, "maxHealth": 60, "isCannon" : true, "price": 10, "weight": 10.0, "res": "res://ObjectNodes/Items/Cannon/CannonItem.tscn", "icon": "res://ObjectNodes/Items/Cannon/cannon.png"},
	"WallLong"   : {"type": "gear", "size": Vector3(1,2, 3), "penetrationFactor": 0.6, "maxHealth": 50, "isCannon" : false, "price": 1, "weight": 1.0, "res": "res://ObjectNodes/Items/Walls/WallLong.tscn", "icon": "res://ObjectNodes/Items/Walls/Sprites/Wall.png"},
	"LightSmall" : {"type": "gear", "size": Vector3(1,1, 1), "penetrationFactor": 0.9, "maxHealth": 3, "isCannon" : false, "price": 1, "weight": 1.0, "res": "res://ObjectNodes/Items/Lights/Light1.tscn", "icon": "res://ObjectNodes/Items/Walls/Sprites/Wall.png"}
}
var types: Dictionary = { ## this could be auto generated?
	"food": ["banana", "apple"],
	"gear": ["CannonLarge", "WallLong", "LightSmall"]
}
var cases: Dictionary = {
	"storm": {
		"banana": 0.5
	},
	"fire": {
		"apple": 0.5
	}
}


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

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
		"goods": {"banana": 10, "apple": INF, "cannon" : 10},
		"white": ["food", "gear"],
		"black": ["drug"],
		"money": 1000
	},
	"appleCity": {
		"capacity": Vector2(0, 100),
		"consumption": 0,
		"grows": {"apple": 1.0},
		"goods": {},
		"white": ["food"],
		"black": [],
		"money": 1000
	}
}
var goods: Dictionary = {
	"banana": {"type": "food", "size": Vector2(2, 1), "autoSize": true, "price": 10, "weight": 1.0, "res": "res://exampleItem.tscn", "icon": "res://icon.png"},
	"apple": {"type": "food", "size": Vector2(2, 1), "autoSize": true, "price": 10, "weight": 1.0, "res": "res://exampleItem.tscn", "icon": "res://icon.png"}
	"cannon": {"type": "food", "size": Vector2(2, 1), "autoSize": true, "price": 10, "weight": 1.0, "res": "res://ObjectNodes/Items/Cannon/CannonItem.tscn", "icon": "res://icon.png"}
}
var types: Dictionary = {
	"food": ["banana", "apple"],
	"gear": ["cannon"]
}
var cases: Dictionary = {
	"storm": {
		"banana": 0.5
	},
	"fire": {
		"apple": 0.5
	}
}


# Returns true if the given product is expected to have its collider box shape automatically sized.
func shouldAutoSize(of: String):
	return goods[of]["autoSize"]


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

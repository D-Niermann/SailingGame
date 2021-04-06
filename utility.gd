extends Node

var matrix: Image = Image.new()

# Finds path between the given parts.
func findPath(from: Vector3, to: Vector3, canCross: bool, extended: bool):
	var paths: Dictionary = {from: {"path": [from], "dist": 0}}
	var open: Dictionary = {from: null}
	var close: Dictionary = {}
	var limit: int = 100
	while limit > 0 && !open.empty():
		var lowest: Vector3
		var value: int = -1
		for part in open.keys():
			var score: int = paths[part]["dist"] + chebyshevDistance(part, to)
			if value < 0 || score < value:
				value = score
				lowest = part
		close[lowest] = null
		open.erase(lowest)
		var adjacent: Array = findAdjacent(lowest, canCross, extended)
		for part in adjacent:
			if open.has(part) || close.has(part) || !canPass(lowest, part, canCross, extended):
				continue
			var path: Array = paths[lowest]["path"].duplicate(true)
			path.append(part)
			paths[part] = {"path": [path], "dist": paths[lowest]["dist"] + 1}
			open[part] = null
			if part == to:
				return path
		limit -= 1
	var lowest: Vector3
	var value: int = -1
	for part in close.keys():
		var score: int = paths[part]["dist"] + chebyshevDistance(part, to)
		if value < 0 || score < value:
			value = score
			lowest = part
	return paths[lowest]["path"]


# Checks if transition between the given parts is possible.
func canPass(from: Vector3, to: Vector3, canCross: bool, extended: bool):
	var difference: Vector3 = to - from
	var distance: int = chebyshevDistance(from, to)
	if distance > 1:
		return false
	if difference == Vector3.UP || difference == Vector3.DOWN:
		if !extended:
			return false
	if difference.length_squared() > 1:
		if !canCross:
			return false
		var comp: Vector3
		comp = Vector3(difference.x, 0, 0)
		if comp != Vector3.ZERO && isOccupied(from + comp):
			return false
		comp = Vector3(0, difference.y, 0)
		if comp != Vector3.ZERO && isOccupied(from + comp):
			return false
		comp = Vector3(0, 0, difference.z)
		if comp != Vector3.ZERO && isOccupied(from + comp):
			return false
	else:
		if isOccupied(to):
			return false
	return true


# Checks if the given part is occupied.
func isOccupied(partition: Vector3):
	matrix.lock()
	var pixel: Color = matrix.get_pixel(fmod(abs(partition.x), matrix.get_width()), fmod(abs(partition.z), matrix.get_height()))
	matrix.unlock()
	if pixel != Color.black:
		return false
	return true


# Returns adjacent parts for the given part.
func findAdjacent(partition: Vector3, canCross: bool, extended: bool):
	var keys = []
	keys.append(partition + Vector3(1, 0, 0))
	keys.append(partition + Vector3(-1, 0, 0))
	keys.append(partition + Vector3(0, 0, 1))
	keys.append(partition + Vector3(0, 0, -1))
	if canCross:
		keys.append(partition + Vector3(1, 0, 1))
		keys.append(partition + Vector3(1, 0, -1))
		keys.append(partition + Vector3(-1, 0, 1))
		keys.append(partition + Vector3(-1, 0, -1))
	if extended:
		keys.append(partition + Vector3(0, 1, 0))
		keys.append(partition + Vector3(0, -1, 0))
		if canCross:
			keys.append(partition + Vector3(1, 1, 0))
			keys.append(partition + Vector3(-1, 1, 0))
			keys.append(partition + Vector3(0, 1, 1))
			keys.append(partition + Vector3(0, 1, -1))
			keys.append(partition + Vector3(1, 1, 1))
			keys.append(partition + Vector3(1, 1, -1))
			keys.append(partition + Vector3(-1, 1, 1))
			keys.append(partition + Vector3(-1, 1, -1))
			keys.append(partition + Vector3(1, -1, 0))
			keys.append(partition + Vector3(-1, -1, 0))
			keys.append(partition + Vector3(0, -1, 1))
			keys.append(partition + Vector3(0, -1, -1))
			keys.append(partition + Vector3(1, -1, 1))
			keys.append(partition + Vector3(1, -1, -1))
			keys.append(partition + Vector3(-1, -1, 1))
			keys.append(partition + Vector3(-1, -1, -1))
	return keys


# Returns partition identification key for the given location.
func partitionID(location: Vector3, length: float, extended: bool):
	var partition = location / length
	if extended:
		return Vector3(floor(partition.x), floor(partition.y), floor(partition.z))
	else:
		return Vector3(floor(partition.x), 0, floor(partition.z))


# Returns location of the given partition.
func partitionLocation(partition: Vector3, length: float, extended: bool):
	var halfLength = length * 0.5
	if extended:
		return partition * length + Vector3(halfLength, halfLength, halfLength)
	else:
		return partition * length + Vector3(halfLength, 0, halfLength)


# Returns chebyshev distance between two three dimensional vectors.
func chebyshevDistance(from: Vector3, to: Vector3):
	return max(max(abs(from.x - to.x), abs(from.y - to.y)), abs(from.z - to.z))


# Returns manhattan distance between two three dimensional vectors.
func manhattanDistance(from: Vector3, to: Vector3):
	return abs(from.x - to.x) + abs(from.y - to.y) + abs(from.z - to.z)


# Returns signed angle between two three dimensional vectors.
func signedAngle(from: Vector3, to: Vector3, up: Vector3):
	return atan2(to.cross(from).dot(up), from.dot(to))


# Returns time stamp for the given seconds.
func secondsToStamp(seconds: float):
	var stamp: String = ""
	for index in range(2, -1, -1):
		if index != 0:
			var power = pow(60, index)
			var result = int(seconds / power)
			seconds = fmod(seconds, power)
			if result < 10:
				stamp += "0"
			stamp += str(result) + ":"
		else:
			if seconds < 10:
				stamp += "0"
			stamp += str(int(seconds))
	return stamp


# Tries to find the preprocessed form of the given node name from any scene.
func resName(text: String):
	var result = text
	var parts: Array = text.split("@", 2)
	if parts[0] == "":
		result = parts[1]
	else:
		result = parts[0]
	return result


# Creates hash out of given pixels.
func img2Hash(image: Image):
	image.resize(8, 8)
	var pixels = {}
	var total: float = 0.0
	image.lock()
	for i in range(image.get_width()):
		for j in range(image.get_height()):
			var raw: Color = image.get_pixel(i, j)
			var intensity: float = (raw.r + raw.g + raw.b) / 3
			total += intensity
			var cell: Vector2 = Vector2(i, j)
			pixels[cell] = intensity
		
	image.unlock()
	var average = total / pixels.size()
	var bytes: Array = []
	var bits: Array = []
	for key in pixels.keys():
		if pixels[key] < average:
			bits.append(0)
		else:
			bits.append(1)
		if bits.size() == 8:
			bytes.append(toByte(bits))
			bits.clear()
	var imgHash: String = ""
	for byte in bytes:
		imgHash += str(byte)
	return imgHash


# Converts bits to byte.
func toByte(bits: Array):
	var byte = 0
	for i in range(8):
		if bits[i]:
			byte |= 1 << i
	return byte


# Converts byte to bits.
func toBits(byte):
	var bits: Array = [0, 0, 0, 0, 0, 0, 0, 0]
	for i in range(8):
		bits[i] = (byte & (1 << i)) != 0
	return bits


# Loads the given dictionary with the data read from provided json file.
func load2(dictionary: Dictionary, from: String):
	var file: File = File.new()
	file.open(from, File.READ)
	var json: JSONParseResult = JSON.parse(file.get_as_text())
	file.close()
	if json.error == OK:
		dictionary = json.result


# Saves the given dictionary into the json file provided in the path.
func save2(path: String, from: Dictionary):
	var file: File = File.new()
	file.open(path, File.WRITE)
	file.store_string(JSON.print(from, "\t"))
	file.close()


# Gets file names in the given directory
func dir(path: String):
	var files = []
	var directory = Directory.new()
	directory.open(path)
	directory.list_dir_begin()
	while true:
		var file = directory.get_next()
		if file == "":
			break
		elif !file.begins_with("."):
			files.append(file)
	directory.list_dir_end()
	return files


# Saves screenshot.
func printScreen():
	var image = get_viewport().get_texture().get_data()
	image.flip_y()
	var no = 0
	while Directory.new().file_exists("pics/" + str(no) + ".png") && no < 999:
		no += 1
	image.save_png("pics/" + str(no) + ".png")

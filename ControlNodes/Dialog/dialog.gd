extends Control

const CHOICE: PackedScene = preload("res://ControlNodes/Dialog/choice.tscn")

var content: RichTextLabel
var choices: VBoxContainer

var pointer: Array = [] # [dialogID, contentNumber]
var data: Dictionary = {
	"D1": {
		"content": [
			"some text",
			"more text"
		],
		"choices": {
			"C1": "D2",
			"C2": "D2",
			"C3": "D2"
		}
	},
	"D2": {
		"content": [
			"hmm",
			"huh"
		],
		"choices": {
			"C1": null,
			"C2": null,
			"C3": null
		}
	}
}


# Called when the node enters the scene tree for the first time.
func _ready():
	content = get_node("Content")
	choices = get_node("Scroller/Choices")
	# jumpTo("D1", 0) #use this for demonstration


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if visible && Input.is_action_just_pressed("leftClick"):
		next()
	pass


# Opens the given dialog and content, and fills choices if needed.
func jumpTo(dialogID, contentNumber: int):
	clear()
	if !data.has(dialogID):
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	pointer = [dialogID, max(0, contentNumber)]
	addContent()
	if pointer[1] > data[pointer[0]]["content"].size() - 1:
		addChoices()


# Proceeds to the next content or dialog according to position of the pointer.
func next():
	if pointer[1] <= data[pointer[0]]["content"].size():
		pointer[1] += 1
	if pointer[1] <= data[pointer[0]]["content"].size() - 1:
		clear()
		addContent()
	elif pointer[1] == data[pointer[0]]["content"].size():
		addChoices()


# Clears the user interface.
func clear():
	content.clear()
	for child in choices.get_children():
		child.queue_free()


# Prints choices on the user interface according to position of the pointer.
func addChoices():
	content.anchor_bottom = 0.5
	choices.anchor_top = 0.5
	for entry in data[pointer[0]]["choices"].keys():
		var newChoice: Button = CHOICE.instance()
		choices.add_child(newChoice)
		newChoice.get_child(0).bbcode_text = entry
		newChoice.connect("pressed", self, "onChoose", [entry])


# Prints content on the user interface according to position of the pointer.
func addContent():
	content.anchor_bottom = 1.0
	choices.anchor_top = 1.0
	content.bbcode_text = data[pointer[0]]["content"][pointer[1]]


# Switches dialogs when a choice is made.
func onChoose(theChoice: String):
	jumpTo(data[pointer[0]]["choices"][theChoice], 0)

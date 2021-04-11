extends TextureRect

var placeholder # ref to the placeholder in the UI, used for position
var currentHealth
var healthLabel 
var isActive


func updateContent(currentHealth):
	updateHealth(currentHealth)

func updateHealth(currentHealth):
	self.currentHealth = currentHealth
	healthLabel.text = ""
	healthLabel.text = str(round(self.currentHealth))

func _ready():
	healthLabel = $Panel/HealthLabel

func _process(delta):
	print("why am i alive?")
	if placeholder!=null:
		self.rect_position =  placeholder.rect_position


func _on_ActiveToggle_toggled(button_pressed):
	isActive = button_pressed

extends CanvasLayer

signal send_joystick(j : Area2D)

@export var joystick : Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	if OS.get_name() == "Android" or OS.get_name() == "IOS":
		if GameManager.is_dialogue_active == false:
			show()
			send_joystick.emit(joystick)
		else:
			hide()
	else:
		hide()

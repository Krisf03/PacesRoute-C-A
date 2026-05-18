extends CanvasLayer

signal send_joystick(j : Area2D)

@export var joystick : Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "IOS":
		show()
		send_joystick.emit(joystick)
	else:
		hide()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

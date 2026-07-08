extends CanvasLayer

signal send_joystick(j : Area2D)

@export var joystick : Area2D

func _process(_delta: float) -> void:
	if OS.get_name() == "Android" or OS.get_name() == "IOS":
		if not GameManager.is_dialogue_active \
		and not DebugConsole._visible_state:
			show()
			send_joystick.emit(joystick)
		else:
			hide()
	else:
		hide()

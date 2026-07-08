extends CanvasLayer

@onready var animation_player = $AnimationPlayer

func transition_to_scene(target_room_path: String):
	animation_player.play("fade_to_black")
	await animation_player.animation_finished
	
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("change_room"):
		main_scene.change_room(target_room_path)
	
	animation_player.play("fade_from_black")
	await animation_player.animation_finished
	GameManager.the_game_controls = false

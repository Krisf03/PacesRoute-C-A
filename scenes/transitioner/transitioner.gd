extends CanvasLayer

@onready var animation_player = $AnimationPlayer

func transition_to_scene(target_scene_path: String):
	animation_player.play("fade_to_black")
	await animation_player.animation_finished
	
	get_tree().change_scene_to_file(target_scene_path)
	
	animation_player.play("fade_from_black")
	await animation_player.animation_finished
	PlayerManager.the_game_controls = false

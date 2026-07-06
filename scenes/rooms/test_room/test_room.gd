extends Node2D

@export_file("*.tscn") var next_scene : String

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not PlayerManager.the_game_controls:
		if area.owner.is_in_group("player") and next_scene != "":
			PlayerManager.the_game_controls = true
			Transitioner.transition_to_scene(next_scene)

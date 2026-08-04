extends StaticBody2D

const IA_FIRST_MET_DIALOGUE = preload("res://dialogues/ia_first_met.dialogue")

func _input(event: InputEvent) -> void:
	if GameManager.is_near_locked_door:
		if event.is_action_pressed("interact"):
			DialogueManager.show_dialogue_balloon(IA_FIRST_MET_DIALOGUE, "locked_door")
			
			await get_tree().create_timer(1).timeout
			
			if not GameManager.has_read_locked_door:
				GameManager.has_read_locked_door = true

func _on_interact_area_2d_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("player"):
		GameManager.is_near_locked_door = true


func _on_interact_area_2d_area_exited(area: Area2D) -> void:
	if area.owner.is_in_group("player"):
		GameManager.is_near_locked_door = false

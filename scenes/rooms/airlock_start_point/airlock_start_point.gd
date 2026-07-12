extends Node2D

const IA_FIRST_MET_DIALOGUE = preload("res://dialogues/ia_first_met.dialogue")

@export_file("*.tscn") var next_scene : String

func _ready() -> void:
	DialogueManager.show_dialogue_balloon(IA_FIRST_MET_DIALOGUE, "first_act")

func _on_second_act_area_2d_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("player") and not GameManager.has_read_second_act:
		DialogueManager.show_dialogue_balloon(IA_FIRST_MET_DIALOGUE, "second_act")
		GameManager.has_read_second_act = true

func _on_third_act_area_2d_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("player") and not GameManager.has_read_third_act:
		DialogueManager.show_dialogue_balloon(IA_FIRST_MET_DIALOGUE, "third_act")
		GameManager.has_read_third_act = true


func _on_exit_area_2d_area_entered(area: Area2D) -> void:
	if not GameManager.the_game_controls:
		if area.owner.is_in_group("player") and next_scene:
			GameManager.the_game_controls = true
			Transitioner.transition_to_scene(next_scene)

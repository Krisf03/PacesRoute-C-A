extends Node2D

const IA_FIRST_MET_DIALOGUE = preload("res://dialogues/ia_first_met.dialogue")

func _ready() -> void:
	GameManager.the_game_controls = true
	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue_balloon(IA_FIRST_MET_DIALOGUE, "break")

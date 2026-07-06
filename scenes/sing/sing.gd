extends Node2D

var is_player_close := false

#Constante que contiene la ruta del dialogo
const _INTERACT_TUTORIAL = preload("res://dialogues/interact_tutorial.dialogue")

func _area_entered(area):
	if area.owner.is_in_group("player"):
		is_player_close = true

func _area_exited(area):
	if area.owner.is_in_group("player"):
		is_player_close = false

func _process(_delta: float) -> void:
	if is_player_close and Input.is_action_just_pressed("interact") \
		and GameManager.is_dialogue_active == false \
		and PlayerManager.is_dead == false:
		DialogueManager.show_dialogue_balloon(_INTERACT_TUTORIAL, "start")

#Iniciar diálogo
func _on_dialogue_started(_dialogue):
	GameManager.is_dialogue_active = true

#Terminar dialogo
func _on_dialogue_ended(_dialogue):
	await get_tree().create_timer(0.2).timeout
	GameManager.is_dialogue_active = false

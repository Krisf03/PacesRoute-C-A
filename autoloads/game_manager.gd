extends Node

#Variiable para detectar si se está en dialogo
var is_dialogue_active := false

#Registra interacción del jugador con el mundo
var has_met_enemy01 = false

#Eventos según las decisiones del jugador
signal player_steps_aside
signal enemy_attacks

func  _ready() -> void:
	#Detectar si está en dialogo
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

#Activar dialogo
func _on_dialogue_started(_dialogue):
	is_dialogue_active = true

#Terminar dialogo
func _on_dialogue_ended(_dialogue):
	await get_tree().create_timer(0.2).timeout
	is_dialogue_active = false

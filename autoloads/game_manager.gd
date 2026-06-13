extends Node

#Variiable para detectar si se está en dialogo
var is_dialogue_active := false

#Registra interacción del jugador con el mundo
var has_met_enemy01 = false

#Eventos según las decisiones del jugador
signal player_steps_aside
signal enemy_attacks

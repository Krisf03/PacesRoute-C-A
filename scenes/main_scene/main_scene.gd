extends Node2D

var current_room_path := ""

@export var room_container : Node2D
@export var player : CharacterBody2D
@export var hud : CanvasLayer

func _ready() -> void:
	if player and hud:
		GameManager.health_changed.connect(hud.update_health)
		hud.update_health(GameManager.health, GameManager.max_health)

func change_room(room_path: String) -> void:
	current_room_path = room_path
	# 1. Limpiar la habitación anterior de forma segura
	for child in room_container.get_children():
		child.queue_free()
	
	# 2. Cargar la nueva escena desde la ruta de archivos
	var new_room_scene = load(room_path)
	if new_room_scene:
		var room_instance = new_room_scene.instantiate()
		room_container.add_child(room_instance)
		
		# 3. Posicionar al jugador en el SpawnPoint de la nueva habitación
		_teleport_player_to_spawn(room_instance)

func _teleport_player_to_spawn(room_instance: Node) -> void:
	# Buscar el Marker2D llamado 'SpawnPoint' dentro del cuarto instanciado
	var spawn_point = room_instance.get_node_or_null("SpawnPoint")
	if spawn_point and spawn_point is Marker2D:
		player.global_position = spawn_point.global_position

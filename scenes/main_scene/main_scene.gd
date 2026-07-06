extends Node2D

@onready var room_container = $RoomContainer
@onready var player = $Player

func change_room(room_path: String) -> void:
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

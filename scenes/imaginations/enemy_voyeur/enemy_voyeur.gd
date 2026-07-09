extends CharacterBody2D

var _last_movement_animation := "idle_front"
@export var detection_area : Area2D

#diccionario para la animación según la dirección del personaje 
var animaciones = {
	Vector2.RIGHT: "run_horizontal", 
	Vector2.LEFT: "run_horizontal",
	Vector2.UP: "run_back",
	Vector2.DOWN: "run_front",
	
	#Diagonales
	Vector2(1, 1): "run_horizontal",
	Vector2(-1, 1): "run_horizontal",
	Vector2(1, -1): "run_horizontal",
	Vector2(-1, -1): "run_horizontal"
}

# Stats (Eliminamos daño y cooldowns de ataque)
@export var health := 3
@export var player_ref = null
@export var is_dead := false

# Constantes de velocidad en base a la escala
const PPM = 32
const SPRITE_SCALE = 1

var _facing_direction = Vector2.DOWN

# Variables para dirección y velocidad
var direction : Vector2
var speed = 3.0 * PPM * SPRITE_SCALE
# Límite de movimiento en pixeles
var left_limit := 600
var right_limit := 1150

# Variable para detectar al jugador
var is_player_close := false

# Variables y constantes para el knockback (Mantenidas por si decides golpearlo)
var _knockback_velocity := Vector2.ZERO
const _KNOCKBACK_FORCE := 450.0
const _KNOCKBACK_DECAY := 1000.0

# Variable animación
@onready var _animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	platform_wall_layers = 0
	platform_floor_layers = 0
	# Mover el personaje apenas iniciar
	direction = Vector2(1, 0)

# Movimiento del personaje y comportamiento de mirada
func _physics_process(delta: float) -> void:
	if is_dead == true:
		return
	if not player_ref:
		for body in detection_area.get_overlapping_bodies():
			if body.is_in_group("player"):
				player_ref = body
				break
		
	# Reducir gradualmente el knockback hasta 0 usando "delta"
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, _KNOCKBACK_DECAY * delta)
	
	# ¿El jugador está dentro del rango de visión?
	if player_ref and not GameManager.is_dead:
		# 1. Detener patrullaje (La velocidad base se vuelve 0, solo le afecta el knockback si le pegas)
		velocity = _knockback_velocity
		
		# 2. Calcular la dirección exacta hacia el jugador para quedarse mirándolo
		var direction_to_player = (player_ref.global_position - global_position).normalized()
		direction = direction_to_player
	else:
		# Patrulla normal de lado a lado si el jugador no está cerca
		direction.y = 0
		direction.x = 1 if direction.x > 0 else -1
		if position.x < left_limit:
			direction = Vector2(1, 0)
		if position.x > right_limit:
			direction = Vector2(-1, 0)
			
		velocity = direction * speed + _knockback_velocity
		
		if direction != Vector2.ZERO:
			_facing_direction = direction
	
	move_and_slide()
	_calculate_flip_h() # Al actualizar _facing_direction arriba, esto lo girará hacia ti
	
	_animation_run()

# --- REUTILIZACIÓN DE SEÑALES DE DETECCIÓN ---
# Consejo: Para ahorrar tiempo en el editor de Godot, puedes usar el mismo Area2D que tenías antes
func _on_detection_area_entered(area):
	if area.owner != null and area.owner.has_method("_take_damage"):
		player_ref = area.owner
		is_player_close = true

func _on_detection_area_exited(area):
	if area.owner == player_ref:
		await get_tree().create_timer(0.2).timeout
		if not is_inside_tree():
			return
		player_ref = null
		is_player_close = false

func _take_damage(amount: int, source_position: Vector2):
	#print("recibí daño: ", amount)
	health -= amount
	#print("Vida actual: ", health)
	
	#Calculamos la dirección del empuje y la aplicamos
	var knockback_direction = (global_position - source_position).normalized()
	_knockback_velocity = knockback_direction * _KNOCKBACK_FORCE
	
	if health <= 0:
		_die()

func  _die():
	is_dead = true
	#print("ME MORÍ")
	_animated_sprite.stop()
	velocity = Vector2(0, 0)
	await  get_tree().create_timer(1).timeout
	if not is_inside_tree():
		return
	queue_free()

func _animation_run():
	if direction != Vector2.ZERO:
		# El personaje se está moviendo
		var rounded_direction = direction.snapped(Vector2.ONE) 

		if animaciones.has(rounded_direction):
			var animation_name = animaciones[rounded_direction]
			_animated_sprite.play(animation_name)
			# GUARDAMOS LA ANIMACIÓN: Recordamos qué animación de correr se usó
			_last_movement_animation = animation_name
	else:
		# EL PERSONAJE SE DETUVO: Cambiamos "run_" por "idle_" usando la última animación guardada
		var idle_animation = _last_movement_animation.replace("run_", "idle_")
		_animated_sprite.play(idle_animation)

func _calculate_flip_h():
	if is_dead == true:
		return
	if !is_zero_approx(direction.x):
		_animated_sprite.flip_h = direction.x < 0

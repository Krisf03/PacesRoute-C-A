extends CharacterBody2D

# Stats
@export var health := 3
@export var attack_damage := 1
@export var attack_cooldown := 1
@export var can_attack := true
@export var player_ref = null
@export var is_dead := false

# Constantes de velocidad en base a la escala
const PPM = 32
const SPRITE_SCALE = 1

var _facing_direction = Vector2.DOWN
@export var _attack_area : Area2D
@export var _detection_area : Area2D # NUEVA: Área para detectar la persecución

# Variables para dirección y velocidad
var direction : Vector2
var speed = 3.0 * PPM * SPRITE_SCALE

# Límite de movimiento en pixeles (Patrullaje)
var left_limit := 600
var right_limit := 1150

# Variable para almacenar al jugador cuando entra en el rango de persecución
var chase_target: Node2D = null

# Variables y constantes para el knockback
var _knockback_velocity := Vector2.ZERO
const _KNOCKBACK_FORCE := 450.0
const _KNOCKBACK_DECAY := 1000.0

# Variable animación
@export var animated_sprite : AnimatedSprite2D

func _ready() -> void:
	platform_wall_layers = 0
	platform_floor_layers = 0
	direction = Vector2(1, 0)
	
	# Conectar las señales de la zona de detección dinámicamente si no lo haces desde el editor
	if _detection_area:
		_detection_area.area_entered.connect(_on_player_detection_area_entered)
		_detection_area.area_exited.connect(_on_player_detection_area_exited)

func _physics_process(delta: float) -> void:
	if is_dead == true:
		return
		
	# LÓGICA DE MOVIMIENTO: ¿Persiguiendo o Patrullando?
	if chase_target and not GameManager.is_dead and not GameManager.is_dialogue_active:
		# Calcular dirección hacia el jugador (Persecución en 360°)
		direction = (chase_target.global_position - global_position).normalized()
	else:
		# Movimiento de patrullaje original de lado a lado
		direction.y = 0
		direction.x = 1 if direction.x > 0 else -1
		if position.x < left_limit:
			direction = Vector2(1, 0)
		elif position.x > right_limit: # Cambiado a 'elif' para evitar conflictos de frames
			direction = Vector2(-1, 0)
		
	# Reducir gradualmente el knockback hasta 0 usando "delta"
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, _KNOCKBACK_DECAY * delta)
	
	velocity = direction * speed + _knockback_velocity
	
	if direction != Vector2.ZERO:
		_facing_direction = direction
	
	move_and_slide()
	_calculate_flip_h()
	
	if can_attack == true:
		_animation_run()
		
	_update_attack_position()

func _process(_delta: float) -> void:
	if not chase_target:
		for body in _detection_area.get_overlapping_bodies():
			if body.is_in_group("player"):
				chase_target = body
				break
	if player_ref != null and can_attack \
		and not GameManager.is_dialogue_active \
		and not GameManager.is_dead:
		_attack_player()

# --- DETECCIÓN PARA PERSECUCIÓN ---
func _on_player_detection_area_entered(area):
	# Ajusta esto dependiendo de si el jugador es un Area2D o si usas su Hurtbox
	if area.owner != null and area.owner.has_method("_take_damage"):
		chase_target = area.owner

func _on_player_detection_area_exited(area):
	if area.owner == chase_target:
		chase_target = null

# --- DETECCIÓN PARA ATAQUE (Se mantiene igual) ---
func _attack_area_entered(area):
	if area.owner != null and area.owner.has_method("_take_damage"):
		player_ref = area.owner

func _attack_area_exited(area):
	if area.owner == player_ref:
		await get_tree().create_timer(0.2).timeout
		if not is_inside_tree():
			return
		player_ref = null

func _update_attack_position():
	if is_dead == true:
		return
	if abs(_facing_direction.x) > abs(_facing_direction.y):
		if _facing_direction.x > 0:
			_attack_area.position = Vector2(24, 0)
		else:
			_attack_area.position = Vector2(-24, 0)
	else:
		if _facing_direction.y > 0:
			_attack_area.position = Vector2(0, 24)
		else:
			_attack_area.position = Vector2(0, -24)

func _attack_player():
	if is_dead == true:
		return
	can_attack = false
	
	_attack_animation()
	
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	
	if player_ref == null:
		can_attack = true
		return
	
	player_ref._take_damage(attack_damage, global_position)
	
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_inside_tree():
		return
	
	can_attack = true

func _take_damage(amount: int, source_position: Vector2):
	health -= amount
	
	var knockback_direction = (global_position - source_position).normalized()
	_knockback_velocity = knockback_direction * _KNOCKBACK_FORCE
	
	if health <= 0:
		_die()

func _die():
	is_dead = true
	animated_sprite.stop()
	velocity = Vector2(0, 0)
	await get_tree().create_timer(1).timeout
	if not is_inside_tree():
		return
	queue_free()
	
func _animation_run():
	if is_dead == true:
		return
	if velocity != Vector2.ZERO:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

func _attack_animation():
	if is_dead == true:
		return
	animated_sprite.play("header")
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	_animation_run()

func _calculate_flip_h():
	if is_dead == true:
		return
	if !is_zero_approx(direction.x):
		animated_sprite.flip_h = direction.x < 0

extends CharacterBody2D

#Stats
@export var health := 3
@export var attack_damage := 1
@export var attack_cooldown := 1
@export var can_attack := true
@export var player_ref = null
@export var is_dead := false
@export var is_attacking := false

#Constantes de velocidad en base a la escala
const PPM = 32
const SPRITE_SCALE = 1

#Constante que contiene la ruta del dialogo
const TEST_GREETING = preload("uid://dejlirvax3g55")

var _facing_direction = Vector2.DOWN

@export var _attack_area : Area2D

#Variables para dirección y velocidad
var direction : Vector2
var speed = 3.0 * PPM * SPRITE_SCALE

#Límite de movimiento en pixeles
@export var left_limit := 600
@export var right_limit := 1150

#Variable para detectar al jugador
var is_player_close := false

#Variables y constantes para el knockback
var _knockback_velocity := Vector2.ZERO

const _KNOCKBACK_FORCE := 450.0
const _KNOCKBACK_DECAY := 1000.0

#Variable animación
@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.self_modulate = Color.GREEN
	
	#Señales para eventos de diálogo
	GameManager.enemy_attacks.connect(_attack_player)
	
	platform_wall_layers = 0
	platform_floor_layers = 0
	direction = Vector2(1, 0)

#Movimiento del personaje de lado a lado
func _physics_process(delta: float) -> void:
	if not is_attacking:
		_animation_run()
		
	_calculate_flip_h()
	
	if is_dead or GameManager.is_dialogue_active or is_attacking:
		return
	
	#Patrulla
	if position.x < left_limit:
		direction = Vector2(1, 0)
	if position.x > right_limit:
		direction = Vector2(-1, 0)
	
	#Reducir gradualmente el knockback
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, _KNOCKBACK_DECAY * delta)
	
	velocity = direction * speed + _knockback_velocity
	
	if direction != Vector2.ZERO:
		_facing_direction = direction
	
	move_and_slide()
	
	_update_attack_position()

#Gestiona diálogos del enemigo
func _process(_delta: float) -> void:
	if is_dead:
		return
	
	# Iniciar diálogo con interact
	if is_player_close and Input.is_action_just_pressed("interact") \
			and not GameManager.is_dialogue_active \
			and not PlayerManager.is_dead:
		DialogueManager.show_dialogue_balloon(TEST_GREETING, "start")
		animated_sprite.stop()
		GameManager.is_dialogue_active = true

func _area_entered(_area):
	is_player_close = true
	if _area.owner != null and _area.owner.has_method("_take_damage"):
		player_ref = _area.owner

func _area_exited(_area):
	is_player_close = false
	if _area.owner == player_ref:
		await get_tree().create_timer(0.2).timeout
		player_ref = null

func _update_attack_position():
	if is_dead:
		return
	if abs(_facing_direction.x) > abs(_facing_direction.y):
		_attack_area.position = Vector2(24 if _facing_direction.x > 0 else -24, 0)
	else:
		_attack_area.position = Vector2(0, 24 if _facing_direction.y > 0 else -24)

func _attack_player():
	if is_dead:
		return
	# FIX: se pone can_attack = false para que _process no lo llame de nuevo
	can_attack = false
	is_attacking = true
	_attack_animation()
	await get_tree().create_timer(0.6).timeout
	
	if player_ref == null:
		is_attacking = false
		return
	
	player_ref._take_damage(attack_damage, global_position)
	await get_tree().create_timer(attack_cooldown).timeout
	is_attacking = false

func _take_damage(amount: int, source_position: Vector2):
	# FIX: quitar los print() en producción — cuestan mucho en el editor
	health -= amount
	var knockback_direction = (global_position - source_position).normalized()
	_knockback_velocity = knockback_direction * _KNOCKBACK_FORCE
	if health <= 0:
		_die()

func _die():
	is_dead = true
	animated_sprite.stop()
	velocity = Vector2.ZERO
	await get_tree().create_timer(1).timeout
	queue_free()

func _animation_run():
	if is_dead or is_attacking:
		return
	
	if GameManager.is_dialogue_active:
		animated_sprite.play("walk")
		animated_sprite.stop()
	elif velocity != Vector2.ZERO:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

func _attack_animation():
	if is_dead:
		return
	animated_sprite.play("header")
	await get_tree().create_timer(1).timeout
	_animation_run()

func _calculate_flip_h():
	if is_dead:
		return
	
	if is_player_close and GameManager.is_dialogue_active or is_attacking:
		if player_ref != null and player_ref.global_position.x > global_position.x:
			animated_sprite.flip_h = false
		elif player_ref != null:
			animated_sprite.flip_h = true
	else:
		if not is_zero_approx(direction.x):
			animated_sprite.flip_h = direction.x < 0

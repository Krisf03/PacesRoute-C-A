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
var left_limit := 600
var right_limit := 1150

#Variable para detectar al jugador
var is_player_close := false

#Variables y constantes para el knockback
var _knockback_velocity := Vector2.ZERO

const _KNOCKBACK_FORCE := 450.0
const _KNOCKBACK_DECAY := 1000.0

#Variable animación
@export var animated_sprite : AnimatedSprite2D

func _ready() -> void:
	animated_sprite.self_modulate = Color.GREEN
	
	#Señales para eventos de diálogo
	GameManager.enemy_attacks.connect(_attack_player)
	
	platform_wall_layers = 0
	platform_floor_layers = 0
	#Mover el personaje apenas iniciar
	direction = Vector2(1, 0)
	
	#Detectar si está en dialogo
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

#Movimiento del personaje de lado a lado
func _physics_process(delta: float) -> void:
	if is_dead == true:
		return
	if GameManager.is_dialogue_active == true:
		return
	
	#Patrulla
	if position.x < left_limit:
		direction = Vector2(1, 0)
	if position.x > right_limit:
		direction = Vector2(-1, 0)
		
	#Reducir gradualmente el knockback hasta 0 usando "delta"
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, _KNOCKBACK_DECAY * delta)
	
	velocity = direction * speed + _knockback_velocity
	
	if direction != Vector2.ZERO:
		_facing_direction = direction
	
	move_and_slide()
	_calculate_flip_h()
	
	if is_attacking == false:
		_animation_run()
	
	_update_attack_position()

#Estar pendiente a iniciar el dialogo
func _process(_delta: float) -> void:
	if is_dead == true:
		return
	if is_player_close and Input.is_action_just_pressed("interact") and GameManager.is_dialogue_active == false and CharacterManager.is_dead == false:
		DialogueManager.show_dialogue_balloon(TEST_GREETING, "start")
		animated_sprite.stop()
		GameManager.is_dialogue_active = true
		
	if is_player_close and can_attack == true and player_ref != null and GameManager.is_dialogue_active == false and CharacterManager.is_dead == false:
		_attack_player()

#Detectar al personaje para una interacción
func _area_entered(_area):
	is_player_close = true

#Detectar que el personaje se ha alejado
func _area_exited(_area):
	is_player_close = false

func _attack_area_entered(area):
	if area.owner != null and area.owner.has_method("_take_damage"):
		player_ref = area.owner

func _attack_area_exited(area):
	if area.owner == player_ref:
		await get_tree().create_timer(0.2).timeout
		player_ref = null

#Activar dialogo
func _on_dialogue_started(_dialogue):
	GameManager.is_dialogue_active = true

#Terminar dialogo
func _on_dialogue_ended(_dialogue):
	await get_tree().create_timer(0.2).timeout
	GameManager.is_dialogue_active = false

func _attack_player():
	if is_dead == true:
		return
		
	is_attacking = true
	_attack_animation()
	await  get_tree().create_timer(0.5).timeout
	
	if player_ref == null:
		is_attacking = false
		return
	
	player_ref._take_damage(attack_damage, global_position)
	await  get_tree().create_timer(attack_cooldown).timeout
	is_attacking = false

func _take_damage(amount: int, source_position: Vector2):
	print("recibí daño: ", amount)
	health -= amount
	print("Vida actual: ", health)
	
	#Calculamos la dirección del empuje y la aplicamos
	var knockback_direction = (global_position - source_position).normalized()
	_knockback_velocity = knockback_direction * _KNOCKBACK_FORCE
	
	if health <= 0:
		_die()

func  _die():
	is_dead = true
	print("ME MORÍ")
	animated_sprite.stop()
	velocity = Vector2(0, 0)
	await  get_tree().create_timer(1).timeout
	queue_free()
	
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

#Animación
func _animation_run():
	if is_dead == true:
		return
	if GameManager.is_dialogue_active == true:
		animated_sprite.stop()
	else:
		if velocity != Vector2.ZERO:
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")

func _attack_animation():
	if is_dead == true:
		return
	animated_sprite.play("header")
	await  get_tree().create_timer(0.9).timeout
	_animation_run()

#Voltear según a donde camina
func _calculate_flip_h():
	if is_dead == true:
		return
	if !is_zero_approx(direction.x):
		animated_sprite.flip_h = direction.x < 0

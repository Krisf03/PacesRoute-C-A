extends CharacterBody2D

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
var left_limit := 40
var right_limit := 450

#Variable para detectar al jugador
var is_player_close := false

#Variable animación
@export var animated_sprite : AnimatedSprite2D

func _ready() -> void:
	platform_wall_layers = 0
	platform_floor_layers = 0
	#Mover el personaje apenas iniciar
	direction = Vector2(1, 0)

	#Detectar si está en dialogo
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

#Movimiento del personaje de lado a lado
func _physics_process(_delta: float) -> void:
	if position.x < left_limit:
		direction = Vector2(1, 0)
	if position.x > right_limit:
		direction = Vector2(-1, 0)
	velocity = direction * speed
	
	if direction != Vector2.ZERO:
		_facing_direction = direction
	
	move_and_slide()
	_calculate_flip_h()
	
	if EnemyManager.can_attack == true:
		_animation_run()
		
	_update_attack_position()

#Estar pendiente a iniciar el dialogo
func _process(_delta: float) -> void:
	if is_player_close and Input.is_action_just_pressed("interact") and GameManager.is_dialogue_active == false:
		DialogueManager.show_dialogue_balloon(TEST_GREETING, "start")
		
	if is_player_close and EnemyManager.can_attack == true and EnemyManager.player_ref != null and GameManager.is_dialogue_active == false and CharacterManager.is_dead == false:
		_attack_player()

#Voltear según a donde camina
func _calculate_flip_h():
	if !is_zero_approx(direction.x):
		animated_sprite.flip_h = direction.x < 0

#Animación
func _animation_run():
	if velocity != Vector2.ZERO:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

func _attack_animation():
	animated_sprite.play("header")
	await  get_tree().create_timer(0.9).timeout
	_animation_run()

#Detectar al personaje para una interacción
func _area_entered(_area):
	is_player_close = true


#Detectar que el personaje se ha alejado
func _area_exited(_area):
	is_player_close = false


func _attack_area_entered(area):
	if area.owner != null and area.owner.has_method("_take_damage"):
		EnemyManager.player_ref = area.owner

func _attack_area_exited(area):
	if area.owner == EnemyManager.player_ref:
		EnemyManager.player_ref = null

#Activar dialogo
func _on_dialogue_started(_dialogue):
	GameManager.is_dialogue_active = true

#Terminar dialogo
func _on_dialogue_ended(_dialogue):
	await get_tree().create_timer(0.2).timeout
	GameManager.is_dialogue_active = false

func _attack_player():
	EnemyManager.can_attack = false
	EnemyManager.player_ref._take_damage(EnemyManager.attack_damage)
	
	_attack_animation()
	
	await  get_tree().create_timer(EnemyManager.attack_cooldown).timeout
	EnemyManager.can_attack = true

func _take_damage(amount):
	print("recibí daño: ", amount)
	EnemyManager.health -= amount
	print("Vida actual: ", EnemyManager.health)
	
	if EnemyManager.health <= 0:
		_die()

func  _die():
	print("ME MORÍ")
	queue_free()
	
func _update_attack_position():
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

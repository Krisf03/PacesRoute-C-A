extends CharacterBody2D

#Constantes de velocidad en base a la escala
const PPM = 32
const SPRITE_SCALE = 1

#Constante que contiene la ruta del dialogo
const TEST_GREETING = preload("uid://dejlirvax3g55")

#Variables para dirección y velocidad
var direction : Vector2
var speed = 3.0 * PPM * SPRITE_SCALE
#Límite de movimiento en pixeles
var left_limit := 30
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
	move_and_slide()
	_calculate_flip_h()
	_animation_run()

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

#Detectar al personaje para una interacción
func _area_entered(_area):
	is_player_close = true

#Detectar que el personaje se ha alejado
func _area_exited(_area):
	is_player_close = false

#Activar dialogo
func _on_dialogue_started(_dialogue):
	GameManager.is_dialogue_active = true

#Terminar dialogo
func _on_dialogue_ended(_dialogue):
	await get_tree().create_timer(0.2).timeout
	GameManager.is_dialogue_active = false

#Estar pendiente a iniciar el dialogo
func _process(_delta: float) -> void:
	if is_player_close and Input.is_action_just_pressed("ui_accept") and GameManager.is_dialogue_active == false:
		DialogueManager.show_dialogue_balloon(TEST_GREETING, "start")

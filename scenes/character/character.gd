extends CharacterBody2D

#Constantes de velocidad según la escala del personaje
const PPM = 32
const SPRITE_SCALE = 2

#variables para el movimiento 
var joystick : Area2D
var direction : Vector2
var speed = 3.0 * PPM * SPRITE_SCALE

#Variiable para detectar si se está en dialogo
var _is_dialogue_active := false

#variable para la animación 
@export var animated_sprite : AnimatedSprite2D

#variable para detectar objetos interactuables con raycast
@export var interact : RayCast2D

func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

#función para el movimiento del personaje 
func _physics_process(_delta: float) -> void:
	#diferencia entre dirección de joystick y dirección del teclado 
	var joystick_direction = Vector2.ZERO
	var keyboard_direction : Vector2
	if _is_dialogue_active == false:
		keyboard_direction = Input.get_vector(
			"ui_left",
			"ui_right",
			"ui_up",
			"ui_down"
		)

	#calcula la dirección del joystick y lo mete en su variable 
	if joystick != null and is_instance_valid(joystick) and _is_dialogue_active == false:
		joystick_direction = joystick.direction

	#suma las variables, para que no decidir una u otra, y se normaliza para evitar velocidades exageradas
	direction = joystick_direction + keyboard_direction
	direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()

	_calculate_flip_h()

	_animation_run()

#para que mire en la dirección correcta 
func _calculate_flip_h():
	if !is_zero_approx(direction.x):
		animated_sprite.flip_h = direction.x < 0
		
#para que la animación funcione en cada frame
func _animation_run():
	if velocity != Vector2.ZERO:
		animated_sprite.play("Walk")
		animated_sprite.position.y =+ 6.5
	else:
		animated_sprite.play("idle")
		animated_sprite.position.y =- 6.5

func receive_joystick(j: Area2D) -> void:
	joystick = j

#Activar dialogo
func _on_dialogue_started(_dialogue):
	_is_dialogue_active = true

#Terminar dialogo
func _on_dialogue_ended(_dialogue):
	await get_tree().create_timer(0.2).timeout
	_is_dialogue_active = false
func _process(_delta: float) -> void:
	if _is_dialogue_active == false:
		pass

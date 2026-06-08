extends CharacterBody2D

var _last_movement_animation := "idle_front"

#diccionario para la animación según la dirección del personaje 

var animaciones = {Vector2.RIGHT: "run_horizontal", 
Vector2.LEFT: "run_horizontal",
Vector2.UP: "run_back",
Vector2.DOWN: "run_front"
}

#Constantes de velocidad según la escala del personaje
const PPM = 32
const SPRITE_SCALE = 2

#variables para el movimiento 
var joystick : Area2D
var direction : Vector2
var speed = 3.0 * PPM * SPRITE_SCALE

#variable para saber a donde mira el personaje
var _facing_direction := Vector2.DOWN

#variable para saber si está atacando
var _is_attacking := false

#variable para almacenar temporalmente los enemigos que fueron atacados
var _targets_in_range := []

#variable para la animación 
@export var _animated_sprite : AnimatedSprite2D

#variable para el ataque
@export var _attack_area : Area2D

func _ready() -> void:
	#Desactivo el área de ataque
	_attack_area.monitoring = false
	
	#Arreglando bug de colisiones "efecto carrito"
	platform_floor_layers = 0
	platform_wall_layers = 0
	
	#Dialogos
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

#función para el movimiento del personaje 
func _physics_process(_delta: float) -> void:
	#diferencia entre dirección de joystick y dirección del teclado 
	var joystick_direction := Vector2.ZERO
	var keyboard_direction := Vector2.ZERO
	if GameManager.is_dialogue_active == false:
		keyboard_direction = Input.get_vector(
			"ui_left",
			"ui_right",
			"ui_up",
			"ui_down"
		)

	#calcula la dirección del joystick y lo mete en su variable 
	if joystick != null and is_instance_valid(joystick) and GameManager.is_dialogue_active == false:
		joystick_direction = joystick.direction

	#suma las variables, para que no decidir una u otra, y se normaliza para evitar velocidades exageradas
	direction = joystick_direction + keyboard_direction
	direction = direction.normalized()

	#Cambiar la dirección hacia donde mira por si ataca
	if direction != Vector2.ZERO:
		_facing_direction = direction
	
	velocity = direction * speed
	move_and_slide()
	
	if Input.is_action_just_pressed("attack"):
		_attack()

	_calculate_flip_h()

	_animation_run()


func _on_attack_area_body_entered(body):
	if _is_attacking == true:
		body._take_damage(1)

#funcion que maneja el funcionamiento del ataque
func _attack():
	_update_attack_position()
	_is_attacking = true
	_attack_area.monitoring = true
	
	await  get_tree().create_timer(0.15).timeout
	
	_attack_area.monitoring = false
	_is_attacking = false


#funcion que define en que dirección sucederá el ataque
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

#para que mire en la dirección correcta 
func _calculate_flip_h():
	if !is_zero_approx(direction.x):
		_animated_sprite.flip_h = direction.x < 0
		
#para que la animación funcione en cada frame
func _animation_run():
	if _animated_sprite == null:
		return
		
	if _is_attacking == true:
		var attack_animation = _last_movement_animation.replace("run_", "attack_")
		_animated_sprite.play(attack_animation)
	else:

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

func receive_joystick(j: Area2D) -> void:
	joystick = j

#Activar dialogo
func _on_dialogue_started(_dialogue):
	GameManager.is_dialogue_active = true

#Terminar dialogo
func _on_dialogue_ended(_dialogue):
	await get_tree().create_timer(0.2).timeout
	GameManager.is_dialogue_active = false

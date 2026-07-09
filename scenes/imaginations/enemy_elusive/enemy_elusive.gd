extends CharacterBody2D

# Stats
@export var health := 3
@export var is_dead := false

# Constantes de velocidad en base a la escala
const PPM = 32
const SPRITE_SCALE = 1

# Variables para direcci¨®n y velocidad
var direction : Vector2
@export var normal_speed = 3.0 * PPM * SPRITE_SCALE
@export var flee_speed = 6.0 * PPM * SPRITE_SCALE # 03Mucho m¨¢s r¨¢pido al huir!

# L¨ªmite de movimiento en pixeles
@export var left_limit := 600
@export var right_limit := 1150

# Referencia al jugador y ¨¢rea de detecci¨®n
@export var detection_area : Area2D
var player_ref = null

# Variables y constantes para el knockback
var _knockback_velocity := Vector2.ZERO
const _KNOCKBACK_FORCE := 450.0
const _KNOCKBACK_DECAY := 1000.0

@export var animated_sprite : AnimatedSprite2D

func _ready() -> void:
	platform_wall_layers = 0
	platform_floor_layers = 0
	# Mover el personaje apenas iniciar (Patrulla inicial)
	direction = Vector2(1, 0)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not player_ref:
		for body in detection_area.get_overlapping_bodies():
			if body.is_in_group("player"):
				player_ref = body
				break
		
	var current_speed = normal_speed
	
	# Comprobar si el jugador est¨¢ cerca y activo
	if player_ref != null and not GameManager.is_dead and not GameManager.is_dialogue_active:
		# Calcular direcci¨®n opuesta al jugador (Huir)
		var flee_direction = (global_position - player_ref.global_position).normalized()
		
		# Mantener el movimiento en el eje X (horizontal) seg¨²n tus l¨ªmites
		direction = flee_direction
		current_speed = flee_speed
		# Si llega a los l¨ªmites mientras huye, se queda "atrapado" o intenta no avanzar m¨¢s
	else:
		# L¨®gica de patrulla original si no hay jugador cerca
		if position.x < left_limit:
			direction = Vector2(1, 0)
		elif position.x > right_limit:
			direction = Vector2(-1, 0)
	
	# Reducir gradualmente el knockback hasta 0 usando "delta"
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, _KNOCKBACK_DECAY * delta)
	
	velocity = direction * current_speed + _knockback_velocity
	
	move_and_slide()
	_calculate_flip_h()
	_animation_run()

# --- DETECCI07N DEL JUGADOR ---
# Conecta las se09ales de tu Area2D (ahora enfocada en detecci¨®n mas amplia) aqu¨ª:
func _on_detection_area_entered(area):
	if area.owner != null and area.owner.is_in_group("player"):
		player_ref = area.owner

func _on_detection_area_exited(area):
	if area.owner == player_ref:
		# Un peque09o delay antes de perder el rastro por si sale y entra r¨¢pido
		await get_tree().create_timer(0.3).timeout
		if not is_inside_tree():
			return
		player_ref = null

# --- RECIBIR DA05O Y MUERTE ---
func _take_damage(amount: int, source_position: Vector2):
	health -= amount
	
	# El knockback original se mantiene para darle feedback al golpe
	var knockback_direction = (global_position - source_position).normalized()
	_knockback_velocity = knockback_direction * _KNOCKBACK_FORCE
	
	if health <= 0:
		_die()

func _die():
	is_dead = true
	animated_sprite.stop()
	velocity = Vector2.ZERO
	await get_tree().create_timer(1).timeout
	if not is_inside_tree():
		return
	queue_free()
	
# --- ANIMACIONES ---
func _animation_run():
	if is_dead:
		return
		
	if velocity != Vector2.ZERO:
		# Si su velocidad actual es la de huida, podr¨ªas usar una animaci¨®n de "run" si la tienes
		if velocity.length() > normal_speed:
			if animated_sprite.sprite_frames.has_animation("run"):
				animated_sprite.play("run")
				return
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

func _calculate_flip_h():
	if is_dead:
		return
	if !is_zero_approx(direction.x):
		animated_sprite.flip_h = direction.x < 0

extends StaticBody2D

var health = 2
var is_dead = false

func _take_damage(amount: int, _source_position: Vector2):
	#print("recibí daño: ", amount)
	health -= amount
	#print("Vida actual: ", health)
	if health <= 0:
		_die()

func  _die():
	is_dead = true
	#print("ME MORÍ")
	await  get_tree().create_timer(1).timeout
	if not is_inside_tree():
		return
	queue_free()

extends CanvasLayer

@export var health_bar : TextureProgressBar

func update_health(current: int, max_hp: int):
	health_bar.max_value = max_hp
	health_bar.value = current

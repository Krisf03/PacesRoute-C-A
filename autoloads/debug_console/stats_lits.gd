extends VBoxContainer

func _on_vida_actual_changed(value: float) -> void:
	DebugConsole.execute("set_health %d" % int(value))

func _on_vida_máxima_changed(value: float) -> void:
	DebugConsole.execute("set_max_hp %d" % int(value))

func _on_daño_de_ataque_changed(value: float) -> void:
	DebugConsole.execute("set_damage %d" % int(value))

func _on_velocidad_changed(value: float) -> void:
	DebugConsole.execute("set_speed %.0f" % value)

func _on_hp_enemigos_changed(value: float) -> void:
	DebugConsole.execute("set_enemy_hp %d" % int(value))

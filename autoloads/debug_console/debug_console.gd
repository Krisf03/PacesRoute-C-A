# ================================================================
# DEBUG CONSOLE — PacesRoute
# ================================================================
# Activar / Desactivar: F3
# Teclas en el input de comando:
#   ↑ / ↓   → navegar historial
#   Tab      → autocompletar
#   Enter    → ejecutar
# ================================================================

extends CanvasLayer

# --- Señales ---
signal command_executed(cmd: String)

# --- Enums ---
enum LogLevel { INFO, SUCCESS, WARNING, ERROR }

# --- Constantes ---
const MAX_HISTORY    := 50
const TOGGLE_ACTION  := "debug_toggle"

# --- Estado interno ---
var _visible_state   := false
var _commands        : Dictionary = {}
var _history         : Array[String] = []
var _history_idx     := -1
var _god_mode        := false
var _player_ref      : CharacterBody2D = null

# --- Referencias a nodos UI (se asignan vía @onready en la escena) ---
@onready var _root_panel    : PanelContainer = $RootPanel
@warning_ignore("unused_private_class_variable")
@onready var _tab_container : TabContainer   = $RootPanel/Margin/VBox/Tabs
@onready var _cmd_input     : LineEdit       = $RootPanel/Margin/VBox/InputRow/Input
@onready var _log_output    : RichTextLabel  = $RootPanel/Margin/VBox/Tabs/Console/Log

# Nodos del tab Estado (se actualizan dinámicamente)
@onready var _status_label  : RichTextLabel  = $RootPanel/Margin/VBox/Tabs/Estado/StatusLabel

# ================================================================
# CICLO DE VIDA
# ================================================================

func _ready() -> void:
	layer = 128                   # Por encima de todo
	follow_viewport_enabled = false # Render en resolución de ventana, no viewport
	_root_panel.visible = false
	_register_all_commands()

func _input(event: InputEvent) -> void:
	# La consola solo existe en debug builds
	if not OS.is_debug_build():
		return
	
	if event is InputEventMouseMotion:
		return
	
	if event.is_action_pressed(TOGGLE_ACTION):
		_toggle_console()
		get_viewport().set_input_as_handled()
		return
	
	# Navegación de historial cuando el input está activo
	if _visible_state and _cmd_input.has_focus() \
		and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:   _navigate_history(-1); get_viewport().set_input_as_handled()
			KEY_DOWN: _navigate_history(1);  get_viewport().set_input_as_handled()
			KEY_TAB:  _autocomplete();       get_viewport().set_input_as_handled()

# ================================================================
# TOGGLE
# ================================================================

func _toggle_console() -> void:
	_visible_state = !_visible_state
	_root_panel.visible = _visible_state
	
	if _visible_state:
		_refresh_player_ref()
		_refresh_status_tab()
		_cmd_input.grab_focus()
		_log_info("Debug Console activa. Escribe 'help' para ver los comandos.")
	else:
		# Devolver el foco al juego
		_cmd_input.release_focus()

# ================================================================
# REGISTRO DE COMANDOS
# ================================================================

## Registra un nuevo comando en la consola.
## [br]name: nombre del comando (sin espacios, en minúsculas)
## [br]desc: descripción corta que aparece en 'help'
## [br]args: lista de nombres de argumentos esperados, ej: ["<amount>", "<x>"]
## [br]callback: Callable que recibe Array con los argumentos como strings
##
## Ejemplo de uso desde otro script:
## [codeblock]
## DebugConsole.register_command(
##     "my_cmd", "Descripción", ["<valor>"],
##     func(args): print(args[0])
## )
## [/codeblock]
func register_command(_name: String, desc: String, args: Array[String], callback: Callable) -> void:
	_commands[_name.to_lower()] = {
		"description": desc,
		"args": args,
		"callback": callback
	}

func _register_all_commands() -> void:
	# ── Jugador ──────────────────────────────────────────
	register_command("heal",
		"Restaura la vida del jugador al máximo",
		[],
		func(_a): _cmd_heal())
	
	register_command("kill",
		"Mata al jugador",
		[],
		func(_a): _cmd_kill())
	
	register_command("revive",
		"Revive al jugador con vida completa",
		[],
		func(_a): _cmd_revive())
	
	register_command("god",
		"Toggle modo dios — el jugador no recibe daño",
		[],
		func(_a): _cmd_god())
	
	register_command("set_health",
		"Establece la vida actual del jugador",
		["<amount>"],
		func(a): _cmd_set_health(a))
	
	register_command("set_max_hp",
		"Establece la vida máxima del jugador",
		["<amount>"],
		func(a): _cmd_set_max_hp(a))
	
	register_command("set_damage",
		"Establece el daño de ataque del jugador",
		["<amount>"],
		func(a): _cmd_set_damage(a))
	
	register_command("set_speed",
		"Establece la velocidad del jugador (default: 192)",
		["<amount>"],
		func(a): _cmd_set_speed(a))
	
	register_command("tp",
		"Teletransporta al jugador a las coordenadas dadas",
		["<x>", "<y>"],
		func(a): _cmd_tp(a))
	
	# ── Enemigos ─────────────────────────────────────────
	register_command("kill_enemies",
		"Mata todos los enemigos activos en la escena",
		[],
		func(_a): _cmd_kill_enemies())
	
	register_command("set_enemy_hp",
		"Establece la vida de todos los enemigos",
		["<amount>"],
		func(a): _cmd_set_enemy_hp(a))
	
	register_command("freeze_enemies",
		"Toggle: pausa / reanuda el movimiento de todos los enemigos",
		[],
		func(_a): _cmd_freeze_enemies())
	
	# ── Estado del juego ─────────────────────────────────
	register_command("met_enemy",
		"Toggle: ha_conocido_al_enemigo01 (has_met_enemy01)",
		[],
		func(_a): _cmd_met_enemy())
	
	register_command("end_dialogue",
		"Fuerza el fin del diálogo activo",
		[],
		func(_a): _cmd_end_dialogue())
	
	register_command("reload",
		"Recarga la escena actual",
		[],
		func(_a): _cmd_reload())
	
	register_command("scene",
		"Cambia a una escena por nombre. Ej: scene test_room",
		["<name>"],
		func(a): _cmd_scene(a))
	
	register_command("translate",
		"Cambia el idioma del juego. Ej: translate en",
		["<languaje>"],
		func(a): _cmd_translate(a))
	
	# ── Consola ───────────────────────────────────────────
	register_command("help",
		"Muestra todos los comandos disponibles",
		[],
		func(_a): _cmd_help())
	
	register_command("clear",
		"Limpia el log de la consola",
		[],
		func(_a): _cmd_clear())

# ================================================================
# EJECUCIÓN
# ================================================================

## Ejecuta un string como si fuera un comando escrito en la consola.
## Puede llamarse desde cualquier otro script:
## [codeblock]
## DebugConsole.execute("heal")
## DebugConsole.execute("set_health 3")
## [/codeblock]
func execute(raw: String) -> void:
	raw = raw.strip_edges()
	if raw.is_empty():
		return
	
	_add_to_history(raw)
	_log_info("> " + raw)
	
	var parts  := Array(raw.split(" ", false))
	var name_f_exe   = parts[0].to_lower()
	var args   := parts.slice(1)
	
	if not _commands.has(name_f_exe):
		_log_error("Comando desconocido: '%s'. Escribe 'help'." % name_f_exe)
		return
	
	var data           : Dictionary    = _commands[name_f_exe]
	var expected_args  : int           = data["args"].size()
	
	if args.size() < expected_args:
		_log_warning("Uso: %s %s" % [name_f_exe, " ".join(data["args"])])
		return
	
	data["callback"].call(args)
	emit_signal("command_executed", name_f_exe)

# ================================================================
# IMPLEMENTACIONES DE COMANDOS
# ================================================================

# ── Jugador ──────────────────────────────────────────────────────

func _cmd_heal() -> void:
	GameManager.health = GameManager.max_health
	GameManager.health_changed.emit(GameManager.health, GameManager.max_health)
	if GameManager.is_dead:
		_cmd_revive()
		return
	_log_success("Jugador curado → %d/%d HP" % [GameManager.health, GameManager.max_health])
	_refresh_status_tab()

func _cmd_kill() -> void:
	_refresh_player_ref()
	if _player_ref == null:
		_log_error("Jugador no encontrado en escena.")
		return
	_player_ref._die()
	_log_success("Jugador eliminado.")
	_refresh_status_tab()

func _cmd_revive() -> void:
	_refresh_player_ref()
	if _player_ref == null:
		_log_error("Jugador no encontrado en escena.")
		return
	_player_ref.revive()
	_log_success("Jugador revivido → %d/%d HP" % [GameManager.health, GameManager.max_health])
	_refresh_status_tab()

func _cmd_god() -> void:
	_god_mode = !_god_mode
	var estado := "ACTIVADO ✦" if _god_mode else "DESACTIVADO"
	_log_success("God Mode: %s" % estado)
	_refresh_status_tab()

func _cmd_set_health(args: Array) -> void:
	var amount := int(args[0])
	amount = clamp(amount, 0, GameManager.max_health)
	GameManager.health = amount
	if amount <= 0 and not GameManager.is_dead:
		_cmd_kill()
	elif amount > 0 and GameManager.is_dead:
		_cmd_revive()
	else:
		_log_success("Vida → %d/%d" % [GameManager.health, GameManager.max_health])
	_refresh_status_tab()

func _cmd_set_max_hp(args: Array) -> void:
	var amount := int(args[0])
	amount = max(1, amount)
	GameManager.max_health = amount
	GameManager.health = min(GameManager.health, amount)
	_log_success("Vida máxima → %d" % amount)
	_refresh_status_tab()

func _cmd_set_damage(args: Array) -> void:
	var amount := int(args[0])
	GameManager.attack_damage = max(0, amount)
	_log_success("Daño de ataque → %d" % GameManager.attack_damage)
	_refresh_status_tab()

func _cmd_set_speed(args: Array) -> void:
	_refresh_player_ref()
	if _player_ref == null:
		_log_error("Jugador no encontrado.")
		return
	_player_ref.speed = max(0.0, float(args[0]))
	_log_success("Velocidad → %.0f" % _player_ref.speed)

func _cmd_tp(args: Array) -> void:
	_refresh_player_ref()
	if _player_ref == null:
		_log_error("Jugador no encontrado.")
		return
	var target := Vector2(float(args[0]), float(args[1]))
	_player_ref.global_position = target
	_log_success("Teletransportado → (%.0f, %.0f)" % [target.x, target.y])

# ── Enemigos ─────────────────────────────────────────────────────

func _cmd_kill_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("Enemies")
	if enemies.is_empty():
		_log_warning("No hay enemigos en escena.")
		return
	for enemy in enemies:
		if enemy.has_method("_die") and not enemy.is_dead:
			enemy._die()
	_log_success("%d enemigos eliminados." % enemies.size())
	_refresh_status_tab()

func _cmd_set_enemy_hp(args: Array) -> void:
	var amount = max(1, int(args[0]))
	var enemies := get_tree().get_nodes_in_group("Enemies")
	if enemies.is_empty():
		_log_warning("No hay enemigos en escena.")
		return
	for enemy in enemies:
		if not enemy.is_dead:
			enemy.health = amount
	_log_success("Vida de %d enemigos → %d" % [enemies.size(), amount])

func _cmd_freeze_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("Enemies")
	if enemies.is_empty():
		_log_warning("No hay enemigos en escena.")
		return
	for enemy in enemies:
		if not enemy.is_dead:
			enemy.set_physics_process(!enemy.is_physics_processing())
	var estado := "PAUSADOS" if not enemies[0].is_physics_processing() else "REANUDADOS"
	_log_success("Enemigos %s." % estado)

# ── Estado del juego ─────────────────────────────────────────────

func _cmd_met_enemy() -> void:
	GameManager.has_met_enemy01 = !GameManager.has_met_enemy01
	_log_success("has_met_enemy01 → %s" % GameManager.has_met_enemy01)
	_refresh_status_tab()

func _cmd_end_dialogue() -> void:
	if not GameManager.is_dialogue_active:
		_log_warning("No hay diálogo activo en este momento.")
		return
	GameManager.is_dialogue_active = false
	_log_success("Diálogo forzado a terminar.")
	_refresh_status_tab()

func _cmd_reload() -> void:
	var main = get_tree().get_nodes_in_group("main_scene")[0]
	_log_info("Recargando escena...")
	await get_tree().process_frame
	if main.current_room_path:
		Transitioner.transition_to_scene(main.current_room_path)
	else:
		get_tree().reload_current_scene()

func _cmd_scene(args: Array) -> void:
	# Mapa de alias → ruta real
	var scene_map := {
		"test" : "res://scenes/rooms/test_room/test_room.tscn",
		"zones" : "res://scenes/rooms/test_game_zones/test_game_zones.tscn",
		"start" : "res://scenes/rooms/airlock_start_point/airlock_start_point.tscn",
		"hall" : "res://scenes/rooms/start_hallway/start_hallway.tscn"
	}
	var key = args[0].to_lower()
	if scene_map.has(key):
		_log_info("Cambiando a escena '%s'..." % key)
		await get_tree().process_frame
		Transitioner.transition_to_scene(scene_map[key])
	else:
		_log_warning("Escena desconocida. Opciones: %s" % ", ".join(scene_map.keys()))

func _cmd_translate(args: Array) -> void:
	var language = args[0]
	if language == "es":
		_log_success("Cambiando idioma del juego a español")
	elif language == "en":
		_log_success("Cambiando idioma del juego a inglés")
	else:
		_log_warning("El idioma seleccionado no existe. Opciones: es, en")
	TranslationServer.set_locale(str(language))

# ── Consola ───────────────────────────────────────────────────────

func _cmd_help() -> void:
	_log_info("\n═══════════ COMANDOS DISPONIBLES ═══════════")
	var sorted_keys := _commands.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		var data       : Dictionary = _commands[key]
		var args_str   : String     = " ".join(data["args"])
		var full_cmd   : String     = "%-25s" % (key + " " + args_str)
		_log_info("  [color=#88bbff]%s[/color]  %s" % [full_cmd, data["description"]])
	_log_info("════════════════════════════════════════════\n")

func _cmd_clear() -> void:
	_log_output.clear()

# ================================================================
# SISTEMA DE LOG (público — úsalo desde cualquier parte del juego)
# ================================================================

## Añade un mensaje al log de la consola.
## También puedes llamarlo desde cualquier script:
## [codeblock]
## DebugConsole.log_info("Misión completada")
## DebugConsole.log_error("No se pudo cargar el recurso")
## [/codeblock]
func log_info(text: String)    -> void: _log_info(text)
func log_success(text: String) -> void: _log_success(text)
func log_warning(text: String) -> void: _log_warning(text)
func log_error(text: String)   -> void: _log_error(text)

func _log_info(text: String) -> void:
	_append_to_log(text, "dddddd")

func _log_success(text: String) -> void:
	_append_to_log("✓ " + text, "55ee88")

func _log_warning(text: String) -> void:
	_append_to_log("⚠ " + text, "ffcc44")

func _log_error(text: String) -> void:
	_append_to_log("✗ " + text, "ff5555")

func _append_to_log(text: String, hex_color: String) -> void:
	if not is_node_ready() or _log_output == null:
		return
	_log_output.append_text("[color=#%s]%s[/color]\n" % [hex_color, text])
	# Scroll automático al final
	await get_tree().process_frame
	var sb := _log_output.get_v_scroll_bar()
	if sb:
		sb.value = sb.max_value

# ================================================================
# HISTORIAL
# ================================================================

func _add_to_history(cmd: String) -> void:
	if _history.is_empty() or _history.back() != cmd:
		_history.append(cmd)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	_history_idx = _history.size()

func _navigate_history(direction: int) -> void:
	_history_idx = clamp(_history_idx + direction, 0, _history.size())
	if _history_idx < _history.size():
		_cmd_input.text = _history[_history_idx]
		_cmd_input.caret_column = _cmd_input.text.length()
	else:
		_cmd_input.text = ""

func _autocomplete() -> void:
	var partial := _cmd_input.text.strip_edges().to_lower()
	if partial.is_empty():
		return
	var matches := _commands.keys().filter(func(k): return k.begins_with(partial))
	if matches.size() == 1:
		_cmd_input.text = matches[0] + " "
		_cmd_input.caret_column = _cmd_input.text.length()
	elif matches.size() > 1:
		matches.sort()
		_log_info("Sugerencias: " + ", ".join(matches))

# ================================================================
# GETTER PÚBLICO — God Mode
# ================================================================

## Retorna true si el modo dios está activo.
## Llamar esto en character.gd → _take_damage() para ignorar el daño.
func is_god_mode() -> bool:
	return _god_mode

# ================================================================
# REFRESH DEL TAB ESTADO
# ================================================================

func _refresh_player_ref() -> void:
	var players := get_tree().get_nodes_in_group("player")
	_player_ref = players[0] if players.size() > 0 else null

func _refresh_status_tab() -> void:
	if not is_node_ready() or _status_label == null:
		return
	
	var enemies      := get_tree().get_nodes_in_group("Enemies")
	var alive_enemies := enemies.filter(func(e): return not e.is_dead).size()
	var player_speed : float = _player_ref.speed if _player_ref else -1
	
	var text := ""
	text += "[b][color=#aaddff]══ JUGADOR ══[/color][/b]\n"
	text += "  Vida:          [color=#ff7777]%d[/color] / [color=#dddddd]%d[/color]\n" % [GameManager.health, GameManager.max_health]
	text += "  Daño:          [color=#ffaa44]%d[/color]\n" % GameManager.attack_damage
	text += "  Velocidad:     [color=#aaffaa]%.0f[/color]\n" % player_speed
	text += "  Muerto:        [color=#ff5555]%s[/color]\n" % GameManager.is_dead
	text += "  God Mode:      [color=%s]%s[/color]\n" % ["#55ee88" if _god_mode else "#888888", _god_mode]
	text += "\n"
	text += "[b][color=#aaddff]══ JUEGO ══[/color][/b]\n"
	text += "  Diálogo activo:   [color=#ffcc44]%s[/color]\n" % GameManager.is_dialogue_active
	text += "  has_met_enemy01:  [color=#ffcc44]%s[/color]\n" % GameManager.has_met_enemy01
	text += "  Escena actual:    [color=#cccccc]%s[/color]\n" % get_tree().current_scene.name
	text += "\n"
	text += "[b][color=#aaddff]══ ENEMIGOS ══[/color][/b]\n"
	text += "  Total en escena:  [color=#ff7777]%d[/color]\n" % enemies.size()
	text += "  Vivos:            [color=#ff9966]%d[/color]\n" % alive_enemies
	
	_status_label.clear()
	_status_label.append_text(text)

# ================================================================
# SEÑAL DEL BOTÓN DE INPUT
# ================================================================

## Conectar este método a la señal text_submitted del LineEdit en la escena.
func _on_input_submitted(text: String) -> void:
	execute(text)
	_cmd_input.clear()
	_cmd_input.grab_focus()

func _on_run_button_pressed() -> void:
	execute(_cmd_input.text)
	_cmd_input.clear()
	_cmd_input.grab_focus()

func _on_action_button_pressed(_command: String) -> void:
	execute(_command)

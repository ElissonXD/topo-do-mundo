# cursor.gd
class_name CharacterCursor
extends Control   # OU TextureRect (se quiser usar como imagem)

enum Mode { CHAR, SKILL }

var player_id: int = 1
var grid: GridContainer          # grid de personagens
var skill_grid: GridContainer    # grid de skills
var columns: int = 4
var rows: int = 3
var skill_columns: int = 4
var skill_rows: int = 1

var current_grid_pos: Vector2i = Vector2i.ZERO
var current_skill_pos: Vector2i = Vector2i.ZERO
var mode: Mode = Mode.CHAR
var current_costume_index: int = 0
var selected_character: int = 0
var selected_skill: int = 0

signal cursor_moved(player_index: int, character_index: int)
signal skill_moved(player_index: int, skill_index: int)
signal mode_changed(player_index: int, new_mode: int)
signal confirm_pressed(player_index: int)
signal cancel_pressed(player_index: int)
signal costume_changed(player_index: int, costume_index: int)

func _process(delta):
	var left_action = "left_%d" % player_id
	var right_action = "right_%d" % player_id
	var up_action = "up_%d" % player_id
	var down_action = "down_%d" % player_id
	var toggle_action = "toggle_mode_%d" % player_id
	var accept_action = "ui_accept"
	var cancel_action = "ui_cancel"

	# Alternar modo
	if Input.is_action_just_pressed(toggle_action):
		set_mode(Mode.SKILL if mode == Mode.CHAR else Mode.CHAR)

	# Movimento
	var direction = Vector2i.ZERO
	if Input.is_action_just_pressed(left_action):
		direction = Vector2i(-1, 0)
	elif Input.is_action_just_pressed(right_action):
		direction = Vector2i(1, 0)
	elif Input.is_action_just_pressed(up_action):
		direction = Vector2i(0, -1)
	elif Input.is_action_just_pressed(down_action):
		direction = Vector2i(0, 1)

	if direction != Vector2i.ZERO:
		move_cursor(direction)

	# Confirmação / Cancelamento
	if Input.is_action_just_pressed(accept_action):
		emit_signal("confirm_pressed", player_id - 1)
	if Input.is_action_just_pressed(cancel_action):
		emit_signal("cancel_pressed", player_id - 1)

	# Troca de cor (pode usar use_ability_N ou jump_N)
	if Input.is_action_just_pressed("use_ability_%d" % player_id):
		current_costume_index += 1
		emit_signal("costume_changed", player_id - 1, current_costume_index)
	elif Input.is_action_just_pressed("jump_%d" % player_id):
		current_costume_index -= 1
		emit_signal("costume_changed", player_id - 1, current_costume_index)

func set_mode(new_mode: Mode):
	mode = new_mode
	update_cursor_position()
	emit_signal("mode_changed", player_id - 1, mode)

func move_cursor(direction: Vector2i):
	if mode == Mode.CHAR:
		var new_pos = current_grid_pos + direction
		if new_pos.x < 0 or new_pos.x >= columns or new_pos.y < 0 or new_pos.y >= rows:
			return
		current_grid_pos = new_pos
		selected_character = new_pos.y * columns + new_pos.x
		emit_signal("cursor_moved", player_id - 1, selected_character)
	else:
		var new_pos = current_skill_pos + direction
		if new_pos.x < 0 or new_pos.x >= skill_columns or new_pos.y < 0 or new_pos.y >= skill_rows:
			return
		current_skill_pos = new_pos
		selected_skill = new_pos.y * skill_columns + new_pos.x
		emit_signal("skill_moved", player_id - 1, selected_skill)
	update_cursor_position()

func update_cursor_position():
	if mode == Mode.CHAR and grid:
		var child_index = current_grid_pos.y * columns + current_grid_pos.x
		if child_index < grid.get_child_count():
			var target = grid.get_child(child_index)
			global_position = target.global_position
	elif mode == Mode.SKILL and skill_grid:
		var child_index = current_skill_pos.y * skill_columns + current_skill_pos.x
		if child_index < skill_grid.get_child_count():
			var target = skill_grid.get_child(child_index)
			global_position = target.global_position

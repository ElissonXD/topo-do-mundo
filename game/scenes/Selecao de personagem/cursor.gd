class_name CharacterCursor
extends TextureRect

signal cursor_moved(character_index)
signal costume_changed(costume_index)
signal confirm_pressed
signal cancel_pressed

@export var player_id: int = 1
@export var grid: GridContainer
@export var columns: int = 4
@export var rows: int = 3
@export var costumes_per_character: int = 8  # número de paletas

var current_grid_pos: Vector2i = Vector2i.ZERO
var selected_character: int = 0
var current_costume_index: int = 0
var is_locked: bool = false

func _ready():
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	update_cursor_position()

func _process(delta):
	if is_locked:
		return
	var prefix = "_%d" % player_id
	if Input.is_action_just_pressed("left" + prefix):
		move_cursor(Vector2i.LEFT)
	elif Input.is_action_just_pressed("right" + prefix):
		move_cursor(Vector2i.RIGHT)
	elif Input.is_action_just_pressed("up" + prefix):
		move_cursor(Vector2i.UP)
	elif Input.is_action_just_pressed("down" + prefix):
		move_cursor(Vector2i.DOWN)
	elif Input.is_action_just_pressed("costume_next" + prefix):
		change_costume(1)
	elif Input.is_action_just_pressed("costume_prev" + prefix):
		change_costume(-1)
	elif Input.is_action_just_pressed("accept" + prefix):
		is_locked = true
		emit_signal("confirm_pressed" + prefix)
	elif Input.is_action_just_pressed("cancel" + prefix):
		is_locked = false
		emit_signal("cancel_pressed" + prefix)

func move_cursor(direction: Vector2i):
	var new_pos = current_grid_pos + direction
	new_pos.x = clamp(new_pos.x, 0, columns - 1)
	new_pos.y = clamp(new_pos.y, 0, rows - 1)
	if new_pos != current_grid_pos:
		current_grid_pos = new_pos
		update_cursor_position()

func update_cursor_position():
	var index = current_grid_pos.y * columns + current_grid_pos.x
	if index < grid.get_child_count():
		var target = grid.get_child(index)
		global_position = target.global_position
		selected_character = index
		emit_signal("cursor_moved", selected_character)

func change_costume(direction: int):
	current_costume_index = wrapi(current_costume_index + direction, 0, costumes_per_character)
	emit_signal("costume_changed", current_costume_index)
	# Aplicar mudança de cor no retrato selecionado
	var portrait = grid.get_child(selected_character) as TextureRect
	if portrait and portrait.material is ShaderMaterial:
		portrait.material.set_shader_parameter("hue_shift", float(current_costume_index) / costumes_per_character)

# cursor.gd
extends Sprite2D

@export var grid: GridContainer
@export var columns: int = 4
@export var rows: int = 3

var current_grid_pos: Vector2i = Vector2i.ZERO
var selected_character: int = 0

func _ready():
	update_cursor_position()

func _process(delta):
	if Input.is_action_just_pressed("ui_left"):
		move_cursor(Vector2i.LEFT)
	elif Input.is_action_just_pressed("ui_right"):
		move_cursor(Vector2i.RIGHT)
	elif Input.is_action_just_pressed("ui_up"):
		move_cursor(Vector2i.UP)
	elif Input.is_action_just_pressed("ui_down"):
		move_cursor(Vector2i.DOWN)

func move_cursor(direction: Vector2i):
	var new_pos = current_grid_pos + direction
	new_pos.x = clamp(new_pos.x, 0, columns - 1)
	new_pos.y = clamp(new_pos.y, 0, rows - 1)
	
	if new_pos != current_grid_pos:
		current_grid_pos = new_pos
		update_cursor_position()

func update_cursor_position():
	# Encontra o nó filho na posição correspondente
	var index = current_grid_pos.y * columns + current_grid_pos.x
	if index < grid.get_child_count():
		var target = grid.get_child(index)
		global_position = target.global_position
		selected_character = index
		# Opcional: atualizar painel de informações
		emit_signal("cursor_moved", selected_character)

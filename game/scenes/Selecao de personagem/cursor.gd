# cursor.gd
class_name CharacterCursor
extends Control

var player_id: int = 1
var grid: GridContainer
var columns: int = 4
var rows: int = 3
var current_grid_pos: Vector2i = Vector2i.ZERO
var current_costume_index: int = 0
var selected_character: int = 0

signal cursor_moved(player_index: int, character_index: int)
signal confirm_pressed(player_index: int)
signal cancel_pressed(player_index: int)
signal costume_changed(player_index: int, costume_index: int)

func _process(delta):
	# Mapeia as ações de acordo com o player_id
	var left_action = "left_%d" % player_id
	var right_action = "right_%d" % player_id
	var up_action = "up_%d" % player_id
	var down_action = "down_%d" % player_id
	var jump_action = "jump_%d" % player_id
	# Para confirmação e cancelamento, você pode usar ui_accept/ui_cancel
	# ou criar ações específicas como "use_ability_1"
	var accept_action = "ui_accept"  # ou "use_ability_%d" % player_id
	var cancel_action = "ui_cancel"  # ou "jump_%d" % player_id

	# Movimento
	if Input.is_action_just_pressed(left_action):
		move_cursor(Vector2i(-1, 0))
	elif Input.is_action_just_pressed(right_action):
		move_cursor(Vector2i(1, 0))
	elif Input.is_action_just_pressed(up_action):
		move_cursor(Vector2i(0, -1))
	elif Input.is_action_just_pressed(down_action):
		move_cursor(Vector2i(0, 1))

	# Confirmação
	if Input.is_action_just_pressed(accept_action):
		emit_signal("confirm_pressed", player_id - 1)
	
	# Cancelamento
	if Input.is_action_just_pressed(cancel_action):
		emit_signal("cancel_pressed", player_id - 1)

	# Troca de cor (exemplo: use "use_ability" para próximo, "jump" para anterior)
	if Input.is_action_just_pressed("use_ability_%d" % player_id):
		current_costume_index += 1
		emit_signal("costume_changed", player_id - 1, current_costume_index)
	elif Input.is_action_just_pressed("jump_%d" % player_id):
		current_costume_index -= 1
		emit_signal("costume_changed", player_id - 1, current_costume_index)

func move_cursor(direction: Vector2i):
	var new_pos = current_grid_pos + direction
	# Verifica limites
	if new_pos.x < 0 or new_pos.x >= columns or new_pos.y < 0 or new_pos.y >= rows:
		return
	
	# Verifica se o personagem está desbloqueado (opcional)
	var index = new_pos.y * columns + new_pos.x
	# Aqui você precisaria ter acesso à lista de personagens para verificar bloqueio
	# Se estiver bloqueado, não move
	
	current_grid_pos = new_pos
	selected_character = index
	update_cursor_position()
	emit_signal("cursor_moved", player_id - 1, selected_character)

func update_cursor_position():
	# Atualiza a posição visual do cursor baseado na grade
	# Exemplo: posiciona sobre o TextureRect correspondente
	if grid:
		var child_index = current_grid_pos.y * columns + current_grid_pos.x
		if child_index < grid.get_child_count():
			var target = grid.get_child(child_index)
			global_position = target.global_position
			# Ajuste conforme necessário (centralizar o cursor)

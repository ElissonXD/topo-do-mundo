# cursor.gd
class_name CharacterCursor
extends Control

enum Mode { CHAR, SKILL }

signal cursor_moved(player_index: int, character_index: int)
signal skill_moved(player_index: int, skill_index: int)
signal confirm_pressed(player_index: int)
signal cancel_pressed(player_index: int)
signal costume_changed(player_index: int, costume_index: int)

# Ações do Mapa de Entrada. O sufixo _1.._4 é adicionado automaticamente.
const ACT_LEFT := "left"
const ACT_RIGHT := "right"
const ACT_UP := "up"
const ACT_DOWN := "down"
const ACT_CONFIRM := "use_ability"
const ACT_CANCEL := "interact"
const ACT_COSTUME := "jump"

# Afasta um pouco os cursores de jogadores diferentes no mesmo slot
const STAGGER := Vector2(14, 14)

var player_id: int = 1               # 1..4
var grid: GridContainer              # grid de personagens
var skill_grid: GridContainer        # grid de habilidades
var costume_count: int = 6
var current_costume_index: int = 0
var mode: Mode = Mode.CHAR

# active = false ignora todo input (usado no frame em que o jogador entra)
var active := true
var two_presses = 2 # gambiarra para não selecionar automaticamente
# locked = true só aceita "cancelar" (jogador já está pronto)
var locked := false

var _char_pos := Vector2i.ZERO
var _skill_pos := Vector2i.ZERO
var _tween: Tween

func _process(_delta: float) -> void:
	if not active:
		return

	var sfx := "_%d" % player_id

	if Input.is_action_just_pressed(ACT_CANCEL + sfx):
		cancel_pressed.emit(player_id - 1)

	if locked:
		return

	var dir := Vector2i.ZERO
	if Input.is_action_just_pressed(ACT_LEFT + sfx):
		dir = Vector2i.LEFT
	elif Input.is_action_just_pressed(ACT_RIGHT + sfx):
		dir = Vector2i.RIGHT
	elif Input.is_action_just_pressed(ACT_UP + sfx):
		dir = Vector2i.UP
	elif Input.is_action_just_pressed(ACT_DOWN + sfx):
		dir = Vector2i.DOWN
	if dir != Vector2i.ZERO:
		move_cursor(dir)

	if Input.is_action_just_pressed(ACT_CONFIRM + sfx):
		two_presses -= 1
		
		if two_presses <= 0:
			confirm_pressed.emit(player_id - 1)

	if mode == Mode.CHAR and Input.is_action_just_pressed(ACT_COSTUME + sfx):
		change_costume(1)


func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	if mode == Mode.SKILL:
		_skill_pos = Vector2i.ZERO
		skill_moved.emit(player_id - 1, 0)
	update_position()


func change_costume(step: int) -> void:
	current_costume_index = posmod(current_costume_index + step, costume_count)
	costume_changed.emit(player_id - 1, current_costume_index)


func get_character_index() -> int:
	return _char_pos.y * grid.columns + _char_pos.x


func get_skill_index() -> int:
	return _skill_pos.y * skill_grid.columns + _skill_pos.x


func move_cursor(dir: Vector2i) -> void:
	var g := _current_grid()
	if g == null:
		return
	var pos := _char_pos if mode == Mode.CHAR else _skill_pos
	var new_pos := pos + dir
	var idx := new_pos.y * g.columns + new_pos.x
	if new_pos.x < 0 or new_pos.x >= g.columns or new_pos.y < 0 or idx >= g.get_child_count():
		return
	if mode == Mode.CHAR:
		_char_pos = new_pos
		cursor_moved.emit(player_id - 1, idx)
	else:
		_skill_pos = new_pos
		skill_moved.emit(player_id - 1, idx)
	update_position()


func update_position(animated := true) -> void:
	var g := _current_grid()
	if g == null:
		return
	var idx := get_character_index() if mode == Mode.CHAR else get_skill_index()
	if idx >= g.get_child_count():
		return
	var target := g.get_child(idx) as Control
	var dest := target.global_position + target.size * 0.5 - size * 0.5 + STAGGER * (player_id - 1)
	if _tween:
		_tween.kill()
	if animated:
		_tween = create_tween()
		_tween.tween_property(self, "global_position", dest, 0.08)
	else:
		global_position = dest


func _current_grid() -> GridContainer:
	return grid if mode == Mode.CHAR else skill_grid

extends Control

# labels
@export var player: Label
@export var score: Label
@export var portraits : Dictionary = {
	'fdp':load("res://assets/sprites/players/portraits/Purgatorio_portrait.png"),
	'pero': load("res://assets/sprites/players/portraits/Pero_portrait.png"),
	'dave': load("res://assets/sprites/players/portraits/Dave_portrait.png"),
	'laje': load("res://assets/sprites/players/portraits/Lajetixa_idle.png")
}
var player_int : int = 0
@export var texture_rect: TextureRect
@export var panel_container: PanelContainer

# vai enviar o index do player
func change_player(new_player : int, portrait: String) -> void:
	player.text = "Player " + str(new_player+1)
	player_int = new_player
	texture_rect.texture = portraits[portrait]

func change_color(color : Color):
	var current_style = panel_container.get_theme_stylebox("panel") as StyleBoxFlat
	var new_style = current_style.duplicate() as StyleBoxFlat
	new_style.border_color = color
	panel_container.add_theme_stylebox_override("panel", new_style)

# isso aqui vai conectar com o round logic, recebendo o array
func change_score(scores:Array[int]) -> void:
	score.text = str(scores[player_int])
	return

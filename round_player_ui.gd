extends Control

@export var portraits : Dictionary = {
	'fdp':load("res://assets/portraits/Purgatorio_portrait.png"),
	'pero': load("res://assets/portraits/Pero_portrait.png"),
	'dave': load("res://assets/portraits/Dave_portrait.png"),
	'laje': load('res://assets/portraits/Lajetixa_idle.png')
}


# Seções para mostrar
@onready var panel_container: PanelContainer = $PanelContainer

# o proprio placar
@onready var round_player: Control = $"."
@onready var texture_rect: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/playerstats/TextureRect
@onready var playername: Label = $PanelContainer/MarginContainer/VBoxContainer/playerstats/playername

# a pontuação
@onready var pontos: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/pontos
@onready var pontuaçãoplayer: Label = $PanelContainer/MarginContainer/VBoxContainer/pontos/pontuaçãoplayer

# o placar
@onready var placar: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/placar
@onready var posição: Label = $PanelContainer/MarginContainer/VBoxContainer/placar/posição
@onready var pontuaçãopos: Label = $PanelContainer/MarginContainer/VBoxContainer/placar/pontuaçãopos

# a pontuação geral
@onready var v_box_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/VBoxContainer
@onready var pontosjogo: Label = $PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/pontosjogo

func _ready() -> void:
	pass

func show_details(player : String, portrait: String) -> void:
	round_player.visible = true
	playername.text = player
	texture_rect.texture = portraits[portrait]
	var current_style = panel_container.get_theme_stylebox("panel") as StyleBoxFlat
	var new_style = current_style.duplicate() as StyleBoxFlat
	if '1' in player:
		new_style.border_color = Color.RED
	elif '2' in player:
		new_style.border_color = Color.BLUE
	elif '3' in player:
		new_style.border_color = Color.GREEN
	else:
		new_style.border_color = Color.YELLOW
	panel_container.add_theme_stylebox_override("panel", new_style)
	return

func show_points(points: int):
	pontos.visible = true
	pontuaçãoplayer.text = str(points)
	return

func show_placar(pos: int, value: int):
	placar.visible = true
	posição.text = str(pos) + 'º lugar'
	pontuaçãopos.text = '+ ' + str(value)
	if pos == 1:
		posição.add_theme_color_override("font_color", Color.GOLD)
	elif pos == 2:
		posição.add_theme_color_override("font_color", Color.SILVER)
	elif pos == 3:
		posição.add_theme_color_override("font_color", Color.FIREBRICK)
	return

func show_geral(value: int):
	v_box_container.visible = true
	pontosjogo.text = str(value)
	return
	
	

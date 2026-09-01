extends Control

# Seções para mostrar

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

func show_details(player : String) -> void:
	round_player.visible = true
	playername.text = player
	#dps mudar a textura
	return

func show_points(points: int):
	pontos.visible = true
	pontuaçãoplayer.text = str(points)
	return

func show_placar(pos: int, value: int):
	placar.visible = true
	posição.text = str(pos) + 'º lugar'
	pontuaçãopos.text = '+ ' + str(value)
	return

func show_geral(value: int):
	v_box_container.visible = true
	pontosjogo.text = str(value)
	return
	
	

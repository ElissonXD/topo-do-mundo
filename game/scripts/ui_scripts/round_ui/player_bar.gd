extends Control

# labels
@export var player: Label
@export var score: Label
@export var pts: Label
var player_int : int = 0
@export var texture_rect: TextureRect
@export var panel_container: PanelContainer
@export var x: AnimatedSprite2D
var should_update_score = true

# vai enviar o index do player
func change_player(new_player : int, texture: Texture2D) -> void:
	player.text = "Player " + str(new_player+1)
	player_int = new_player
	texture_rect.texture = texture

func change_color(color : Color):
	var current_style = panel_container.get_theme_stylebox("panel") as StyleBoxFlat
	var new_style = current_style.duplicate() as StyleBoxFlat
	new_style.border_color = color
	panel_container.add_theme_stylebox_override("panel", new_style)

# isso aqui vai conectar com o round logic, recebendo o array
func change_score(scores:Array[int]) -> void:
	if should_update_score:
		score.text = str(scores[player_int])
	return

func on_player_died() -> void:
	should_update_score = false
	x.visible = true
	x.play('x') 
	# adiiconar algo legal, por enquanto so texto
	score.text = "Eliminado"
	score.add_theme_color_override("font_color", Color.RED)
	pts.visible = false
	return

extends Control

# portraits
@export var portraits : Dictionary = {
	'fdp':load("res://assets/sprites/players/portraits/Purgatorio_portrait.png"),
	'pero': load("res://assets/sprites/players/portraits/Pero_portrait.png"),
	'dave': load("res://assets/sprites/players/portraits/Dave_portrait.png"),
	'laje': load("res://assets/sprites/players/portraits/Lajetixa_idle.png")
}

# conteudo de cada player
@onready var timervolta: Label = $timervolta

@export var timer: Timer

# primeiro
@onready var vencedor_content: VBoxContainer = $PanelContainer/MarginContainer/conteudo/vencedor_content
@onready var label_pos_1: Label = $PanelContainer/MarginContainer/conteudo/vencedor_content/label_pos_1
@onready var crown: AnimatedSprite2D = $PanelContainer/MarginContainer/conteudo/vencedor_content/Crown
@onready var texture_rect: TextureRect = $PanelContainer/MarginContainer/conteudo/vencedor_content/TextureRect
@onready var pnt_vencedor: Label = $PanelContainer/MarginContainer/conteudo/vencedor_content/pnt_vencedor
@onready var player_vencedor: Label = $PanelContainer/MarginContainer/conteudo/vencedor_content/player_vencedor

# segundo
@onready var player_2: VBoxContainer = $PanelContainer/MarginContainer/conteudo/players_content/player_2nd
@onready var label_pos_2: Label = $PanelContainer/MarginContainer/conteudo/players_content/player_2nd/label_pos_2
@onready var pnts_2: Label = $PanelContainer/MarginContainer/conteudo/players_content/player_2nd/pnts_2
@onready var nome_2: Label = $PanelContainer/MarginContainer/conteudo/players_content/player_2nd/nome_2

# terceiro
@onready var player_3: VBoxContainer = $PanelContainer/MarginContainer/conteudo/players_content/player_3rd
@onready var label_pos_3: Label = $PanelContainer/MarginContainer/conteudo/players_content/player_3rd/label_pos_3
@onready var pnts_3: Label = $PanelContainer/MarginContainer/conteudo/players_content/player_3rd/pnts_3
@onready var nome_3: Label = $PanelContainer/MarginContainer/conteudo/players_content/player_3rd/nome_3

# quarto
@onready var player_4: VBoxContainer = $PanelContainer/MarginContainer/conteudo/players_content/player_4th
@onready var label_pos_4: Label = $PanelContainer/MarginContainer/conteudo/players_content/player_4th/label_pos_4
@onready var pnts_4: Label = $PanelContainer/MarginContainer/conteudo/players_content/player_4th/pnts_4
@onready var nome_4: Label = $PanelContainer/MarginContainer/conteudo/players_content/player_4th/nome_4

# dados
var current_player : int
var players_data : Array

# estados
enum FinalResults {
	showplayers,
	showpositions,
	showfinalplayer,
	finaltimer
}

var state : FinalResults

func _ready() -> void:
	_reset_visibility()
	players_data = GameLogic.get_players()
	current_player = players_data.size()
	change_and_sort()
	go_to_show_player_state()

func _process(_delta: float) -> void:
	match state:
		FinalResults.showplayers:
			show_player_state()
		FinalResults.showpositions:
			show_position_state()
		FinalResults.showfinalplayer:
			show_final_position()
		FinalResults.finaltimer:
			final_timer_state()

# Funções de ida

func go_to_show_player_state() -> void:
	state = FinalResults.showplayers
	await get_tree().create_timer(0.5).timeout
	go_to_show_position_state()

func go_to_show_position_state() -> void:
	state = FinalResults.showpositions
	await get_tree().create_timer(1.0).timeout
	
	current_player -= 1
	if current_player > 1:
		go_to_show_player_state()
	else:
		go_to_show_final_player_state()

func go_to_show_final_player_state() -> void:
	state = FinalResults.showfinalplayer

func go_to_final_timer_state() -> void:
	state = FinalResults.finaltimer
	timervolta.visible = true
	timer.start()

# Funções de permanência

func show_player_state() -> void:
	match current_player:
		2:
			player_2.visible = true
		3:
			player_3.visible = true
		4:
			player_4.visible = true

func show_position_state() -> void:
	match current_player:
		2:
			label_pos_2.visible = true
		3:
			label_pos_3.visible = true
		4:
			label_pos_4.visible = true

func show_final_position() -> void:
	player_vencedor.visible = true
	texture_rect.visible = true
	pnt_vencedor.visible = true
	await get_tree().create_timer(1.0).timeout
	label_pos_1.visible = true
	crown.visible = true
	await get_tree().create_timer(2.0).timeout
	go_to_final_timer_state()

func final_timer_state() -> void:
	timervolta.text = "Retornando em " + str(int(timer.time_left)) + "..."
	

func _reset_visibility() -> void:
	texture_rect.visible = false
	pnt_vencedor.visible = false
	player_vencedor.visible = false
	player_2.visible = false
	player_3.visible = false
	player_4.visible = false
	label_pos_1.visible = false
	label_pos_2.visible = false
	label_pos_3.visible = false
	label_pos_4.visible = false
	crown.visible = false
	timervolta.visible = false

func change_and_sort() -> void:
	players_data.sort_custom(func(a, b): return a['score'] > b['score'])
	print(players_data)
	
	var slots = [
		{"container": vencedor_content, "label": pnt_vencedor, "nome": player_vencedor},
		{"container": player_2, "label": pnts_2, "nome": nome_2},
		{"container": player_3, "label": pnts_3, "nome": nome_3},
		{"container": player_4, "label": pnts_4, "nome":nome_4}
	]
	
	for i in range(players_data.size()):
		if i >= slots.size():
			break
			
		var data = players_data[i]
		var slot = slots[i]
		
		slot["label"].text = str(data["score"]) + "pts"
		slot['nome'].text = "Player " + str(data['id'])
		
		# Procura o TextureRect dentro do container da posição para alterar o retrato
		var portrait_node = slot["container"].get_node_or_null("TextureRect")
		if portrait_node and portraits.has(data["portrait"]):
			portrait_node.texture = portraits[data["portrait"]]
	


func _on_timer_timeout() -> void:
	GameLogic.clear_and_go_back()

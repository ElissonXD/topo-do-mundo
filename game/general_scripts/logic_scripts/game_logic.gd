extends Node

"""
game logic princiapl
- gerenciamento das trocas das telas principais:
 - menu principal
 - jogo
- do menu principal ele deve:
	- pegar os dados de cada player      
- gerenciamento do jogo em si:
  - pontuações de cada rodada
  - placar geral
  - troca de mapas
"""

@export_category("Configurações do menu inicial")
@export var current_scene : String
# genuinamente nao sei oq poderia ficar aqui

@export_category('Configurações de jogo')
@export var players_data: Array[Dictionary] = []
@export var total_players : int = 1
@export var maps : Dictionary = {
	0: "res://game/scenes/test/test_2 da camera.tscn",
	1: "res://game/scenes/test/test_2 da camera.tscn",
	2: 'res://game/scenes/test/test_2 da camera.tscn'
}
@export var current_map : int = 1

# Controle do menu

"""
Funções para controle de menu
- Guardar players selecionados
- Passar para cena principal
"""

signal update_player;

func add_player(player_model: PlayerModel, costume_index: int, control_schema: String):
	if players_data.size() < 4:
		players_data.append({
			"model": player_model,
			"costume_index": costume_index,
			"control_schema": control_schema,
			"score": 0,
			"ready": false
		})
		update_player.emit()

func set_player_ready(player_index: int, ready: bool):
	if player_index < players_data.size():
		players_data[player_index]["ready"] = ready
		update_player.emit()

func all_players_ready() -> bool:
	for p in players_data:
		if not p["ready"]:
			return false
	return players_data.size() > 0



func remove_player(id: int):
	if total_players > 1:
		players_data.remove_at(id)
		update_player.emit(players_data.size())

func change_player(id: int, player:PlayerModel):
	players_data[id]['model'] = player
	update_player.emit(total_players)

func go_to_main_game():
	if all_players_ready():
		get_tree().change_scene_to_file("res://game/scenes/main_game.tscn")
	else:
		print("Nem todos os jogadores estão prontos!")

# Controle do jogo

"""
Funções para controle do jogo
 - Pegar os dados do player
 - Incrementar pontuações gerais
 - Resetar pontuações
 - Emitir sinais das pontuações gerais
 - Controlar mudança de mapa
 
"""
func get_players():
	var active_players: Array[Dictionary] = []
	
	for data in players_data:
		var node_instance = data['model'].instantiate()
		
		node_instance.ability = data['ability']
		node_instance.control_schema = data['controls']
		
		active_players.append({
			"id": data["id"],
			"portrait": data['portrait'],
			"model": node_instance,
			"score": data["score"]
		})
		
	return active_players

func update_player_total_points(id: int, points:int):
	players_data[id]['score'] += points
	return

func go_to_next_map():
	current_map = (current_map + 1) % 3 #temporariamente circular
	var map = maps[current_map]
	get_tree().change_scene_to_file.call_deferred(map)
	return


func _ready() -> void:
	var players : Array[Dictionary]
	for x in range(4):
		var object = preload("res://game/scenes/player/fdp.tscn")
		var player = {
			"id": x+1,
			"model": object,
			"portrait": 'fdp',
			"ability": 3,
			"controls": str(x+1),
			"score": 0
		}
		players.append(player)
	
	players_data = players


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
	2: 'res://game/scenes/test/test_2 da camera.tscn',
	3: "res://game/scenes/menus/resultados_finais.tscn"
}
@export var current_map : int = 0

# Controle do menu

"""
Funções para controle de menu
- Guardar players selecionados
- Passar para cena principal
"""

signal update_player;

func add_player(id, player_model, costume_index, portrait, controls, ability = -1):
	players_data.append({
		"id": id,
		"model": player_model,
		"costume_index": costume_index,
		"portrait": portrait,
		"controls": controls,
		"ability": ability,
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
		var instance = load(data['model'])
		
		var node_instance = instance.instantiate()
		
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

#func get_players():
#	##mock temporarário
#	var players : Array[Dictionary] = []
#	for x in range(4):
#		var object = load("res://game/scenes/player/characters/fdp.tscn").instantiate()
#		object.ability = 3
#		object.vivo = true
#		object.control_schema = str(x+1)
#		var player = {
#			"id": x+1,
#			"model": object,
#			"portrait": "laje" 
#		}
#		players.append(player)
#
#	return players

func update_game_points(total_points : Array[int]):
	var player_rank: Array[int] = range(total_points.size())

	player_rank.sort_custom(func(a: int, b: int) -> bool:
		return total_points[a] > total_points[b]
	)
	
	
	
	# logica de calcular posição

# Em game_logic.gd
#func create_player_dict(player_model: PlayerModel, costume_index: int, controls: String, ability: int = 0) -> Dictionary:
	#return {
		#"model": player_model,
		#"costume_index": costume_index,   # mantido para a cor
		#"controls": controls,             # renomeado de control_schema
		#"ability": ability,               # se vier do modelo, pode ser extraído
		#"score": 0,
		#"ready": false,
		#"id": players_data.size() + 1     # ou use um ID incremental
	#}
func clear_players():
	players_data.clear()
	update_player.emit()
	

func go_to_next_map():
	current_map += 1
	var map = maps[current_map]
	get_tree().change_scene_to_file.call_deferred(map)
	get_tree().paused = false
	return


func _ready() -> void:
	var players : Array[Dictionary]
	for x in range(4):
		var object = preload("res://game/scenes/player/characters/Lajetixa.tscn")
		var player = {
			"id": x+1,
			"model": object,
			"portrait": 'laje',
			"ability": 3,
			"controls": str(x+1),
			"score": 0
		}
		players.append(player)
	
	players_data = players

func clear_and_go_back():
	players_data = []
	current_map = 0
	get_tree().change_scene_to_file.call_deferred("res://game/scenes/menus/main_menu.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

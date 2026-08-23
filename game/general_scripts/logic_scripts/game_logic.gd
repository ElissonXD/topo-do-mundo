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

# Controle do menu

"""
Funções para controle de menu
- Guardar players selecionados
- Passar para cena principal
"""

signal update_player;

func add_player(player: PlayerModel):
	if players_data.size() < 4:
		players_data.append({
			"score": 0.0,
			"model": player
		})
		update_player.emit(players_data.size())

func remove_player(id: int):
	if total_players > 1:
		players_data.remove_at(id)
		update_player.emit(players_data.size())

func change_player(id: int, player:PlayerModel):
	players_data[id]['model'] = player
	update_player.emit(total_players)

func go_to_main_game():
	get_tree().change_scene_to_file("opa") # placeholder
	return

# Controle do jogo

"""
Funções para controle do jogo
 - Pegar os dados do player
 - Incrementar pontuações gerais
 - Resetar pontuações
 - Emitir sinais das pontuações gerais
 - Controlar mudança de mapa
 
"""
# botar um mock para os players

func get_players():
	return players_data

func update_game_points(total_points : Array[int]):
	var player_rank: Array[int] = range(total_points.size())

	player_rank.sort_custom(func(a: int, b: int) -> bool:
		return total_points[a] > total_points[b]
	)
	
	
	
	# logica de calcular posição



func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

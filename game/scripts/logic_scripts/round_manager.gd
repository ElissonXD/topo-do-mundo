extends Node

# ok, importante, talvez seja legal refatorar os nós para ser exports
# ao inves de depender da cena, depois faço isso

# Configurações

@export_category('Configurações gerais')
@export var general_timer : Timer
@export var start_timer : Timer
@export var spawn_points : Array[Node]
@export var players : Array[Dictionary]
@export var players_points : Array[int] = [0,0,0,0]
@export var roundResults : Control
var crown_object : Node2D

var colors_dict : Dictionary = {
		0: Color.RED,
		1: Color.BLUE,
		2: Color.GREEN,
		3: Color.YELLOW
}

enum GameState {
	SETUP,
	PLAYING,
	GAME_OVER
}

var current_state: GameState

# Sinais

signal get_players_points(player_points : Array[int])
signal get_start_timer(timer : Timer)
signal get_game_timer(timer: Timer)
signal game_end(dados: Array) 

func _ready() -> void:
	crown_object = load("res://game/scenes/entities/crown.tscn").instantiate()
	crown_object.visible = false
	$"../Entities".add_child(crown_object)
	change_state(GameState.SETUP)

func _process(delta: float) -> void:
	match current_state:
		GameState.PLAYING:
			_process_playing_state(delta)
		GameState.GAME_OVER:
			pass
		GameState.SETUP:
			pass

# Transição de Estados
func change_state(new_state: GameState) -> void:
	current_state = new_state
	
	match current_state:
		GameState.SETUP:
			_enter_setup_state()
		GameState.PLAYING:
			_enter_playing_state()
		GameState.GAME_OVER:
			_enter_game_over_state()

func _enter_setup_state() -> void:
	get_tree().paused = true
	
	players = GameLogic.get_players()
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	spawn_points = get_tree().get_nodes_in_group('Spawn')
	
	for x in range(len(players)):
		$"../Jogadores".add_child(players[x]['model'])
		players[x]["model"].global_position = spawn_points[x].global_position
	
	start_timer.start()
	get_start_timer.emit(start_timer)

func _on_timer_2_timeout() -> void:
	change_state(GameState.PLAYING)
	create_ui_points(len(players))
	create_ui_itens((len(players)))
	$"../CanvasLayer/round_timer".visible = true
	
func _enter_playing_state() -> void:
	get_tree().paused = false
	general_timer.start()
	get_game_timer.emit(general_timer)

func _process_playing_state(delta: float) -> void:
	var menor_y: int = 9999999999 
	var player_vencedor: Dictionary = {}
	var empate: bool = false
	
	for player in players:
		if int(player['model'].global_position.y) < menor_y:
			menor_y = int(player['model'].global_position.y)
			player_vencedor = player
			empate = false
		elif int(player['model'].global_position.y) == menor_y:
			empate = true
			
	if not player_vencedor.is_empty() and not empate:
		match player_vencedor['id']:
			1:
				players_points[0] += delta * 100
			2:
				players_points[1] += delta * 100
			3:
				players_points[2] += delta * 100
			4:
				players_points[3] += delta * 100
		crown_object.visible = true
		crown_object.global_position = player_vencedor['model'].global_position
		crown_object.global_position.y -= 30
	else:
		crown_object.visible = false
			
	get_players_points.emit(players_points)

func _on_timer_timeout() -> void:
	change_state(GameState.GAME_OVER)


func _enter_game_over_state() -> void:
	get_tree().paused = true
	
	await get_tree().create_timer(1.5, true, false, true).timeout
	
	var placar = calculate_score()
	
	roundResults.go_to_score_state(placar)
	$"../CanvasLayer/players".visible = false
	$"../CanvasLayer/round_timer".visible = false
	hide_ui_points()
	game_end.emit(placar as Array)


# utils

func create_ui_points(length: int) -> void:
	var object = load("res://game/scenes/ui/round_ui/player_bar.tscn")

	for i in range(length):
		var player_portrait = players[i]['portrait']
		var player_ui_score = object.instantiate()
		player_ui_score.change_color(colors_dict[i])
		$"../CanvasLayer/players".add_child(player_ui_score)
		player_ui_score.change_player(i, player_portrait)
		get_players_points.connect(player_ui_score.change_score)

func create_ui_itens(length:int) -> void:
	var object = load("res://game/scenes/ui/round_ui/item_ui.tscn")

	for i in range(length):
		var player_portrait = players[i]['portrait']
		var player_ui_item = object.instantiate()
		player_ui_item.change_color(colors_dict[i])
		players[i]['model'].get_item.connect(player_ui_item.get_item)
		players[i]['model'].use_item.connect(player_ui_item.remove_item)
		$"../CanvasLayer/items".add_child(player_ui_item)

func calculate_score() -> Array[Dictionary]:
	var players_dict: Array[Dictionary] = []
	for i in range(players.size()):
		players_dict.append({
			"id": i + 1,
			"portrait": players[i]['portrait'],
			"score": players_points[i],
			"show": 0,
			"pos": 0,
			"scored": 0,
			"total_score": 0
		})
	
	players_dict.sort_custom(func (a, b): return a['score'] > b['score'])
	
	var points : int = 7
	for i in range(players_dict.size()):
		var player_index : int = players_dict[i]["id"] - 1
		players_dict[i]['scored'] = points
		players_dict[i]["pos"] = i + 1
		players_dict[i]["total_score"] = points + players[i]["score"]
		GameLogic.update_player_total_points(player_index, points)
		points -= 2
	
	players_dict.sort_custom(func (a, b): return a['id'] < b['id'])
	
	return players_dict

func hide_ui_points() -> void:
	$"../CanvasLayer/players".visible = false
	$"../CanvasLayer/items".visible = false
	return

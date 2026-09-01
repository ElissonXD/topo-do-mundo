extends Node

# configurações

@export_category('Configurações gerais')
@export var general_timer : Timer
@export var start_timer : Timer
@export var spawn_points : Array[Node]
@export var players : Array[Dictionary]
@export var players_points : Array[int] = [0,0,0,0]
@export var game_started : bool = false
@export var game_ended : bool = false
@export var roundResults : Control

# sinais

signal get_players_points(player_points : Array[int]);
# pega as pontuações dos 4 players
signal get_start_timer(timer : Timer)
# pega o timer inicial
signal get_game_timer(timer: Timer)
# pega o timer do jogo
signal game_end(dados: Array) 


func _ready() -> void:
	players = GameLogic.get_players()
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	general_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	spawn_points = get_tree().get_nodes_in_group('Spawn')
	get_tree().paused = true
	
	for x in range(len(players)):
		$"../Jogadores".add_child(players[x]['model'])
		players[x]["model"].global_position = spawn_points[x].global_position
	
	create_ui_points(len(players))
	
	start_timer.start(3)
	get_start_timer.emit(start_timer)
	
	return


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if game_started and not game_ended:
		var menor_y: int = 9999999999 
		var player_vencedor: Dictionary
		var empate: bool = false
		for player in players:
			if int(player['model'].global_position.y) < menor_y:
				menor_y = int(player['model'].global_position.y)
				player_vencedor = player
				empate = false
			elif int(player['model'].global_position.y) == menor_y:
				empate = true
		if player_vencedor != null and not empate:
			match player_vencedor['id']:
				1:
					players_points[0] += delta * 100
				2:
					players_points[1] += delta * 100
				3:
					players_points[2] += delta*100
				4:
					players_points[3] += delta * 100
		
		
		get_players_points.emit(players_points)
		# adicionar logica de coroa	
	
	if game_ended:
		get_tree().paused = true
		

func create_ui_points(length):
	
	var object = load("res://game/scenes/ui_principal/player_bar.tscn")
	for i in range(length):
		var player_ui_score = object.instantiate()
		$"../CanvasLayer/players".add_child(player_ui_score)
		player_ui_score.change_player(i)
		get_players_points.connect(player_ui_score.change_score)
		
	
	return
	


func _on_timer_2_timeout() -> void:
	game_started = true
	get_tree().paused = false
	general_timer.start(1)
	get_game_timer.emit(general_timer)


func _on_timer_timeout() -> void:
	var mock_placar = [
		{
			"id": 1,
			"score": 15000,
			"show": 0,
			"pos": 1,
			"scored": 100,
			"total_score": 450
		},
		{
			"id": 2,
			"score": 12000,
			"show": 0,
			"pos": 2,
			"scored": 75,
			"total_score": 380
		},
		{
			"id": 3,
			"score": 8000,
			"show": 0,
			"pos": 3,
			"scored": 50,
			"total_score": 290
		},
		{
			"id": 4,
			"score": 1000,
			"show": 0,
			"pos": 4,
			"scored": 25,
			"total_score": 150
		}
	]
	
	roundResults.go_to_score_state(mock_placar)
	game_end.emit(mock_placar as Array)
	game_ended = true

extends Node


@export_category('Configurações gerais')
@export var general_timer : Timer
@export var start_timer : Timer
@export var spawn_points : Array[Node]
@export var players : Array[PlayerModel]
@export var players_points : Array[int] = [0,0,0,0]
@export var game_started : bool = false



func _ready() -> void:
	# aqui deve exisir uma conexão com um sinal que recebe os players
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	spawn_points = get_tree().get_nodes_in_group('Spawn')
	get_tree().paused = true
	
	for x in range(4):
		# atualizar para instanciar
		players[x].global_position = spawn_points[x].global_position
	
	start_timer.start(3)
	
	return


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if game_started:
		var menor_y: int = 9999999999 
		var player_vencedor: Node2D = null
		var empate: bool = false
		for player in players:
			if int(player.global_position.y) < menor_y:
				menor_y = int(player.global_position.y)
				player_vencedor = player
				empate = false
			elif int(player.global_position.y) == menor_y:
				empate = true
		if player_vencedor != null and not empate:
			match player_vencedor.name:
				'PlayerModel':
					players_points[0] += delta * 100
				'PlayerModel2':
					players_points[1] += delta * 100
				'PlayerModel3':
					players_points[2] += delta*100
				'PlayerModel4':
					players_points[3] += delta * 100
		
		print(players_points)
		# adicionar logica de coroa
		
	
		


func _on_timer_2_timeout() -> void:
	game_started = true
	get_tree().paused = false

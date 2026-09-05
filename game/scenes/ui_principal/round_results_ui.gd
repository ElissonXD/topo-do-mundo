extends Control

# players
@export var round_player: Control 
@export var round_player_2: Control 
@export var round_player_3: Control 
@export var round_player_4: Control 

var players_array : Array[Control]
var players_results : Array # dicionario com id do player, pontuação da rodada, pontuação total
var number_players : int

"""
dicionario que deve receber (o array tem que já estar em ordem dos players):
	score: x -> pontuação da rodada
	show: 0 -> pontuação para mostrar no placar
	pos: x -> posição em que ficou
	scored: x -> pontuação adquirida com base na posição
	total_score: x -> pontuação do jogo já incrementada
"""

# statemachine manual pq eu sou foda

enum RoundState {
	none,
	score,
	board,
	general
}

var state : RoundState

"""
	estado de mostrar pontuação: incrementa pontuação ate a rodada
		- apos incrementar, 1 segundo de espera, ir para o proximo estado
	estado de mostrar placar: só mostra, timer de 1 segundo de espera
	estado de mostrar geral: só mostra, timer de 5 segundos para ir emitir sinal
"""

func _ready() -> void:
	visible = false
	state = RoundState.none
	process_mode = Node.PROCESS_MODE_ALWAYS
	var players = GameLogic.get_players()
	number_players = len(players)
	players_array = [round_player, round_player_2, round_player_3, round_player_4]



func _process(delta: float) -> void:
	
	match state:
		RoundState.score:
			score_state(delta)
		RoundState.board:
			board_state()
		RoundState.general:
			general_state()
	
	return

# funções de entrada

func go_to_score_state(results : Array):
	state = RoundState.score
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	players_results = results
	
	for x in range(number_players):
		var player = 'Player ' + str(x+1)
		players_array[x].show_details(player)
	
	return

func go_to_board_state():
	state = RoundState.board
	return

func go_to_general_state():
	state = RoundState.general
	return

# funções permanência

func score_state(delta: float):
	# animação de incrementar
	for i in range(number_players):
		var current_display = players_results[i]['show']
		var target_display = players_results[i]['score']
		players_results[i]['show'] = min(delta * 679 + current_display, target_display)
		players_array[i].show_points(players_results[i]['show'])
	
	# verificação se todos estão no maximo
	if verify_all_scores():
		get_tree().create_timer(2).timeout.connect(func(): go_to_board_state())
			 
	return
	
func board_state():
	for i in range(number_players):
		var pos = players_results[i]['pos']
		var general_score = players_results[i]['scored']
		players_array[i].show_placar(pos, general_score)
	
	get_tree().create_timer(2).timeout.connect(func(): go_to_general_state())
	return

func general_state():
	for i in range(number_players):
		var total_score = players_results[i]['total_score']
		players_array[i].show_geral(total_score)
	
	get_tree().create_timer(5).timeout.connect(func(): next_scene())
	return

# funções uteis

func verify_all_scores():
	var total = 0
	
	for i in range(number_players):
		if players_results[i]['show'] == players_results[i]['score']:
			total += 1
	
	return total == number_players

func next_scene():
	GameLogic.go_to_next_map()
	return

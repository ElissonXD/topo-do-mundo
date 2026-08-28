extends Control

# labels
@export var player: Label
@export var score: Label
var player_int : int = 0

# vai enviar o index do player
func change_player(new_player : int) -> void:
	player.text = "Player " + str(new_player+1)
	player_int = new_player

# isso aqui vai conectar com o round logic, recebendo o array
func change_score(scores:Array[int]) -> void:
	score.text = str(scores[player_int])
	return

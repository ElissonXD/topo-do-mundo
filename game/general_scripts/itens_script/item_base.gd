class_name ItemBase
extends Area2D
 
var spawn_data: ItemSpawnData
 
 
func _ready() -> void:
	body_entered.connect(_on_body_entered)
 
 
func _on_body_entered(body: Node2D) -> void:
	print('COLIDIU COM: ', body.name)
	var player := _find_player_model(body)
	if player == null:
		return
	print('PLAYER ENCONTRADO, current_item = ', player.current_item)
	_try_pick_up(player)
 
 
func _find_player_model(body: Node2D) -> PlayerModel:
	if body is PlayerModel:
		return body
 
	for child in body.get_children():
		if child is PlayerModel:
			return child
 
	return null
 
 
func _try_pick_up(player: PlayerModel) -> void:
	print('TENTANDO PEGAR, spawn_data = ', spawn_data, ' | current_item do player = ', player.current_item)
	if player.current_item != null:
		return
 
	player.current_item = spawn_data
	queue_free()

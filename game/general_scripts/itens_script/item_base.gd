class_name ItemBase
extends Area2D
 
var spawn_data: ItemSpawnData
 
 
func _ready() -> void:
	body_entered.connect(_on_body_entered)
 
 
func _on_body_entered(body: Node2D) -> void:
	var player := _find_player_model(body)
	if player == null:
		return
	_try_pick_up(player)
 
 
func _find_player_model(body: Node2D) -> PlayerModel:
	if body is PlayerModel:
		return body
 
	for child in body.get_children():
		if child is PlayerModel:
			return child
 
	return null
 
 
func _try_pick_up(player: PlayerModel) -> void:
	if player.current_item != null:
		return
 
	player.current_item = spawn_data
	player.get_item.emit(spawn_data.texture)
	queue_free()

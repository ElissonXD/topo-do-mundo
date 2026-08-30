class_name ItemBase
extends Area2D
 
var spawn_data: ItemSpawnData
 
var _player_in_range: PlayerModel = null
 
 
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
 
 
func _process(_delta: float) -> void:
	if _player_in_range == null:
		return
 
	var interact_action := 'interact_' + str(_player_in_range.control_schema)
 
	if Input.is_action_just_pressed(interact_action):
		_try_pick_up(_player_in_range)
 
 
func _on_body_entered(body: Node2D) -> void:
	if body is PlayerModel:
		if body.current_item == null:
			_player_in_range = body
 
 
func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
 
 
func _try_pick_up(player: PlayerModel) -> void:
	if player.current_item != null:
		return
 
	player.current_item = spawn_data
	queue_free()  

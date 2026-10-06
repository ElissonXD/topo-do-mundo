extends Item

var _previous_author_process_mode: ProcessMode
var players_affected: Array[Node]
var items_affected: Array[Node]
var timer_affected: Array[Node]
var color_rect : ColorRect


func _ready() -> void:
	
	# para evitar bugs e questão de balanceamento, zawarudo nao pode ser ativado duas vezes
	if get_tree().paused:
		queue_free()
	
	players_affected = get_tree().get_nodes_in_group('Player')
	items_affected = get_tree().get_nodes_in_group('Item')
	timer_affected = get_tree().get_nodes_in_group('Game_Timer')
	color_rect = get_tree().get_first_node_in_group('color_rect') 
	AUTHOR.z_index = 5
	for player in players_affected:
		if player != AUTHOR:
			player.process_mode = Node.PROCESS_MODE_DISABLED
			player.set_physics_process(true)
			player.set_process(true)
		
	for item in items_affected:
		if item != self:
			item.process_mode = Node.PROCESS_MODE_DISABLED
			item.set_physics_process(true)
	for time in timer_affected:
		time.process_mode = Node.PROCESS_MODE_DISABLED
	
	color_rect.material.set_shader_parameter("intensity", 1.0)
	PhysicsServer2D.set_active(true)
	
	#aplicar algum efeito de shader e efeitos sonoros aqui


func _process(delta: float) -> void:
	DURATION -= delta
	
	if DURATION <= 0:
		_end_effect()


func _end_effect() -> void:
	for player in players_affected:
		if player != AUTHOR:
			player.process_mode = Node.PROCESS_MODE_PAUSABLE
	for item in items_affected:
		if item != self:
			item.process_mode = Node.PROCESS_MODE_PAUSABLE
	for time in timer_affected:
		time.process_mode = Node.PROCESS_MODE_PAUSABLE
	color_rect.material.set_shader_parameter("intensity", 0.0)
	AUTHOR.z_index = 0
	queue_free()


func _exit_tree() -> void:
	get_tree().paused = false

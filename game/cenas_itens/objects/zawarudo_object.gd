extends Item

var _previous_author_process_mode: ProcessMode


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if AUTHOR != null:
		_previous_author_process_mode = AUTHOR.process_mode
		AUTHOR.process_mode = Node.PROCESS_MODE_ALWAYS
	
	get_tree().paused = true
	PhysicsServer2D.set_active(true)


func _process(delta: float) -> void:
	DURATION -= delta
	
	if DURATION <= 0:
		_end_effect()


func _end_effect() -> void:
	get_tree().paused = false
	
	if AUTHOR != null:
		AUTHOR.process_mode = _previous_author_process_mode
	
	queue_free()


func _exit_tree() -> void:
	get_tree().paused = false

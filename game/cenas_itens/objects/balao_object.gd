extends Item

# enquanto estiver ativo, só vai subir o player

func _ready() -> void:
	global_position.x = AUTHOR.global_position.x
	global_position.y = AUTHOR.global_position.y - 40
	AUTHOR.go_to_flying_state()

func _process(delta: float) -> void:
	DURATION -= delta
	
	if DURATION <= 0:
		AUTHOR.go_to_falling_state()
		queue_free()
		return
	
	global_position.x = AUTHOR.global_position.x
	global_position.y = AUTHOR.global_position.y - 40
	AUTHOR.velocity.y = -POWER

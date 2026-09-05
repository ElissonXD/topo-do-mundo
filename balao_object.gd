extends Item

# enquanto estiver ativo, só vai subir o player

func _ready() -> void:
	position.x = AUTHOR.position.x
	position.y = AUTHOR.position.y - 20
	AUTHOR.go_to_flying_state()

func _process(delta: float) -> void:
	DURATION -= delta
	
	if DURATION <= 0:
		AUTHOR.go_to_falling_state()
		queue_free()
		return
	
	position.y = AUTHOR.position.y - 20
	position.x = AUTHOR.position.x
	AUTHOR.velocity.y = -POWER

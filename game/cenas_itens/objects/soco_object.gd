extends Item

var direction: int = 1


func _ready() -> void:
	direction = 1
	if AUTHOR.aim.position.x < 0:
		direction = -1
	
	global_position = AUTHOR.aim.global_position
	freeze = true


func _physics_process(delta: float) -> void:
	DURATION -= delta
	
	if DURATION <= 0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == AUTHOR:
		return
	
	if not body.is_in_group("Player"):
		return
	
	if not body.can_be_hurt():
		return
	
	body.apply_knockback(self, POWER, -direction)
	body.go_to_hurt_state()
	
	queue_free()  

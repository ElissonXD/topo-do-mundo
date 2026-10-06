extends Item

@export var snow_duration : float = 3.0
@export var throw_speed : float = 600.0
@export var gravity_scale_item : float = 1.0

func _ready() -> void:
	max_contacts_reported = 2
	gravity_scale = gravity_scale_item

func throw(direction: Vector2) -> void:
	#vou ter que fazer gambiarra por enquanto, mas depois devo ajeitar
	freeze = false
	apply_central_impulse(direction.normalized() * throw_speed)



func _on_area_2d_body_entered(body: Node2D) -> void:
	# só colide com plyaer ou parede
	if body is PlayerModel:
		if body.can_be_hurt() and body != AUTHOR:
			var dir_x = sign(linear_velocity.x)
			var knockback_dir = Vector2(dir_x, -0.5).normalized()
			body.apply_knockback(knockback_dir, POWER)
			body.go_to_freeze_state(snow_duration)
		else:
			#continua a trajetoria atravessando
			return
	queue_free()

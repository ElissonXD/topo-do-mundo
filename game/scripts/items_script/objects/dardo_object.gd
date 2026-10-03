extends Item

@export_category("Configurações do dardo")
@export var ACCEL : float = 200
@export var MAX_SPEED : float = 600
var players : Array 
var focused : Node2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision: Area2D = $vision

func _ready() -> void:
	animated_sprite_2d.flip_h = AUTHOR.animation.flip_h	
	
	var min_distance = INF
	
	var direction = 1
	if AUTHOR.aim.position.x < 0:
		direction = -1
		rotation_degrees = 180
	linear_velocity.x = (MAX_SPEED / 2) * direction
	

func _physics_process(delta: float) -> void:
	
	DURATION -= delta
	
	if DURATION < 0:
		queue_free()
	
	if focused != null:
		var direction = position.direction_to(focused.position)
		var target_angle = direction.angle()

		rotation = rotate_toward(rotation, target_angle, 2*delta)

		var forward_dir = Vector2.RIGHT.rotated(rotation)
		var target_velocity = forward_dir * MAX_SPEED
		linear_velocity = linear_velocity.move_toward(target_velocity, ACCEL * delta)
		
	else:
		var target_velocity = Vector2.RIGHT.rotated(rotation) * MAX_SPEED
		linear_velocity = linear_velocity.move_toward(target_velocity, ACCEL * delta)

func _on_body_entered(body: Node) -> void:
	if body == AUTHOR:
		return
		
	if body.is_in_group("Player"):
		if body.can_be_hurt():
			var dir_x = sign(linear_velocity.x)
			var knockback_dir = Vector2(dir_x, -0.5).normalized()
			body.apply_knockback(knockback_dir, POWER)
			body.go_to_hurt_state()
		else:
			return
			
	queue_free()


func _on_vision_body_entered(body: Node2D) -> void:
	if body == AUTHOR:
		return
	if focused == null:
		focused = body
		return
	
	var distance1 = body.global_position.distance_to(global_position)
	var distance2 = focused.global_position.distance_to(global_position)
	
	if (distance1 < distance2):
		focused = body
	return


func _on_vision_body_exited(body: Node2D) -> void:
	focused = null
	return

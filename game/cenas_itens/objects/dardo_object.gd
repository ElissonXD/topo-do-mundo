extends Item

@export_category("Configurações do dardo")
@export var ACCEL : float = 200
@export var MAX_SPEED : float = 400
var players : Array 
var focused : Node2D


func _ready() -> void:
	players = get_tree().get_nodes_in_group('Player')
	
	var min_distance = INF

	for player in players:
		if player != AUTHOR:
			var distance = global_position.distance_to(player.global_position)
			if distance < min_distance:
				min_distance = distance
				focused = player
	
	linear_velocity.x = MAX_SPEED / 2
	

func _physics_process(delta: float) -> void:
	
	DURATION -= delta
	
	if DURATION < 0:
		queue_free()
	
	var direction = position.direction_to(focused.position)
	var target_velocity = direction * MAX_SPEED
	
	var target_angle = direction.angle()
	rotation = lerp_angle(rotation, target_angle, 50 * delta)
	
	linear_velocity = linear_velocity.move_toward(target_velocity, ACCEL * delta)



func _on_body_entered(body: Node) -> void:
	if body == AUTHOR:
		return
		
	if body.is_in_group("Player"):
		body.apply_knockback(body, POWER)
		body.go_to_hurt_state()
			
	queue_free()

extends RigidBody2D
class_name StunItem

@export var stun_duration : float = 3.0
@export var throw_speed : float = 600.0
@export var gravity_scale_item : float = 1.0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 2
	body_entered.connect(_on_body_entered)
	gravity_scale = gravity_scale_item

func throw(direction: Vector2) -> void:
	# Chame isso no momento do arremesso
	freeze = false
	apply_central_impulse(direction.normalized() * throw_speed)

func _on_body_entered(body: Node) -> void:
	# body pode ser o PlayerModel ou um TileMap/World
	if body is PlayerModel:
		body.apply_stun(stun_duration)
		queue_free()
	elif body is StaticBody2D or body is TileMap:
		queue_free()

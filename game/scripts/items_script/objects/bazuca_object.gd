extends Item

@export_category("Configurações do foguete")
@export var explosion_scene: PackedScene

var direction: int = 1
var _exploded: bool = false


@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	direction = 1
	if AUTHOR.aim.position.x < 0:
		direction = -1
		if sprite != null:
			sprite.flip_h = true
	
	linear_velocity.x = POWER * direction


func _physics_process(delta: float) -> void:
	DURATION -= delta
	
	if DURATION < 0:
		_explode()


func _on_body_entered(body: Node) -> void:
	if body == AUTHOR:
		return
	
	_explode()


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	
	if explosion_scene != null:
		var explosion := explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
		if explosion.has_method("setup"):
			explosion.setup(AUTHOR)
	
	queue_free()

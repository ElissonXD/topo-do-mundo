extends Item

var direction: int = 1
var OFFSET: float = 20
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var Sfx : AudioStreamPlayer =$AudioStreamPlayer

func _ready() -> void:
	direction = 1
	sprite_2d.flip_h = true
	if AUTHOR.aim.position.x < 0:
		direction = -1
		sprite_2d.flip_h = false
		
	
	global_position = AUTHOR.aim.global_position
	global_position.x += OFFSET * direction
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
	Sfx.play()
	var knockback_dir = Vector2(direction, -0.2).normalized()
	body.apply_knockback(knockback_dir, POWER)
	body.go_to_hurt_state()
	
	queue_free()  

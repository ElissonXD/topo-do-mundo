class_name Explosion
extends Area2D
 
@export_category("Configurações da explosão")
@export var max_knockback_power: float = 700.0
@export var min_knockback_power: float = 200.0
@export var max_stun_time: float = 1.0
@export var min_stun_time: float = 0.2
@export var explosion_radius: float = 80.0  # deve bater com o raio real da CollisionShape2D
 
@export var fallback_lifetime: float = 1.0
 
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var audio : AudioStreamPlayer = $AudioStreamPlayer
var _author: Node2D = null
var _already_hit: Array = []
 
 
func setup(author: Node2D) -> void:
	_author = author
 
 
func _ready() -> void:
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		animated_sprite.play("default")
		audio.play()

	body_entered.connect(_on_body_entered)
	
	for body in get_overlapping_bodies():
		_apply_explosion_to(body)
	
	_wait_and_free()
 
 
func _on_body_entered(body: Node) -> void:
	if body != _author:
		_apply_explosion_to(body)
 
 
func _wait_and_free() -> void:
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(fallback_lifetime).timeout
	
	queue_free()
 
 
func _apply_explosion_to(body: Node) -> void:
	if body in _already_hit:
		return
	
	if not body.is_in_group("Player"):
		return
	
	if not body.can_be_hurt():
		return
	
	var offset: Vector2 = body.global_position - global_position
	var distance: float = offset.length()
	
	if distance > explosion_radius:
		return
	
	_already_hit.append(body)
	
	var closeness: float = 1.0 - clamp(distance / explosion_radius, 0.0, 1.0)
	var knockback_power: float = lerp(min_knockback_power, max_knockback_power, closeness)
	var stun_time: float = lerp(min_stun_time, max_stun_time, closeness)
	var knockback_dir = global_position.direction_to(body.global_position)
	knockback_dir.y = clamp(knockback_dir.y, -2, -0.5)
	knockback_dir = knockback_dir.normalized()
	
	body.apply_knockback(knockback_dir, knockback_power)
	body.go_to_hurt_state()
	body.hurt_timer = stun_time

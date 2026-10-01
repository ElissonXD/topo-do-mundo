extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_anything_pressed():
		$Control.show()
		$Control/Timer.start()
		$Control/AnimationPlayer.play("Transicao")
		
	pass


func _on_timer_timeout():
	get_tree().change_scene_to_file("res://game/scenes/menus/main_menu.tscn")
	pass # Replace with function body.

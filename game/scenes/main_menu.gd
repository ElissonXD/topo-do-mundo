extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_pressed():
	get_tree().change_scene_to_file("res://game/scenes/test/test_2 da camera.tscn")
	#mudar para selecao de personagem
	pass # Replace with function body.


func _on_opcoes_pressed():
	#get_tree().change_scene_to_file()
	pass # Replace with function body.


func _on_creditos_pressed():
	get_tree().change_scene_to_file("res://assets/temp_assets/creditos/creditos.tscn")
	pass # Replace with function body.

extends Node2D
var botao = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_pressed():
	botao = "JOGO"
	$ColorRect.show()
	$ColorRect/Timer.start()
	$ColorRect/AnimationPlayer.play("Transicao")
	
	#mudar para selecao de personagem
	pass # Replace with function body.


func _on_opcoes_pressed():
	botao = "OPCAO"
	$ColorRect.show()
	$ColorRect/Timer.start()
	$ColorRect/AnimationPlayer.play("Transicao")
	pass # Replace with function body.


func _on_creditos_pressed():
	$ColorRect.show()
	$ColorRect/Timer.start()
	$ColorRect/AnimationPlayer.play("Transicao")
	pass
func _on_timer_timeout():
	if botao == "JOGO":
		get_tree().change_scene_to_file("res://game/scenes/test/test_2 da camera.tscn")
	elif botao == "OPCAO":
		get_tree().change_scene_to_file("res://assets/Opcoes.tscn")
	else:
		get_tree().change_scene_to_file("res://assets/temp_assets/creditos/creditos.tscn")	
	pass # Replace with function body.

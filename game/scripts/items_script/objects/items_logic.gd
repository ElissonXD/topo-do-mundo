class_name Item
extends RigidBody2D # tá, nao sei se é viavel, lol

@export_category("Configurações do item")
@export var DURATION : float = 1
@export var POWER : float = 200
@export var AUTHOR : Node2D
@export var time_stopped : bool = false

func set_author(body: Node2D) -> void:
	AUTHOR = body
	return

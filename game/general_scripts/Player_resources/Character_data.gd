# character_data.gd
class_name CharacterData
extends Resource

@export var character_name: String = "Nome"
@export var portrait: Texture2D
@export var scene_path: String = "res://characters/character.tscn"
@export var is_unlocked: bool = true

# character_slot.gd
class_name CharacterSlot
extends Control

@onready var portrait: TextureRect = %Portrait
@onready var name_label: Label = %NameLabel
@onready var highlight: Control = %Highlight
@onready var badges: HBoxContainer = %Badges

var data: CharacterData
var hovering_players: Array[int] = []

func setup(character: CharacterData) -> void:
	data = character
	portrait.texture = data.portrait
	name_label.text = data.character_name
	highlight.hide()

func set_hover(player: int, hovering: bool) -> void:
	if hovering and player not in hovering_players:
		hovering_players.append(player)
	elif not hovering:
		hovering_players.erase(player)
	_refresh()

func _refresh() -> void:
	highlight.visible = not hovering_players.is_empty()
	var tween := create_tween()
	var target := Vector2.ONE * (1.1 if highlight.visible else 1.0)
	pivot_offset = size / 2.0
	tween.tween_property(self, "scale", target, 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func show_confirmed(player: int) -> void:
	var tag := Label.new()
	tag.text = "P%d" % (player + 1)
	badges.add_child(tag)

extends Control

@export var texture_rect: TextureRect
@export var panel_container: PanelContainer


func _ready() -> void:
	texture_rect.visible = false

func change_color(color : Color) -> void:
	var current_style = panel_container.get_theme_stylebox("panel") as StyleBoxFlat
	var new_style = current_style.duplicate() as StyleBoxFlat
	new_style.border_color = color
	panel_container.add_theme_stylebox_override("panel", new_style)

func get_item(image : Texture) -> void:
	texture_rect.texture = image
	texture_rect.visible = true
	return

func remove_item() -> void:
	texture_rect.visible = false
	return

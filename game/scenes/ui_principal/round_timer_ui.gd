extends Control

@export var display_timer : Timer
@onready var label: Label = $Panel/MarginContainer/HBoxContainer/Label

func _process(delta: float) -> void:
	var minutes = int(display_timer.time_left) / 60
	var seconds = int(display_timer.time_left) % 60

	var display_string = "%02d:%02d" % [minutes, seconds]
	label.text = display_string
	
	if minutes == 0 and seconds < 30:
		label.add_theme_color_override("font_color", Color.RED)

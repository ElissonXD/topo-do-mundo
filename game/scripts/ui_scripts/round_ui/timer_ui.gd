extends Control

@export var timer_display : Timer
@onready var label: Label = $Panel/Label

func _ready() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	# vai começar do 5, então subtrair 1 pq delays
	label.text = str(int(timer_display.time_left) - 1) + '...'
	
	if timer_display.time_left <= 2:
		label.text = 'VAI!'
	
	if timer_display.is_stopped():
		visible = false

extends Control

# Exporte as referências dos nós para conectar no Inspector
@export var master_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider
@export var mute_button: CheckButton

const CONFIG_PATH = "user://volume_settings.cfg"

func _ready() -> void:
	# Conecta os sinais dos sliders ao volume dos buses
	master_slider.value_changed.connect(_on_volume_changed.bind("Master"))
	music_slider.value_changed.connect(_on_volume_changed.bind("Music"))
	sfx_slider.value_changed.connect(_on_volume_changed.bind("SFX"))
	
	# Conecta o botão de mudo
	mute_button.toggled.connect(_on_mute_toggled)
	
	# Carrega as configurações salvas
	load_settings()

func _on_volume_changed(value: float, bus_name: String) -> void:
	_set_bus_volume(bus_name, value)
	save_settings()

func _on_mute_toggled(button_pressed: bool) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, button_pressed)
	save_settings()

func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	
	# Converte o valor linear (0..1) para decibéis
	var db = linear_to_db(value) if value > 0.0 else -80.0
	AudioServer.set_bus_volume_db(bus_idx, db)

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("volume", "Master", master_slider.value)
	config.set_value("volume", "Music", music_slider.value)
	config.set_value("volume", "SFX", sfx_slider.value)
	config.set_value("volume", "mute", mute_button.button_pressed)
	config.save(CONFIG_PATH)

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	
	var master_value = config.get_value("volume", "Master", 1.0)
	var music_value = config.get_value("volume", "Music", 1.0)
	var sfx_value = config.get_value("volume", "SFX", 1.0)
	var mute = config.get_value("volume", "mute", false)
	
	# Define os valores sem disparar os sinais
	master_slider.set_value_no_signal(master_value)
	music_slider.set_value_no_signal(music_value)
	sfx_slider.set_value_no_signal(sfx_value)
	mute_button.set_pressed_no_signal(mute)
	
	# Aplica os valores diretamente nos buses
	_set_bus_volume("Master", master_value)
	_set_bus_volume("Music", music_value)
	_set_bus_volume("SFX", sfx_value)
	
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, mute)


func _on_texture_button_pressed():
	$ColorRect.show()
	$ColorRect/Timer.start()
	$ColorRect/AnimationPlayer.play("Transicao")
	
	


func _on_timer_timeout():
	get_tree().change_scene_to_file("res://game/scenes/menus/main_menu.tscn")
	

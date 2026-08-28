extends Control

@export_category("Configurações da seleção")
@export var grid: GridContainer
@export var columns: int = 4
@export var rows: int = 3
@export var cursor_scene: PackedScene  # cena do cursor (CharacterCursor)
@export var cursor_positions: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0)]  # posições iniciais

# Dados dos personagens (preenchidos no _ready ou via editor)
var characters: Array[CharacterData] = []
var cursors: Array[CharacterCursor] = []

func _ready():
	load_characters()
	create_portraits()
	setup_cursors()
	connect_signals()
	update_ui()

func load_characters():
	# Exemplo: carregar recursos .tres de uma pasta
	var dir = DirAccess.open("res://characters")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var char_data = load("res://characters/" + file_name) as CharacterData
				if char_data:
					characters.append(char_data)
			file_name = dir.get_next()
	# Ou carregue manualmente:
	# characters.append(load("res://characters/mario.tres"))
	# ...

func create_portraits():
	# Limpar retratos antigos (se houver)
	for child in grid.get_children():
		child.queue_free()
	# Criar um retrato para cada personagem
	for char in characters:
		var portrait = TextureRect.new()
		portrait.texture = char.portrait
		portrait.custom_minimum_size = Vector2(120, 120)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Aplicar shader de cor
		var shader = load("res://shaders/hue_shift.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("hue_shift", 0.0)
		portrait.material = mat
		grid.add_child(portrait)
	# Garantir que a grade tenha o número correto de colunas
	grid.columns = columns

func setup_cursors():
	# Criar cursores para cada jogador (até 4)
	for i in range(4):  # ou use total_players do GameManager
		if i >= GameLogic.total_players:
			break
		var cursor = cursor_scene.instantiate() as CharacterCursor
		cursor.player_id = i + 1
		cursor.grid = grid
		cursor.columns = columns
		cursor.rows = rows
		add_child(cursor)
		# Definir posição inicial
		if i < cursor_positions.size():
			cursor.current_grid_pos = cursor_positions[i]
		else:
			cursor.current_grid_pos = Vector2i(i % columns, i / columns)
		
		cursors.append(cursor)
		cursor.update_cursor_position()

func connect_signals():
	for i in range(cursors.size()):
		var cursor = cursors[i]
		# Conectar movimento, confirmação, cancelamento e troca de cor
		cursor.connect("cursor_moved", Callable(self, "_on_cursor_moved").bind(i))
		cursor.connect("confirm_pressed", Callable(self, "_on_confirm_pressed").bind(i))
		cursor.connect("cancel_pressed", Callable(self, "_on_cancel_pressed").bind(i))
		cursor.connect("costume_changed", Callable(self, "_on_costume_changed").bind(i))

# ----- Handlers dos sinais -----
func _on_cursor_moved(player_index: int, character_index: int):
	# Atualizar painel do jogador (nome do personagem)
	update_player_panel(player_index)

func _on_costume_changed(player_index: int, costume_index: int):
	# Atualizar painel do jogador (número da cor)
	update_player_panel(player_index)

func _on_confirm_pressed(player_index: int):
	var cursor = cursors[player_index]
	var char_data = characters[cursor.selected_character]
	var costume_index = cursor.current_costume_index
	# Atualizar GameManager
	if player_index >= GameLogic.players_data.size():
		GameLogic.add_player(char_data.model, costume_index, str(player_index + 1))
	else:
		GameLogic.players_data[player_index]["model"] = char_data.model
		GameLogic.players_data[player_index]["costume_index"] = costume_index
		GameLogic.players_data[player_index]["control_schema"] = str(player_index + 1)
	GameLogic.set_player_ready(player_index, true)
	update_ui()

func _on_cancel_pressed(player_index: int):
	if player_index < GameLogic.players_data.size():
		GameLogic.set_player_ready(player_index, false)
	update_ui()

# ----- Atualização da interface -----
func update_ui():
	for i in range(cursors.size()):
		update_player_panel(i)
	# Verificar se todos os jogadores confirmaram e iniciar partida
	if GameLogic.all_players_ready():
		# Pequeno atraso para mostrar "Pronto" antes de trocar de cena
		await get_tree().create_timer(1.0).timeout
		GameLogic.go_to_main_game()

func update_player_panel(player_index: int):
	var cursor = cursors[player_index]
	var panel = get_node_or_null("UI/PlayerPanel%d" % (player_index + 1))
	if not panel:
		return
	# Nome do personagem
	var name_label = panel.get_node_or_null("NameLabel")
	if name_label:
		if cursor.selected_character < characters.size():
			name_label.text = characters[cursor.selected_character].display_name
		else:
			name_label.text = "Nenhum"
	# Estado (Pronto / Escolhendo)
	var status_label = panel.get_node_or_null("StatusLabel")
	if status_label:
		var is_ready = GameLogic.players_data.size() > player_index and GameLogic.players_data[player_index].get("ready", false)
		status_label.text = "Pronto!" if is_ready else "Escolhendo..."
		status_label.modulate = Color.GREEN if is_ready else Color.WHITE
	# Número da cor/costume
	var costume_label = panel.get_node_or_null("CostumeLabel")
	if costume_label:
		costume_label.text = "Cor: %d/%d" % [cursor.current_costume_index + 1, cursor.costumes_per_character]

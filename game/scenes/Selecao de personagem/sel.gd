extends Control
@export_category("Configurações da seleção")
@export var grid: GridContainer
@export var columns: int = 2
@export var rows: int = 2
@export var cursor_scene: PackedScene  # cena do cursor (CharacterCursor)
@export var cursor_positions: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0)]  # posições iniciais
@export var player_panels: Array[Panel]  # arraste os painéis no inspetor

# Dados dos personagens (preenchidos no _ready ou via editor)
var characters: Array[CharacterData] = []
var cursors: Array[CharacterCursor] = []

func _ready():
	load_characters()
	create_portraits()
	setup_cursors()
	connect_signals()
	#update_ui()
	update_player_panels()

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
		var shader = load("res://game/scenes/player/Colorswt.gdshader")
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
		cursor.connect("cursor_moved", Callable(self, "_on_cursor_moved"))
		cursor.connect("confirm_pressed", Callable(self, "_on_confirm_pressed"))
		cursor.connect("cancel_pressed", Callable(self, "_on_cancel_pressed"))
		cursor.connect("costume_changed", Callable(self, "_on_costume_changed"))

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
	
	# Verifica se o personagem está desbloqueado (se houver)
	if not char_data.is_unlocked:return
	
	# Pega o modelo (instância ou caminho)
	var player_model = char_data.scene
	# Se model for PackedScene, instancie-o ou passe o caminho; 
	# melhor: guarde o próprio recurso PlayerModel se ele contiver todos os dados.
	# Mas pelo seu código, parece que você está usando um "model" que é um recurso.
	# Vou supor que CharacterData tem um campo "player_model" do tipo PlayerModel.
	
	# Extrai a habilidade (pode vir do CharacterData)
	var ability = char_data.ability if char_data.has("ability") else 0
	
	# Chama o GameLogic para adicionar/atualizar o jogador
	if player_index >= GameLogic.players_data.size():
		GameLogic.add_player(player_model, costume_index, str(player_index + 1), ability)
	else:
		# Atualiza os dados existentes
		var p_data = GameLogic.players_data[player_index]
		p_data["model"] = player_model
		p_data["costume_index"] = costume_index
		p_data["controls"] = str(player_index + 1)
		p_data["ability"] = ability
		p_data["ready"] = true
		GameLogic.update_player.emit()
	
	# Marca o jogador como pronto (se já não estiver)
	#GameLogic.set_player_ready(player_index, true)
	
	# Atualiza UI (painel do jogador)
	update_player_panel(player_index)
func _on_cancel_pressed(player_index: int):
	if player_index < GameLogic.players_data.size():
		GameLogic.set_player_ready(player_index, false)
	# update_ui()
func update_player_panel(player_index: int):
	var panel = get_node("PlayerPanels/Player%d" % (player_index+1))
	if not panel:
		return
	var name_label = panel.get_node("NameLabel")
	var costume_label = panel.get_node("CostumeLabel")
	var ready_indicator = panel.get_node("ReadyIndicator")
	if player_index < GameLogic.players_data.size():
		var p = GameLogic.players_data[player_index]
		var char_data = get_character_by_model(p["model"])
		if char_data:
			name_label.text = char_data.character_name
		costume_label.text = "Cor %d" % (p["costume_index"] + 1)
		ready_indicator.visible = p["ready"]
	else:
		name_label.text = "Aguardando..."
		costume_label.text = ""
		ready_indicator.visible = false
func get_character_by_model(model) -> CharacterData:
	for char in characters:
		# Se model for um recurso (ex: PlayerModel), compare as referências
		if char.model == model:
			return char
		# Ou se for um caminho (String), compare os paths
		if char.model.resource_path == model.resource_path:
			return char
	return null  
func update_player_panels():
	for i in range(GameLogic.total_players):  # ou cursors.size()
		update_player_panel(i)

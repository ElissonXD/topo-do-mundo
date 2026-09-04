extends Control

@export_category("Configurações da seleção")
@export var char_grid: GridContainer          # Grid de personagens (esquerda)
@export var skill_grid: GridContainer         # Grid de skills (direita)
@export var columns: int = 2                  # colunas do grid de personagens
@export var rows: int = 2                     # linhas do grid de personagens
@export var skill_columns: int = 4            # colunas do grid de skills
@export var skill_rows: int = 1               # linhas do grid de skills
@export var cursor_scene: PackedScene         # cena do cursor (CharacterCursor)
@export var cursor_positions: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0)]  # posições iniciais (personagem)
@export var cursor_skill_positions: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0)]  # posições iniciais (skill)
@export var player_panels: Array[Panel]       # arraste os painéis no inspetor
var characters: Array[CharacterData] = []
var skills: Array[Dictionary] = []  # recurso com ícone e nome (ou use um array de dicts)
var skill_icons: Array[Texture2D] = [preload("res://addons/at-icons/node2d/Climb.svg"), preload("res://addons/at-icons/node2d/Slide.svg"),preload("res://addons/at-icons/node2d/Dash.svg"),preload("res://addons/at-icons/node2d/Glide.svg")]         # Resource de skill (com ícone e dados)
var cursors: Array[CharacterCursor] = []

func _ready():
	load_characters()
	load_skills()
	create_char_portraits()
	create_skill_icons()
	setup_cursors()
	connect_signals()
	ensure_panel_setup()   
	update_player_panels() 
# ------------------- Carregamento de dados -------------------
func load_characters():
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
	# Ou adicione manualmente...

func load_skills():
	skills = [
		{"name": "Dash", "icon": preload("res://addons/at-icons/node2d/Dash.svg")},
		{"name": "Glide", "icon":preload("res://addons/at-icons/node2d/Glide.svg")},
		{"name": "Climb", "icon":preload("res://addons/at-icons/node2d/Climb.svg")},
		{"name": "Slide", "icon":preload("res://addons/at-icons/node2d/Slide.svg")}
		]

# ------------------- Criação de UI -------------------
func create_char_portraits():
	for child in char_grid.get_children():
		child.queue_free()
	for char in characters:
		var portrait = TextureRect.new()
		portrait.texture = char.portrait
		portrait.custom_minimum_size = Vector2(120, 120)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Shader de cor (como você já tem)
		var mat = ShaderMaterial.new()
		mat.shader = load("res://game/scenes/player/Colorswt.gdshader")
		mat.set_shader_parameter("hue_shift", 0.0)
		portrait.material = mat
		char_grid.add_child(portrait)
	char_grid.columns = columns

func create_skill_icons():
	for skill in skills:
		var icon = TextureRect.new()
		icon.texture = skill["icon"]
		icon.custom_minimum_size = Vector2(80, 80)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		skill_grid.add_child(icon)
	skill_grid.columns = skill_columns
# ------------------- Cursores -------------------
func setup_cursors():
	for i in range(GameLogic.total_players):
		var cursor = cursor_scene.instantiate() as CharacterCursor
		cursor.player_id = i + 1
		cursor.grid = char_grid
		cursor.skill_grid = skill_grid
		cursor.columns = columns
		cursor.rows = rows
		cursor.skill_columns = skill_columns   # nova variável no cursor
		cursor.skill_rows = 1                  # ou 2, dependendo do layout
		add_child(cursor)
		
		# Posições iniciais
		if i < cursor_positions.size():
			cursor.current_grid_pos = cursor_positions[i]
		else:
			cursor.current_grid_pos = Vector2i(i % columns, i / columns)
		
		cursor.current_skill_pos = Vector2i(i % skill_columns, i / skill_columns)
		cursor.set_mode(CharacterCursor.Mode.CHAR)
		
		cursors.append(cursor)
		cursor.update_cursor_position()
func connect_signals():
	for cursor in cursors:
		cursor.connect("cursor_moved", Callable(self, "_on_cursor_moved"))
		cursor.connect("skill_moved", Callable(self, "_on_skill_moved"))
		cursor.connect("mode_changed", Callable(self, "_on_mode_changed"))
		cursor.connect("confirm_pressed", Callable(self, "_on_confirm_pressed"))
		cursor.connect("cancel_pressed", Callable(self, "_on_cancel_pressed"))
		cursor.connect("costume_changed", Callable(self, "_on_costume_changed"))

# ------------------- Handlers de sinais -------------------
func _on_char_moved(player_index: int, char_index: int):
	update_player_panel(player_index)

func _on_skill_moved(player_index: int, skill_index: int):
	update_player_panel(player_index)

func _on_mode_changed(player_index: int, new_mode: int):
	# Opcional: atualizar painel ou tocar som
	pass

func _on_costume_changed(player_index: int, costume_index: int):
	update_player_panel(player_index)

func _on_confirm_pressed(player_index: int):
	var cursor = cursors[player_index]
	
	if cursor.mode == CharacterCursor.Mode.CHAR:
		# Confirmar personagem
		var index = cursor.selected_character
		var char_data = characters[index]
		if not char_data.is_unlocked:
			print("Personagem bloqueado!")
			return
		
		var model = char_data.model
		var costume = cursor.current_costume_index
		# Atualizar/Adicionar jogador com ability = -1 (ainda não escolhida)
		if player_index >= GameLogic.players_data.size():
			GameLogic.add_player(model, costume, str(player_index + 1), -1)
		else:
			var p = GameLogic.players_data[player_index]
			p["model"] = model
			p["costume_index"] = costume
			p["ability"] = -1
			p["ready"] = false
			GameLogic.update_player.emit()
		
		# Mudar para modo skill automaticamente
		cursor.set_mode(CharacterCursor.Mode.SKILL)
		
	elif cursor.mode == CharacterCursor.Mode.SKILL:
		if player_index >= GameLogic.players_data.size():
			return
		var skill_index = cursor.selected_skill
		var p = GameLogic.players_data[player_index]
		p["ability"] = skill_index   # int 0-3
		p["ready"] = true
		GameLogic.update_player.emit()
		update_player_panel(player_index)

func _on_cancel_pressed(player_index: int):
	if player_index < GameLogic.players_data.size():
		GameLogic.set_player_ready(player_index, false)
	update_player_panel(player_index)

# ------------------- Atualização dos painéis -------------------
func update_player_panel(player_index: int):
	if player_index >= player_panels.size():
		return
	var panel = player_panels[player_index]
	if not panel:
		return
	
	panel.visible = true
	
	var name_label = panel.get_node_or_null("NameLabel")
	var costume_label = panel.get_node_or_null("CostumeLabel")
	var skill_label = panel.get_node_or_null("SkillLabel")
	var ready_indicator = panel.get_node_or_null("ReadyIndicator")
	var portrait_rect = panel.get_node_or_null("PortraitRect")
	var skill_icon = panel.get_node_or_null("SkillIcon")
	
	if player_index < GameLogic.players_data.size():
		var p = GameLogic.players_data[player_index]
		var char_data = get_character_by_model(p["model"])
		
		if name_label:
			name_label.text = char_data.character_name if char_data else "?"
		if costume_label:
			costume_label.text = "Cor %d" % (p["costume_index"] + 1)
		if skill_label:
			if p["ability"] >= 0 and p["ability"] < skills.size():
				skill_label.text = "Skill: " + skills[p["ability"]]["name"]
			else:
				skill_label.text = "Escolha skill"
		if ready_indicator:
			ready_indicator.visible = p["ready"]
		
		# --- Atualizar retrato do personagem ---
		if portrait_rect and char_data:
			portrait_rect.texture = char_data.portrait
		
		# --- Atualizar ícone da skill ---
		if skill_icon:
			if p["ability"] >= 0 and p["ability"] < skills.size():
				skill_icon.texture = skills[p["ability"]]["icon"]
				skill_icon.visible = true
			else:
				skill_icon.texture = null
				skill_icon.visible = false
	else:
		# Jogador ainda não escolheu nada
		if name_label:
			name_label.text = "Aguardando..."
		if costume_label:
			costume_label.text = ""
		if skill_label:
			skill_label.text = ""
		if ready_indicator:
			ready_indicator.visible = false
		if portrait_rect:
			portrait_rect.texture = null
		if skill_icon:
			skill_icon.texture = null
			skill_icon.visible = false
func ensure_panel_setup():
	for panel in player_panels:
		if panel == null:
			continue
		
		# --- Labels existentes (manter) ---
		if not panel.has_node("NameLabel"):
			var lbl = Label.new()
			lbl.name = "NameLabel"
			lbl.position = Vector2(70, 10)
			panel.add_child(lbl)
		if not panel.has_node("CostumeLabel"):
			var lbl = Label.new()
			lbl.name = "CostumeLabel"
			lbl.position = Vector2(70, 35)
			panel.add_child(lbl)
		if not panel.has_node("SkillLabel"):
			var lbl = Label.new()
			lbl.name = "SkillLabel"
			lbl.position = Vector2(70, 60)
			panel.add_child(lbl)
		if not panel.has_node("ReadyIndicator"):
			var indicator = ColorRect.new()
			indicator.name = "ReadyIndicator"
			indicator.size = Vector2(20, 20)
			indicator.color = Color.GREEN
			indicator.position = Vector2(250, 15)
			indicator.visible = false
			panel.add_child(indicator)
		
		# --- ADICIONAR TextureRect para o retrato do personagem ---
		if not panel.has_node("PortraitRect"):
			var portrait_rect = TextureRect.new()
			portrait_rect.name = "PortraitRect"
			portrait_rect.position = Vector2(5, 5)
			portrait_rect.size = Vector2(55, 55)  # ajuste conforme necessário
			portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			panel.add_child(portrait_rect)
		
		# --- ADICIONAR TextureRect para o ícone da skill ---
		if not panel.has_node("SkillIcon"):
			var skill_icon = TextureRect.new()
			skill_icon.name = "SkillIcon"
			skill_icon.position = Vector2(5, 65)
			skill_icon.size = Vector2(40, 40)
			skill_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			panel.add_child(skill_icon)
		
		# Garantir que o painel tenha um fundo e tamanho
		panel.custom_minimum_size = Vector2(280, 110)  # aumente a altura para caber as imagens
		panel.visible = true
		if panel.get_theme_stylebox("panel") == null:
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0.6)
			style.border_color = Color.WHITE
			style.set_border_width_all(2)
			panel.add_theme_stylebox_override("panel", style)
func update_player_panels():
	for i in range(GameLogic.total_players):
		update_player_panel(i)

func get_character_by_model(model: PackedScene) -> CharacterData:
	for char in characters:
		if char.model == model:
			return char
	return null

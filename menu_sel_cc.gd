# menu_sel_cc.gd
extends Control

signal selection_finished(players: Array[Dictionary])

enum Stage { CHAR, SKILL, READY }

const MAX_PLAYERS := 4
const COSTUME_COUNT := 6
const JOIN_ACTION := "use_ability"     # mesma ação de confirmar do cursor
const START_DELAY := 3         # segundos após todos ficarem prontos
const PLAYER_COLORS := [Color.RED, Color.DODGER_BLUE, Color.LIME_GREEN, Color.YELLOW]

@export var characters: Array[CharacterData] = []
@export var skill_icons: Array[Texture2D] = []
@export var skill_names: Array[String] = []
@export var slot_scene: PackedScene
@export var cursor_scene: PackedScene
@export var costume_shader: Shader     # troca_cor.gdshader

@onready var char_grid: GridContainer = %CharGrid
@onready var skill_grid: GridContainer = %SkillGrid
@onready var panels_container: HBoxContainer = %PlayerPanels
@onready var cursors_layer: Control = %Cursors
@onready var ready_label: Label = $ready
var start_timer: float = -1.0


var slots: Array[CharacterSlot] = []
var panels: Array[Dictionary] = []
# p (0..3) -> { cursor, stage, character, skill, costume }
var players := {}
var _countdown_id := 0


func _ready() -> void:
	
	for c in characters:
		var slot: CharacterSlot = slot_scene.instantiate()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		char_grid.add_child(slot)
		slot.setup(c)
		slots.append(slot)

	for i in skill_icons.size():
		var tex = skill_icons[i]
		
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(48, 48)
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)
		
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = skill_names[i]
		box.add_child(label)
		
		
		
		skill_grid.add_child(box)

	for p in MAX_PLAYERS:
		_build_panel(p)
		_refresh_panel(p)

# ---------- Processamento ----------

func _process(_delta: float) -> void:
	var blink_alpha = (sin(Time.get_ticks_msec() * 0.005) * 0.4) + 0.6 
	
	for p in MAX_PLAYERS:
		if panels[p].status.text in ['Pronto!', 'Aperte para entrar']:
			panels[p].status.modulate.a = blink_alpha
		else:
			panels[p].status.modulate.a = 1.0
	
	if start_timer > 0:
		start_timer -= _delta
		ready_label.text = "Iniciando em " + str(int(ceil(start_timer))) + '...' 
		
		if start_timer <= 0:
			start_timer = -1.0
			_finish()

# ---------- Entrada de jogadores ----------

func _unhandled_input(event: InputEvent) -> void:
	for p in MAX_PLAYERS:
		if not players.has(p) and event.is_action_pressed("%s_%d" % [JOIN_ACTION, p + 1]):
			_join(p)
			get_viewport().set_input_as_handled()
			return


func _join(p: int) -> void:
	var cursor := cursor_scene.instantiate() as CharacterCursor
	cursor.player_id = p + 1
	cursor.grid = char_grid
	cursor.skill_grid = skill_grid
	cursor.costume_count = COSTUME_COUNT
	cursor.active = false              # ignora o mesmo aperto que fez o jogador entrar
	cursor.modulate = PLAYER_COLORS[p]
	cursors_layer.add_child(cursor)

	cursor.cursor_moved.connect(_on_cursor_moved)
	cursor.skill_moved.connect(_on_skill_moved)
	cursor.confirm_pressed.connect(_on_confirm)
	cursor.cancel_pressed.connect(_on_cancel)
	cursor.costume_changed.connect(_on_costume_changed)

	players[p] = { "cursor": cursor, "stage": Stage.CHAR, "character": 0, "skill": 0, "costume": 0 }
	_countdown_id += 1
	slots[0].set_hover(p, true)
	_resolve_costume(p)
	_refresh_panel(p)

	await get_tree().process_frame     # espera o layout dos containers
	if is_instance_valid(cursor):
		cursor.update_position(false)
		cursor.active = true


func _leave(p: int) -> void:
	var st: Dictionary = players[p]
	slots[st.character].set_hover(p, false)
	st.cursor.queue_free()
	players.erase(p)
	_refresh_panel(p)


# ---------- Sinais do cursor ----------

func _on_cursor_moved(p: int, idx: int) -> void:
	var st: Dictionary = players[p]
	slots[st.character].set_hover(p, false)
	st.character = idx
	slots[idx].set_hover(p, true)
	_resolve_costume(p)
	_refresh_panel(p)


func _on_skill_moved(p: int, idx: int) -> void:
	players[p].skill = idx
	_refresh_panel(p)


func _on_costume_changed(p: int, idx: int) -> void:
	players[p].costume = idx
	_resolve_costume(p)
	_refresh_panel(p)


func _on_confirm(p: int) -> void:
	var st: Dictionary = players[p]
	match st.stage:
		Stage.CHAR:
			if _is_taken(st.character, p):
				return
			st.stage = Stage.SKILL
			st.cursor.set_mode(CharacterCursor.Mode.SKILL)
		Stage.SKILL:
			st.stage = Stage.READY
			st.cursor.locked = true
	_refresh_taken()
	_refresh_panel(p)
	_check_all_ready()


func _on_cancel(p: int) -> void:
	start_timer = -1.0
	ready_label.visible = false
	var st: Dictionary = players[p]
	_countdown_id += 1                 # cancela a contagem de início
	match st.stage:
		Stage.READY:
			st.stage = Stage.SKILL
			st.cursor.locked = false
		Stage.SKILL:
			st.stage = Stage.CHAR
			st.cursor.set_mode(CharacterCursor.Mode.CHAR)
		Stage.CHAR:
			_leave(p)
	_refresh_taken()
	_refresh_panel(p)


# ---------- Regras ----------

func _is_taken(idx: int, except: int) -> bool:
	for q in players:
		if q != except and players[q].stage != Stage.CHAR and players[q].character == idx:
			return true
	return false


func _costume_in_use(except: int, character: int, costume: int) -> bool:
	for q in players:
		if q != except and players[q].character == character and players[q].costume == costume:
			return true
	return false


# Evita dois jogadores com o mesmo personagem na mesma cor
func _resolve_costume(p: int) -> void:
	var st: Dictionary = players[p]
	for i in COSTUME_COUNT:
		if not _costume_in_use(p, st.character, st.costume):
			break
		st.costume = (st.costume + 1) % COSTUME_COUNT
	st.cursor.current_costume_index = st.costume


func _check_all_ready() -> void:
	if len(players) < 2:
		return
	for p in players:
		if players[p].stage != Stage.READY:
			return
	
	_countdown_id += 1
	var id := _countdown_id
	ready_label.visible = true
	start_timer = START_DELAY


func _finish() -> void:
	var result: Array[Dictionary] = []
	var ids := players.keys()
	ids.sort()
	for p in ids:
		var st: Dictionary = players[p]
		var c: CharacterData = characters[st.character]
		GameLogic.players_data.append({
			"id": p + 1,
			"model": c.scene_path,
			"costume_index": st.costume,
			"portrait": c.portrait,
			"controls": str(p + 1),
			"ability": st.skill,
			"score": 0
		})
	selection_finished.emit(result)
	get_tree().change_scene_to_file("res://game/scenes/test/test_2 da camera.tscn")


# ---------- Visual ----------

func _refresh_taken() -> void:
	for i in slots.size():
		slots[i].modulate = Color(0.45, 0.45, 0.45) if _is_taken(i, -1) else Color.WHITE


func _build_panel(p: int) -> void:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 30)
	box.add_child(v)

	var title := Label.new()
	title.text = "P%d" % (p + 1)
	title.modulate = PLAYER_COLORS[p]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var portrait := TextureRect.new()
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var mat := ShaderMaterial.new()
	mat.shader = costume_shader
	portrait.material = mat
	v.add_child(portrait)
	
	var char_name := Label.new()
	char_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(char_name)

	var skill := TextureRect.new()
	skill.custom_minimum_size = Vector2(48, 48)
	skill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skill.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(skill)
	
	var skill_label := Label.new()
	skill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skill_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(skill_label)

	var status := Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(100, 40)
	v.add_child(status)

	panels_container.add_child(box)
	panels.append({ "portrait": portrait, "char_name": char_name, "skill": skill, "skill_label": skill_label, "status": status, "material": mat })


func _refresh_panel(p: int) -> void:
	var panel: Dictionary = panels[p]
	if not players.has(p):
		panel.portrait.texture = null
		panel.skill.texture = null
		panel.skill_label.text = ''
		panel.char_name.text = ''
		panel.status.text = "Aperte para entrar"
		return

	var st: Dictionary = players[p]
	panel.portrait.texture = characters[st.character].portrait
	panel.material.set_shader_parameter("hue_shift", float(st.costume) / COSTUME_COUNT)
	panel.char_name.text = characters[st.character].character_name
	
	if st.stage != Stage.CHAR and st.skill < skill_icons.size():
		panel.skill.texture = skill_icons[st.skill]
		panel.skill_label.text = skill_names[st.skill]
	else:
		panel.skill.texture = null
		panel.skill_label.text = ''

	match st.stage:
		Stage.CHAR:
			panel.status.text = "Escolha o personagem"
		Stage.SKILL:
			panel.status.text = "Escolha a habilidade"
		Stage.READY:
			panel.status.text = "Pronto!"

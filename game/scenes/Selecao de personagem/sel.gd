extends Control
# character_select.gd

@export var grid: GridContainer
@export var columns: int = 4
@export var rows: int = 3

# Dados dos personagens (carregue da pasta ou pré-defina)
var characters: Array[CharacterData] = []
var cursors: Array = []  # referências aos cursores

# Jogadores
var players = [
	{"cursor": null, "state": "choosing", "character": -1, "grid_pos": Vector2i.ZERO},
	{"cursor": null, "state": "choosing", "character": -1, "grid_pos": Vector2i.ZERO},
]

func _ready():
	load_characters()
	setup_cursors()
	for i in range(cursors.size()):
		cursors[i].connect("confirm_pressed", Callable(self, "_on_confirm_pressed").bind(i))
		cursors[i].connect("cancel_pressed", Callable(self, "_on_cancel_pressed").bind(i))

func load_characters():
	# Carregue seus recursos manualmente ou através de um loop
	# Exemplo:
	#characters.append(load("res://characters/mario.tres"))
	#characters.append(load("res://characters/link.tres"))
	# ...
	characters.append("res://game/scenes/player/fdp.tscn")
	characters.append("res://game/scenes/player/Pero.tscn")
	pass
func setup_cursors():
	# Cria os cursores e associa aos jogadores
	players[0].cursor = $Cursores/P1
	players[1].cursor = $Cursores/P2
	players[2].cursor = $Cursores/P3
	players[3].cursor = $Cursores/P4
	# Define posições iniciais
	players[0].cursor.current_grid_pos = Vector2i.ZERO
	players[1].cursor.current_grid_pos = Vector2i(1, 0)
	players[0].cursor.update_cursor_position()
	players[1].cursor.update_cursor_position()
	# Conecta sinais para atualizar UI quando o cursor mover
	players[0].cursor.connect("cursor_moved", Callable(self, "_on_cursor_moved").bind(0))
	players[1].cursor.connect("cursor_moved", Callable(self, "_on_cursor_moved").bind(1))

func _on_confirm_pressed(player_index: int):
	var cursor = cursors[player_index]
	if cursor.is_locked:
		return
	cursor.is_locked = true
	var char_data = characters[cursor.selected_character]
	var costume_index = cursor.current_costume_index  # você precisa implementar a troca de costume no cursor
	# Adicionar ou atualizar jogador no game_logic
	if player_index >= GameLogic.players_data.size():
		GameLogic.add_player(char_data.model, costume_index, str(player_index+1))
	else:
		# Atualizar dados se necessário
		GameLogic.players_data[player_index]["model"] = char_data.model
		GameLogic.players_data[player_index]["costume_index"] = costume_index
		GameLogic.players_data[player_index]["control_schema"] = str(player_index+1)
		GameLogic.set_player_ready(player_index, true)
		# Atualizar painel para mostrar "Pronto"
	update_ui()

func _on_cancel_pressed(player_index: int):
	var cursor = cursors[player_index]
	cursor.is_locked = false
	if player_index < GameLogic.players_data.size():
		GameLogic.set_player_ready(player_index, false)
	update_ui()

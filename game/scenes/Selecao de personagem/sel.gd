extends Control
# character_select.gd

@export var grid: GridContainer
@export var columns: int = 4
@export var rows: int = 3

# Dados dos personagens (carregue da pasta ou pré-defina)
var characters: Array[CharacterData] = []

# Jogadores
var players = [
	{"cursor": null, "state": "choosing", "character": -1, "grid_pos": Vector2i.ZERO},
	{"cursor": null, "state": "choosing", "character": -1, "grid_pos": Vector2i.ZERO},
]

func _ready():
	load_characters()
	setup_cursors()
	update_ui()

func load_characters():
	# Carregue seus recursos manualmente ou através de um loop
	# Exemplo:
	#characters.append(load("res://characters/mario.tres"))
	#characters.append(load("res://characters/link.tres"))
	# ...

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

extends Camera2D

@export var players_parent: NodePath  # caminho para o nó que contém os jogadores
@export var margin: Vector2 = Vector2(100, 80)  # margem extra em pixeis
@export var min_zoom: float = 0.5   # zoom máximo (muito afastado)
@export var max_zoom: float = 2.0   # zoom mínimo (muito aproximado)
@export var smooth_factor: float = 5.0  # suavidade (mais alto = mais rápido)
@export var lookahead_factor: float = 0.3  # influência da velocidade
@export var maximum_margin: float = 30
var warning_object : Node2D

var players: Array = []
var target_zoom: float = 1.0

func _ready():
	# Obter referências para os jogadores
	if players_parent:
		var parent = get_node(players_parent)
		for child in parent.get_children():
			if child.has_method("is_alive"):  # Assumindo um método que verifica se está vivo
				players.append(child)
	# Definir limites da câmara (opcional)
	#set_limit(MARGIN_LEFT, limit_left)
	#set_limit(MARGIN_RIGHT, limit_right)
	#set_limit(MARGIN_TOP, limit_top)
	#set_limit(MARGIN_BOTTOM, limit_bottom)
	# Tornar a câmara atual
	
	warning_object = load("res://game/scenes/entities/warning/warning.tscn").instantiate()
	warning_object.visible = false
	$"../Entities".add_child(warning_object)
	
	make_current()

func _process(delta):
	if players.is_empty() and players_parent:
		var parent = get_node_or_null(players_parent)
		if parent:
			for child in parent.get_children():
				if child.has_method("is_alive"):
					players.append(child)
	update_camera(delta)

func update_camera(delta):
	# Filtrar jogadores vivos
	var alive = []
	for p in players:
		if p.has_method("is_alive") and p.is_alive():
			alive.append(p)
	
	if alive.is_empty():
		return
	
	# 1. Calcular centro médio (e antecipação)
	var center = Vector2.ZERO
	var avg_velocity = Vector2.ZERO
	for p in alive:
		center += p.global_position
		# Se o jogador tiver uma propriedade 'velocity', adiciona-a
		if "velocity" in p:
			avg_velocity += p.velocity
	center /= alive.size()
	avg_velocity /= alive.size()
	
	# Ponto de destino com antecipação
	var target_pos = center + avg_velocity * lookahead_factor
	
	# 2. Calcular zoom com base nas distâncias extremas
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for p in alive:
		var pos = p.global_position
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
	
	# Tamanho do enquadramento (inclui margem)
	var width = (max_x - min_x) + margin.x * 2
	var height = (max_y - min_y) + margin.y * 2
	
	# Zoom necessário para caber tudo no ecrã
	var viewport_size = get_viewport_rect().size
	var zoom_x = viewport_size.x / width if width > 0 else max_zoom
	var zoom_y = viewport_size.y / height if height > 0 else max_zoom
	
	# Usar o menor zoom (para garantir que ambos os eixos cabem) e limitar
	target_zoom = min(zoom_x, zoom_y)
	target_zoom = clamp(target_zoom, min_zoom, max_zoom)
	
	# 3. Aplicar suavização
	global_position = global_position.lerp(target_pos, smooth_factor * delta)
	zoom = zoom.lerp(Vector2.ONE * target_zoom, smooth_factor * delta)
	
	# 4. A câmara já respeita os limites definidos com set_limit()
	
	#5. Verificar se o jogador caiu o suficiente para morrer
	player_is_onbound(alive, viewport_size)
	
func player_is_onbound(alive: Array, viewport: Vector2) -> void:
	var canvas_transform = get_canvas_transform()
	
	var lowest_player = null
	var max_y = -INF
	
	for p in alive:
		var screen_pos = canvas_transform * p.global_position
		
		
		if screen_pos.y > viewport.y + maximum_margin:
			p.die()
		


		if p.global_position.y > max_y:
			max_y = p.global_position.y
			lowest_player = p

		var show_warning = lowest_player != null and zoom.y < min_zoom + 0.5
		warning_object.visible = show_warning

		if show_warning:
			warning_object.global_position = lowest_player.global_position + Vector2(0, -40)

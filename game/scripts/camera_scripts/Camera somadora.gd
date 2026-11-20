extends Camera2D

@export var players_parent: NodePath
@export var margin: Vector2 = Vector2(100, 120) # margin.y define a distância mínima do líder até o topo
@export var max_zoom: float = 2.0               # limite máximo de aproximação (zoom in)
@export var smooth_factor: float = 5.0
@export var lookahead_factor: float = 0.3
@export var maximum_margin_per_player: float = 30.0
@export_range(0.0, 1.0) var min_leader_influence: float = 0.6
@export_range(0.0, 1.0) var max_leader_influence: float = 1
@export var zoom_for_max_influence: float = 1

var maximum_margin: float
var warning_object: Node2D

# shake
var randomStrengh: float
var shakeFade: float

var players: Array = []
var target_zoom: float = 1.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if players_parent:
		var parent = get_node(players_parent)
		for child in parent.get_children():
			if child.has_method("is_alive"):
				players.append(child)
	
	warning_object = load("res://game/scenes/entities/warning.tscn").instantiate()
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
	
	if randomStrengh > 0:
		randomStrengh = lerpf(randomStrengh, 0, shakeFade * delta)
		var rng = RandomNumberGenerator.new()
		offset = Vector2(rng.randf_range(-randomStrengh, randomStrengh), rng.randf_range(-randomStrengh, randomStrengh))

func update_camera(delta):
	var alive = []
	for p in players:
		if p.has_method("is_alive") and p.is_alive():
			alive.append(p)
	
	maximum_margin = alive.size() * maximum_margin_per_player
	
	if alive.is_empty():
		return
	
	# 1. Calcular centro médio e extremos
	var center = Vector2.ZERO
	var avg_velocity = Vector2.ZERO
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for p in alive:
		var pos = p.global_position
		center += pos
		if "velocity" in p:
			avg_velocity += p.velocity
		
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
		
	center /= alive.size()
	avg_velocity /= alive.size()
	
	var viewport_size = get_viewport_rect().size
	
	# 2. Zoom calculado APENAS pelo eixo X (sem limite de afastamento)
	var width = (max_x - min_x) + margin.x * 3
	var zoom_x = viewport_size.x / width if width > 0 else max_zoom
	target_zoom = min(zoom_x, max_zoom)
	
	# 3. Posição alvo com antecipação
	var target_pos = center + avg_velocity * lookahead_factor
	
	# 4. Posição vertical forçada pelo jogador mais alto (min_y)
	# Altura real visível na tela considerando o zoom atual
	var zoom_weight = inverse_lerp(max_zoom, zoom_for_max_influence, target_zoom)
	zoom_weight = clamp(zoom_weight, 0.0, 1.0)
	
	var dynamic_influence = lerpf(min_leader_influence, max_leader_influence, zoom_weight)
	
	# Posição ideal focada no topo (líder) vs. centro do grupo
	var visible_height = viewport_size.y / target_zoom
	var leader_focus_y = min_y + (visible_height * 0.5) - margin.y
	
	# Puxa continuamente o Y do grupo em direção ao líder conforme o zoom afasta
	var blended_y = lerpf(target_pos.y, leader_focus_y, dynamic_influence)
	
	# Garante que a câmera sempre suba se o líder ainda estiver ameaçando sair pelo topo
	target_pos.y = min(target_pos.y, blended_y)
	
	# 5. Aplicar suavização
	global_position = global_position.lerp(target_pos, smooth_factor * delta)
	zoom = zoom.lerp(Vector2.ONE * target_zoom, smooth_factor * delta)
	
	# 6. Verificar queda na borda inferior
	player_is_onbound(alive, viewport_size, min_y, max_y)

func player_is_onbound(alive: Array, viewport: Vector2, min_y: float, max_y: float) -> void:
	var canvas_transform = get_canvas_transform()
	
	var lowest_player = null
	for p in alive:
		if p.global_position.y == max_y:
			lowest_player = p
			break

	# Verifica se os jogadores estão separados mais do que a altura visível da tela
	var visible_height = viewport.y / zoom.y
	var is_danger_spread = (max_y - min_y) > (visible_height * 0.75)

	for p in alive:
		var screen_pos = canvas_transform * p.global_position
		# Elimina qualquer jogador que ultrapassar a borda inferior + margem
		if screen_pos.y > viewport.y + maximum_margin:
			p.die()

	var show_warning = lowest_player != null and is_danger_spread
	warning_object.visible = show_warning

	if show_warning:
		warning_object.global_position = lowest_player.global_position + Vector2(0, -40)

func shake_camera(randomS: float, shakeF: float):
	randomStrengh = randomS
	shakeFade = shakeF

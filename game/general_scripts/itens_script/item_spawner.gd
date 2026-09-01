# item_spawner.gd
extends Node
 
@export_category('Configurações de spawn')
 
## Lista de itens possíveis, cada um com sua cena e peso (ItemSpawnData resources)
@export var possible_items: Array[ItemSpawnData] = []
 
## Chance de UM item spawnar a cada tick (0.0 a 1.0). Ex: 0.15 = 15% por segundo
@export_range(0.0, 1.0, 0.01) var spawn_chance_per_tick: float = 0.15
 
## De quanto em quanto tempo (segundos) o spawner tenta um spawn
@export var tick_interval: float = 1.0
 
## Máximo de itens vivos no mapa ao mesmo tempo (0 = sem limite)
@export var max_items_alive: int = 6
 
var _tick_timer: Timer
var _items_alive: Array[Node] = []
var _spawn_points: Array[Node] = []
 
 
func _ready() -> void:
	# mesmo padrão do round_manager: pega os pontos marcados por grupo
	_spawn_points = get_tree().get_nodes_in_group('ItemSpawn')
 
	if _spawn_points.is_empty():
		push_warning("ItemSpawner: nenhum ponto encontrado no grupo 'ItemSpawn'.")
 
	_tick_timer = Timer.new()
	_tick_timer.wait_time = tick_interval
	_tick_timer.one_shot = false
	add_child(_tick_timer)
	_tick_timer.timeout.connect(_on_tick)
	_tick_timer.start()
 
 
func _on_tick() -> void:
	# não faz nada se não tem onde spawnar ou itens configurados
	if _spawn_points.is_empty() or possible_items.is_empty():
		return
 
	# limpa referências de itens que já foram destruídos/coletados
	_items_alive = _items_alive.filter(func(item): return is_instance_valid(item))
 
	if max_items_alive > 0 and _items_alive.size() >= max_items_alive:
		return
 
	# 1º sorteio: será que spawna algo nesse tick?
	if randf() > spawn_chance_per_tick:
		return
 
	# 2º sorteio: qual item, ponderado pelo weight de cada um
	var chosen_data := _pick_weighted_item()
	if chosen_data == null or chosen_data.item_scene == null:
		return
 
	# 3º sorteio: em qual plataforma/ponto
	var chosen_point: Node = _spawn_points[randi() % _spawn_points.size()]
 
	_spawn_item(chosen_data, chosen_point)
 
 
func _pick_weighted_item() -> ItemSpawnData:
	var total_weight := 0.0
	for data in possible_items:
		total_weight += data.weight
 
	if total_weight <= 0.0:
		return null
 
	var roll := randf() * total_weight
	var acumulado := 0.0
 
	for data in possible_items:
		acumulado += data.weight
		if roll <= acumulado:
			return data
 
	# fallback de segurança (não deveria chegar aqui)
	return possible_items[possible_items.size() - 1]
 
 
func _spawn_item(data: ItemSpawnData, point: Node) -> void:
	var item := data.item_scene.instantiate()
	get_tree().current_scene.add_child(item)
	item.global_position = point.global_position
 
	# entrega o próprio resource pro item, pra ele saber quem ele é
	# quando o player interagir e pegá-lo
	if item is ItemBase:
		item.spawn_data = data
	else:
		push_warning("ItemSpawner: a cena '%s' não tem o script item_base.gd (ItemBase) na raiz." % data.item_scene.resource_path)
 
	_items_alive.append(item)

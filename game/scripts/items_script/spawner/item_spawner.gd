extends Node2D
# acho que apagar esse codigo foi um erro mas vou tentar o maximo pra 
# nao fuder tudo

"""
- vai receber item_spawn_data
- tempo de cooldown para respawnar 1 item
- pode spawnar qualquer item com base no cooldown
- seria legal ter um sprite
"""

@export_category("Configurações")
@export var ITEMS : Array[ItemSpawnEntry] # tem spawn rate e o item
var current_item : ItemSpawnData = null
@export var COOLDOWN : float
@export var TIMER : Timer
@onready var item_sprite: AnimatedSprite2D = $item_sprite
var can_pick : bool = false
var rng : RandomNumberGenerator


func _ready() -> void:
	TIMER.start(COOLDOWN)
	rng = RandomNumberGenerator.new()

func _process(delta: float) -> void:
	#acho que é pra fazer nada, o timer já faz as coisas
	return


func _on_hitbox_body_entered(body: Node2D) -> void:
	body = body as PlayerModel # a mask faz ele colidir só com o player
	if can_pick and body.current_item == null:
		can_pick = false
		TIMER.start(COOLDOWN)
		body.current_item = current_item
		body.emit_signal('get_item', current_item.texture)
		
		item_sprite.sprite_frames = null
		current_item = null
	
		return

func _on_cooldown_timeout() -> void:
	can_pick = true
	var weights : Array[float] = []
	var items : Array[ItemSpawnData] = []
	
	for x in ITEMS:
		weights.append(x.weight)
		items.append(x.item)
	
	current_item = items[rng.rand_weighted(weights)]
	item_sprite.sprite_frames = current_item.item_sprite
	item_sprite.scale = current_item.scale
	return

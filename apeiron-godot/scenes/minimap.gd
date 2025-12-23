extends Control

@export var minimap_size: Vector2 = Vector2(200, 200)
@export var world_scale: float = 0.05  # Escala del mundo en el minimapa
@export var player_color: Color = Color(0, 1, 0)
@export var enemy_color: Color = Color(1, 0, 0)
@export var player_size: float = 6.0
@export var enemy_size: float = 4.0
@export var background_color: Color = Color(0, 0, 0, 0.7)
@export var border_color: Color = Color(0.3, 0.3, 0.3, 1.0)
@export var border_width: float = 2.0

var player: Node2D = null

func _ready():
	custom_minimum_size = minimap_size
	size = minimap_size
	
	# Posicionar en esquina superior derecha
	position = Vector2(
		get_viewport().get_visible_rect().size.x - minimap_size.x - 20,
		20
	)
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _draw():
	# Fondo
	draw_rect(Rect2(Vector2.ZERO, minimap_size), background_color)
	
	# Borde
	draw_rect(Rect2(Vector2.ZERO, minimap_size), border_color, false, border_width)
	
	if not player or not is_instance_valid(player):
		return
	
	var center = minimap_size / 2
	
	# Dibujar enemigos
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var relative_pos = (enemy.global_position - player.global_position) * world_scale
		var minimap_pos = center + relative_pos
		
		# Solo dibujar si está dentro del minimapa
		if (minimap_pos.x >= 0 and minimap_pos.x <= minimap_size.x and
			minimap_pos.y >= 0 and minimap_pos.y <= minimap_size.y):
			draw_circle(minimap_pos, enemy_size, enemy_color)
	
	# Dibujar jugador (siempre en el centro)
	draw_circle(center, player_size, player_color)
	
	# Dibujar dirección del jugador
	var player_direction = Vector2.RIGHT.rotated(player.rotation)
	draw_line(center, center + player_direction * 15, player_color, 2.0)

func _process(_delta):
	queue_redraw()

func world_to_minimap(world_pos: Vector2) -> Vector2:
	if not player:
		return Vector2.ZERO
	
	var center = minimap_size / 2
	var relative_pos = (world_pos - player.global_position) * world_scale
	return center + relative_pos

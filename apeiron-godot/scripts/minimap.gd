extends Control

@export var minimap_size: Vector2 = Vector2(200, 200)
@export var world_scale: float = 0.05  # Escala base del mundo
@export var zoom_multiplier: float = 0.3  # Multiplicador para aumentar el alcance con el zoom
@export var player_color: Color = Color(0.2, 0.9, 1.0)
@export var enemy_color: Color = Color(1, 0.2, 0.2)
@export var objective_color: Color = Color(0.3, 1.0, 0.5)
@export var player_size: float = 8.0
@export var enemy_size: float = 4.0
@export var background_color: Color = Color(0, 0, 0, 0.75)
@export var border_color: Color = Color(0.3, 0.6, 1.0, 0.8)
@export var border_width: float = 2.0

var player: Node2D = null
var camera: Camera2D = null

func _ready() -> void:
	custom_minimum_size = minimap_size
	size = minimap_size
	position = Vector2(
		get_viewport().get_visible_rect().size.x - minimap_size.x - 20,
		30
	)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera2D"):
		camera = player.get_node("Camera2D")

func _draw() -> void:
	# Fondo con bordes redondeados
	draw_rect(Rect2(Vector2.ZERO, minimap_size), background_color)
	draw_rect(Rect2(Vector2.ZERO, minimap_size), border_color, false, border_width)

	# Cruz de referencia tenue
	var center: Vector2 = minimap_size / 2.0
	draw_line(Vector2(center.x, 0), Vector2(center.x, minimap_size.y), Color(1,1,1,0.04), 1.0)
	draw_line(Vector2(0, center.y), Vector2(minimap_size.x, center.y), Color(1,1,1,0.04), 1.0)

	if not player or not is_instance_valid(player):
		return

	# Calcular escala efectiva del minimapa según el zoom de la cámara
	var effective_scale: float = _calculate_effective_scale()

	# Enemigos
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var relative_pos: Vector2 = (enemy.global_position - player.global_position) * effective_scale
		var map_pos: Vector2 = center + relative_pos
		if Rect2(Vector2.ZERO, minimap_size).has_point(map_pos):
			draw_circle(map_pos, enemy_size, enemy_color)
			# Borde más oscuro
			draw_arc(map_pos, enemy_size, 0.0, TAU, 8, Color(0.6, 0.1, 0.1), 1.0, true)

	# Objetivo
	for obj in get_tree().get_nodes_in_group("objective"):
		if not is_instance_valid(obj):
			continue
		var relative_pos: Vector2 = (obj.global_position - player.global_position) * effective_scale
		var map_pos: Vector2 = center + relative_pos

		# Si está fuera del minimapa, dibujar flecha en el borde
		if not Rect2(Vector2.ZERO, minimap_size).has_point(map_pos):
			var direction: Vector2 = (map_pos - center).normalized()
			var edge_pos: Vector2 = _clamp_to_minimap(center, direction)
			_draw_objective_arrow(edge_pos, direction)
		else:
			_draw_objective_diamond(map_pos)

	# Nave del jugador — forma de nave personalizada
	_draw_player_ship(center)

func _calculate_effective_scale() -> float:
	var base_scale: float = world_scale
	
	if camera and camera.has_method("get_current_zoom"):
		var zoom_factor: float = camera.get_current_zoom()
		# Cuando la cámara hace zoom out (zoom_factor es menor), 
		# el minimapa muestra MUCHO más área
		# zoom_multiplier = 3.0 significa 3x más alcance por cada nivel de zoom
		base_scale = world_scale * (zoom_factor / 0.2) * zoom_multiplier
	
	return base_scale

func _draw_player_ship(pos: Vector2) -> void:
	var angle: float = player.rotation
	var forward: Vector2 = Vector2.RIGHT.rotated(angle)
	var right: Vector2 = Vector2.DOWN.rotated(angle)

	# Cuerpo principal (triángulo apuntando hacia adelante)
	var tip: Vector2   = pos + forward * 10.0
	var left: Vector2  = pos - forward * 6.0 + right * 6.0
	var right_pt: Vector2 = pos - forward * 6.0 - right * 6.0

	draw_colored_polygon(PackedVector2Array([tip, left, right_pt]), player_color)

	# Alas traseras
	var wing_l1: Vector2 = pos - forward * 4.0 + right * 6.0
	var wing_l2: Vector2 = pos - forward * 10.0 + right * 9.0
	var wing_l3: Vector2 = pos - forward * 8.0 + right * 3.0
	draw_colored_polygon(PackedVector2Array([wing_l1, wing_l2, wing_l3]), player_color.darkened(0.2))

	var wing_r1: Vector2 = pos - forward * 4.0 - right * 6.0
	var wing_r2: Vector2 = pos - forward * 10.0 - right * 9.0
	var wing_r3: Vector2 = pos - forward * 8.0 - right * 3.0
	draw_colored_polygon(PackedVector2Array([wing_r1, wing_r2, wing_r3]), player_color.darkened(0.2))

	# Núcleo brillante
	draw_circle(pos, 2.5, Color(1, 1, 1, 0.9))

func _draw_objective_diamond(pos: Vector2) -> void:
	var s: float = 7.0
	var pulse: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)
	var col: Color = Color(objective_color.r, objective_color.g, objective_color.b, pulse)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -s),
		pos + Vector2(s, 0),
		pos + Vector2(0, s),
		pos + Vector2(-s, 0)
	]), col)
	draw_polyline(PackedVector2Array([
		pos + Vector2(0, -s),
		pos + Vector2(s, 0),
		pos + Vector2(0, s),
		pos + Vector2(-s, 0),
		pos + Vector2(0, -s)
	]), Color(1,1,1,0.5 * pulse), 1.0, true)

func _draw_objective_arrow(edge: Vector2, dir: Vector2) -> void:
	var pulse: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)
	var col: Color = Color(objective_color.r, objective_color.g, objective_color.b, pulse)
	var perp: Vector2 = dir.rotated(PI / 2.0)
	var a: Vector2 = edge + dir * 8.0
	var b: Vector2 = edge - dir * 4.0 + perp * 5.0
	var c: Vector2 = edge - dir * 4.0 - perp * 5.0
	draw_colored_polygon(PackedVector2Array([a, b, c]), col)

func _clamp_to_minimap(center: Vector2, dir: Vector2) -> Vector2:
	var margin: float = 12.0
	var half: Vector2 = minimap_size / 2.0 - Vector2(margin, margin)
	var t_x: float = half.x / max(abs(dir.x), 0.001)
	var t_y: float = half.y / max(abs(dir.y), 0.001)
	var t: float = min(t_x, t_y)
	return center + dir * t

func _process(_delta: float) -> void:
	queue_redraw()

func world_to_minimap(world_pos: Vector2) -> Vector2:
	if not player:
		return Vector2.ZERO
	
	var effective_scale: float = _calculate_effective_scale()
	return minimap_size / 2.0 + (world_pos - player.global_position) * effective_scale

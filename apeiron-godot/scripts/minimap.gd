extends Control

@export var minimap_size: Vector2 = Vector2(200, 200)
@export var world_scale: float = 0.05
@export var player_color: Color = Color(0.2, 0.9, 1.0)
@export var enemy_color: Color = Color(1, 0.2, 0.2)
@export var objective_color: Color = Color(0.3, 1.0, 0.5)
@export var player_size: float = 8.0
@export var enemy_size: float = 4.0
@export var background_color: Color = Color(0, 0, 0, 0.75)
@export var border_color: Color = Color(0.3, 0.6, 1.0, 0.8)
@export var border_width: float = 2.0

var player: Node2D = null

func _ready():
	custom_minimum_size = minimap_size
	size = minimap_size
	position = Vector2(
		get_viewport().get_visible_rect().size.x - minimap_size.x - 20,
		30
	)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _draw():
	# Fondo con bordes redondeados simulados
	draw_rect(Rect2(Vector2.ZERO, minimap_size), background_color)
	draw_rect(Rect2(Vector2.ZERO, minimap_size), border_color, false, border_width)

	# Cruz de referencia tenue
	var center = minimap_size / 2
	draw_line(Vector2(center.x, 0), Vector2(center.x, minimap_size.y), Color(1,1,1,0.04), 1)
	draw_line(Vector2(0, center.y), Vector2(minimap_size.x, center.y), Color(1,1,1,0.04), 1)

	if not player or not is_instance_valid(player):
		return

	# Enemigos
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var rel = (enemy.global_position - player.global_position) * world_scale
		var mpos = center + rel
		if Rect2(Vector2.ZERO, minimap_size).has_point(mpos):
			draw_circle(mpos, enemy_size, enemy_color)
			# Borde más oscuro
			draw_arc(mpos, enemy_size, 0, TAU, 8, Color(0.6, 0.1, 0.1), 1.0)

	# Objetivo
	for obj in get_tree().get_nodes_in_group("objective"):
		if not is_instance_valid(obj):
			continue
		var rel = (obj.global_position - player.global_position) * world_scale
		var mpos = center + rel

		# Si está fuera del minimapa, dibujar flecha en el borde
		if not Rect2(Vector2.ZERO, minimap_size).has_point(mpos):
			var dir = (mpos - center).normalized()
			var edge = _clamp_to_minimap(center, dir)
			_draw_objective_arrow(edge, dir)
		else:
			_draw_objective_diamond(mpos)

	# Nave del jugador — forma de nave personalizada
	_draw_player_ship(center)

func _draw_player_ship(pos: Vector2) -> void:
	var angle = player.rotation
	var forward = Vector2.RIGHT.rotated(angle)
	var right = Vector2.DOWN.rotated(angle)

	# Cuerpo principal (triángulo apuntando hacia adelante)
	var tip   = pos + forward * 10.0
	var left  = pos - forward * 6.0 + right * 6.0
	var right_pt = pos - forward * 6.0 - right * 6.0

	draw_colored_polygon(PackedVector2Array([tip, left, right_pt]), player_color)

	# Alas traseras
	var wing_l1 = pos - forward * 4.0 + right * 6.0
	var wing_l2 = pos - forward * 10.0 + right * 9.0
	var wing_l3 = pos - forward * 8.0 + right * 3.0
	draw_colored_polygon(PackedVector2Array([wing_l1, wing_l2, wing_l3]), player_color.darkened(0.2))

	var wing_r1 = pos - forward * 4.0 - right * 6.0
	var wing_r2 = pos - forward * 10.0 - right * 9.0
	var wing_r3 = pos - forward * 8.0 - right * 3.0
	draw_colored_polygon(PackedVector2Array([wing_r1, wing_r2, wing_r3]), player_color.darkened(0.2))

	# Núcleo brillante
	draw_circle(pos, 2.5, Color(1, 1, 1, 0.9))

func _draw_objective_diamond(pos: Vector2) -> void:
	var s = 7.0
	var pulse = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)
	var col = Color(objective_color.r, objective_color.g, objective_color.b, pulse)
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
	]), Color(1,1,1,0.5 * pulse), 1.0)

func _draw_objective_arrow(edge: Vector2, dir: Vector2) -> void:
	var pulse = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)
	var col = Color(objective_color.r, objective_color.g, objective_color.b, pulse)
	var perp = dir.rotated(PI / 2)
	var a = edge + dir * 8.0
	var b = edge - dir * 4.0 + perp * 5.0
	var c = edge - dir * 4.0 - perp * 5.0
	draw_colored_polygon(PackedVector2Array([a, b, c]), col)

func _clamp_to_minimap(center: Vector2, dir: Vector2) -> Vector2:
	var margin = 12.0
	var half = minimap_size / 2 - Vector2(margin, margin)
	var t_x = half.x / max(abs(dir.x), 0.001)
	var t_y = half.y / max(abs(dir.y), 0.001)
	var t = min(t_x, t_y)
	return center + dir * t

func _process(_delta):
	queue_redraw()

func world_to_minimap(world_pos: Vector2) -> Vector2:
	if not player:
		return Vector2.ZERO
	return minimap_size / 2 + (world_pos - player.global_position) * world_scale

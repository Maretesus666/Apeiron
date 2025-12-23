extends CanvasLayer

@export var indicator_distance: float = 50.0
@export var indicator_size: float = 10.0
@export var update_interval: float = 0.001

var indicators := {}
var update_timer := 0.0
var player: Node2D

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
func _process(delta):
	if not is_instance_valid(player):
		return

	update_indicators()

	for data in indicators.values():
		var indicator: Control = data["node"]
		var alpha: float = float(indicator.get_meta("alpha"))
		alpha = move_toward(alpha, 1.0, delta * 4.0)
		indicator.modulate.a = alpha
		indicator.set_meta("alpha", alpha)




func update_indicators():
	var viewport := get_viewport()
	var viewport_size := viewport.get_visible_rect().size
	var camera := viewport.get_camera_2d()
	
	if not camera:
		return
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var active_enemies := {}

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var screen_pos: Vector2 = (enemy.global_position - camera.global_position) * camera.zoom + viewport_size * 0.5

		var is_on_screen: bool = (
		screen_pos.x >= 0.0 and screen_pos.x <= viewport_size.x and
		screen_pos.y >= 0.0 and screen_pos.y <= viewport_size.y
		)


		if is_on_screen:
			continue  # 👈 SI ESTÁ EN PANTALLA, NO HAY INDICADOR

		active_enemies[enemy] = true

		if not indicators.has(enemy):
			create_indicator(enemy)

		update_indicator_position(enemy, screen_pos, viewport_size)
 
	var to_remove := []
	for enemy in indicators.keys():
		if not is_instance_valid(enemy) or not active_enemies.has(enemy):
			to_remove.append(enemy)

	for enemy in to_remove:
		var data = indicators[enemy]
		var node = data["node"]
		node.modulate.a = 0.0
		node.queue_free()
		indicators.erase(enemy)
	
func create_indicator(enemy: Node2D): 
	var indicator := Control.new()
	indicator.size = Vector2(indicator_size, indicator_size)
	indicator.custom_minimum_size = indicator.size
	indicator.modulate.a = 0.0
	indicator.set_meta("alpha", 0.0)


	var arrow := Sprite2D.new()
	arrow.texture = preload("res://assets/sprites/advertencia.png")
	arrow.centered = true
	arrow.scale = Vector2(0.08, 0.08)
	indicator.add_child(arrow)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(-20, indicator_size + 6)
	indicator.add_child(label)

	indicators[enemy] = {
		"node": indicator,
		"arrow": arrow,
		"label": label,
		"target_pos": Vector2.ZERO
	}
	
	add_child(indicator)
func update_indicator_position(enemy: Node2D, screen_pos: Vector2, viewport_size: Vector2):
	var data = indicators[enemy]
	var indicator: Control = data["node"]
	var arrow: Sprite2D = data["arrow"]
	var label: Label = data["label"]

	var center := viewport_size * 0.5
	var dir := (screen_pos - center).normalized()
	var margin := indicator_distance

	var edge_pos: Vector2

	if abs(dir.x) > abs(dir.y):
		edge_pos.x = viewport_size.x - margin if dir.x > 0 else margin
		edge_pos.y = center.y + dir.y / abs(dir.x) * (edge_pos.x - center.x)
	else:
		edge_pos.y = viewport_size.y - margin if dir.y > 0 else margin
		edge_pos.x = center.x + dir.x / abs(dir.y) * (edge_pos.y - center.y)

	edge_pos.x = clamp(edge_pos.x, margin, viewport_size.x - margin)
	edge_pos.y = clamp(edge_pos.y, margin, viewport_size.y - margin)

	# ✅ POSICIÓN DIRECTA (NO VIBRA)
	indicator.position = edge_pos - indicator.size * 0.5

	# Flecha apunta bien
	arrow.rotation = dir.angle() - PI / 2

	label.text = str(int(player.global_position.distance_to(enemy.global_position)))



func remove_indicator(enemy: Node2D):
	if indicators.has(enemy):
		indicators[enemy]["node"].queue_free()
		indicators.erase(enemy)

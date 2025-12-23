extends Node2D

@export var star_count: int = 200
@export var star_speed_min: float = 10.0
@export var star_speed_max: float = 50.0
@export var star_size_min: float = 1.0
@export var star_size_max: float = 5.0
@export var spawn_distance: float = 1000.0

var stars: Array = []
var player: Node2D = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	generate_initial_stars()

func _process(delta):
	if not player:
		return
	
	update_stars(delta)
	spawn_new_stars()
	remove_distant_stars()

func generate_initial_stars():
	for i in range(star_count):
		var star = create_star(
			Vector2(
				randf_range(-spawn_distance, spawn_distance),
				randf_range(-spawn_distance, spawn_distance)
			)
		)
		stars.append(star)
		add_child(star)

func create_star(pos: Vector2) -> Node2D:
	var star = Node2D.new()
	star.global_position = pos
	
	var size = randf_range(star_size_min, star_size_max)
	var speed = randf_range(star_speed_min, star_speed_max)
	var brightness = randf_range(0.5, 1.0)
	
	# Guardar propiedades en el nodo
	star.set_meta("speed", speed)
	star.set_meta("size", size)
	
	# Crear sprite de la estrella
	var sprite = Sprite2D.new()
	sprite.texture = create_star_texture(size)
	sprite.modulate = Color(brightness, brightness, brightness)
	star.add_child(sprite)
	
	return star

func create_star_texture(size: float) -> ImageTexture:
	var img = Image.create(int(size * 2), int(size * 2), false, Image.FORMAT_RGBA8)
	
	for x in range(int(size * 2)):
		for y in range(int(size * 2)):
			var dx = x - size
			var dy = y - size
			var distance = sqrt(dx * dx + dy * dy)
			
			if distance <= size:
				var alpha = 1.0 - (distance / size)
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(img)

func update_stars(delta):
	if not player:
		return
	
	for star in stars:
		if not is_instance_valid(star):
			continue
		
		# Paralaje: estrellas más lentas se mueven menos con la cámara
		var speed = star.get_meta("speed")
		var parallax_factor = speed / star_speed_max
		
		# Calcular movimiento relativo al jugador
		var offset = player.velocity * delta * parallax_factor * 0.1
		star.global_position -= offset

func spawn_new_stars():
	if not player:
		return
	
	# Spawn estrellas en los bordes de la pantalla
	while stars.size() < star_count:
		var angle = randf() * TAU
		var distance = spawn_distance
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var spawn_pos = player.global_position + offset
		
		var star = create_star(spawn_pos)
		stars.append(star)
		add_child(star)

func remove_distant_stars():
	if not player:
		return
	
	var to_remove = []
	
	for star in stars:
		if not is_instance_valid(star):
			to_remove.append(star)
			continue
		
		var distance = star.global_position.distance_to(player.global_position)
		if distance > spawn_distance * 1.5:
			to_remove.append(star)
	
	for star in to_remove:
		stars.erase(star)
		if is_instance_valid(star):
			star.queue_free()

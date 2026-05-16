extends Area2D

# Parámetros básicos
@export var health: int = 3
@export var damage: int = 1

# Ventaja de velocidad: enemigo va 5-10% más rápido que el jugador
@export var speed_advantage_min: float = 1.05  # 5% más rápido
@export var speed_advantage_max: float = 1.10  # 10% más rápido

# Parámetros de movimiento
@export var acceleration_multiplier: float = 1.5  # Aceleración relativa a velocidad
@export var separation_radius: float = 130.0  # Distancia mínima entre enemigos
@export var separation_weight: float = 0.3  # Fuerza de separación
@export var prediction_time: float = 0.25  # Tiempo de predicción del movimiento del jugador

# Parámetros de rotación suave
@export var rotation_stiffness: float = 20.0
@export var rotation_damping: float = 8.0
@export var min_rotation_speed: float = 80.0

# Estado
var player: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var _angular_velocity: float = 0.0
var _speed_advantage: float = 1.0
var _damage_cooldown: float = 0.0
var _is_enraged: bool = false

func _ready() -> void:
	add_to_group("enemies")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	player = get_tree().get_first_node_in_group("player")
	
	# Cada enemigo tiene una ventaja de velocidad aleatoria entre 5-10%
	_speed_advantage = randf_range(speed_advantage_min, speed_advantage_max)
	set_meta("max_health", health)

func _physics_process(delta: float) -> void:
	if _damage_cooldown > 0.0:
		_damage_cooldown -= delta

	if not player or not is_instance_valid(player):
		return

	_update_rage_state()
	_check_collision_with_player()
	
	# Calcular velocidad objetivo basada en el jugador
	var target_speed: float = _get_target_speed()
	var target_acceleration: float = target_speed * acceleration_multiplier
	
	# Calcular dirección de movimiento
	var move_direction: Vector2 = _calculate_movement_direction()
	
	# Aplicar aceleración
	velocity += move_direction * target_acceleration * delta
	
	# Limitar velocidad máxima
	var current_speed: float = velocity.length()
	if current_speed > target_speed:
		velocity = velocity.normalized() * target_speed
	
	# Mover
	global_position += velocity * delta
	
	# Rotar suavemente hacia la dirección de movimiento
	_smooth_rotation(delta)

func _get_target_speed() -> float:
	if not is_instance_valid(player):
		return 0.0
	
	# Obtener velocidad actual del jugador
	var player_speed: float = 0.0
	if "velocity" in player:
		player_speed = player.velocity.length()
	
	# Si el jugador está parado o muy lento, usar velocidad base mínima
	var min_speed: float = 300.0
	player_speed = max(player_speed, min_speed)
	
	# Aplicar ventaja de velocidad (5-10% más rápido)
	var target: float = player_speed * _speed_advantage
	
	# Si está enfurecido, bonus adicional del 10%
	if _is_enraged:
		target *= 1.1
	
	return target

func _calculate_movement_direction() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	
	# Dirección hacia el jugador
	var to_player: Vector2 = player.global_position - global_position
	
	# Predecir posición futura del jugador
	var player_velocity: Vector2 = Vector2.ZERO
	if "velocity" in player:
		player_velocity = player.velocity
	
	var predicted_position: Vector2 = player.global_position + player_velocity * prediction_time
	var to_predicted: Vector2 = predicted_position - global_position
	
	# Dirección de persecución (mezcla entre posición actual y predicha)
	var chase_direction: Vector2 = to_predicted.normalized()
	
	# Aplicar separación de otros enemigos
	var separation_direction: Vector2 = _calculate_separation()
	
	# Combinar direcciones
	var final_direction: Vector2 = chase_direction
	if separation_direction.length() > 0.001:
		final_direction = chase_direction.lerp(separation_direction, separation_weight)
	
	return final_direction.normalized()

func _calculate_separation() -> Vector2:
	var separation: Vector2 = Vector2.ZERO
	var neighbor_count: int = 0
	
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node == self or not is_instance_valid(enemy_node):
			continue
		
		var to_neighbor: Vector2 = global_position - (enemy_node as Node2D).global_position
		var distance: float = to_neighbor.length()
		
		if distance < separation_radius and distance > 0.001:
			# Fuerza de separación inversamente proporcional a la distancia
			var strength: float = 1.0 - (distance / separation_radius)
			separation += to_neighbor.normalized() * strength
			neighbor_count += 1
	
	if neighbor_count > 0 and separation.length() > 0.001:
		return separation.normalized()
	
	return Vector2.ZERO

func _smooth_rotation(delta: float) -> void:
	var speed: float = velocity.length()
	
	if speed < min_rotation_speed:
		_angular_velocity *= 0.8
		return
	
	# Ángulo objetivo basado en la dirección de movimiento
	var target_angle: float = velocity.angle()
	var angle_error: float = wrapf(target_angle - rotation, -PI, PI)
	
	# Aplicar física de rotación con amortiguamiento
	var torque: float = rotation_stiffness * angle_error - rotation_damping * _angular_velocity
	_angular_velocity += torque * delta
	rotation += _angular_velocity * delta

func _check_collision_with_player() -> void:
	if _damage_cooldown > 0.0:
		return
	
	if not is_instance_valid(player):
		return
	
	var collision_distance: float = 30.0
	var distance_to_player: float = global_position.distance_to(player.global_position)
	
	if distance_to_player < collision_distance:
		if player.has_method("take_damage"):
			player.take_damage(damage)
		_damage_cooldown = 0.5
		die()

func _update_rage_state() -> void:
	var max_hp: int = get_meta("max_health", health) as int
	var was_enraged: bool = _is_enraged
	
	_is_enraged = health <= max_hp / 2
	
	# Efecto visual al enfurecerse
	if _is_enraged and not was_enraged:
		modulate = Color(1.0, 0.45, 0.0)
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.4)

# ══════════════════════════════════════════════════════════════════════════════
# DAÑO Y MUERTE
# ══════════════════════════════════════════════════════════════════════════════

func take_damage(amount: int) -> void:
	if not has_meta("max_health"):
		set_meta("max_health", health)
	
	health -= amount
	_flash_effect()
	_spawn_hit_particles()
	
	if health <= 0:
		die()

func die() -> void:
	_spawn_death_particles()
	
	if ScoreManager:
		ScoreManager.add_score(10)
	
	queue_free()

func _flash_effect() -> void:
	modulate = Color(1.0, 0.2, 0.2)
	await get_tree().create_timer(0.08).timeout
	
	if is_instance_valid(self) and not _is_enraged:
		modulate = Color.WHITE

func _spawn_hit_particles() -> void:
	_make_particles(
		global_position, 
		0, 
		0.5, 
		100.0, 
		220.0, 
		2.0, 
		4.0, 
		Color(1.0, 0.3, 0.1)
	)

func _spawn_death_particles() -> void:
	_make_particles(
		global_position, 
		0, 
		0.9, 
		160.0, 
		340.0, 
		3.0, 
		7.0, 
		Color(1.0, 0.5, 0.0)
	)

func _make_particles(
	pos: Vector2, 
	amount: int, 
	lifetime: float,
	vel_min: float, 
	vel_max: float,
	scale_min: float, 
	scale_max: float,
	color: Color
) -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.global_position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = lifetime
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = vel_min
	particles.initial_velocity_max = vel_max
	particles.scale_amount_min = scale_min
	particles.scale_amount_max = scale_max
	particles.color = color
	particles.gravity = Vector2.ZERO
	
	get_tree().root.add_child(particles)
	
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(particles):
		particles.queue_free()

# ══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ══════════════════════════════════════════════════════════════════════════════

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		die()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_bullet"):
		var bullet_damage: int = 1
		
		# Obtener daño de la bala
		if area.has_method("get_damage"):
			bullet_damage = area.get_damage()
		elif area.has_meta("damage"):
			bullet_damage = area.get_meta("damage") as int
		
		take_damage(bullet_damage)
		area.queue_free()

extends Area2D

@export var acceleration: float   = 6000.0
@export var max_speed: float      = 6000.0
@export var friction: float       = 0.0
@export var health: int           = 3
@export var damage: int           = 1

@export var max_predict_time: float    = 1.0
@export var fallback_predict_time: float = 0.35
@export var wobble_strength: float     = 0.06
@export var wobble_frequency: float    = 1.8
@export var separation_radius: float   = 130.0
@export var separation_weight: float   = 0.45
@export var rage_speed_mult: float     = 1.1
@export var rage_accel_mult: float     = 1.1
@export var rot_stiffness: float       = 20.0
@export var rot_damping: float         = 8.0
@export var rot_min_speed: float       = 80.0
@export var ram_distance: float        = 200.0

# Nuevos parámetros para evitar cruzarse delante del jugador
@export var front_avoid_distance: float = 400.0  # Distancia para detectar estar "delante"
@export var front_avoid_angle: float    = 45.0   # Ángulo en grados para considerar "delante"
@export var side_approach_bias: float   = 1.5    # Multiplicador para preferir aproximación lateral

var player: Node2D    = null
var velocity: Vector2 = Vector2.ZERO

var _wobble_phase: float = 0.0
var _angular_vel:  float = 0.0
var _is_enraged:   bool  = false

var _player_vel_history: Array[Vector2] = []
const HISTORY_SIZE := 4

var _damage_cooldown: float = 0.0

var _speed_advantage: float = 1.0

func _ready() -> void:
	add_to_group("enemies")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	player = get_tree().get_first_node_in_group("player")
	_wobble_phase    = randf_range(0.0, TAU)
	_speed_advantage = randf_range(1.05, 1.10)
	set_meta("max_health", health)

func _get_dynamic_max_speed() -> float:
	if not player or not is_instance_valid(player):
		return max_speed

	var player_max: float = player.max_speed if "max_speed" in player else 6000.0
	var player_cur: float = player.velocity.length()

	var player_accel: float = player.thrust_acceleration if "thrust_acceleration" in player else 6000.0
	var projected_speed: float = player_cur + player_accel * 0.1

	var reference: float = minf(projected_speed, player_max)
	reference = maxf(reference, player_max * 0.2)

	return reference * _speed_advantage

func _get_dynamic_accel() -> float:
	return _get_dynamic_max_speed() * 1.5

func _physics_process(delta: float) -> void:
	if _damage_cooldown > 0.0:
		_damage_cooldown -= delta

	if not player or not is_instance_valid(player):
		_apply_friction(delta)
		_smooth_rotation(delta)
		return

	_update_rage()
	_update_player_history()

	_check_player_proximity(delta)

	var dyn_max_speed: float = _get_dynamic_max_speed()
	var dyn_accel:     float = _get_dynamic_accel()

	var eff_max_speed: float = dyn_max_speed * (rage_speed_mult if _is_enraged else 1.0)
	var eff_accel:     float = dyn_accel     * (rage_accel_mult if _is_enraged else 1.0)

	var desired_dir := _compute_direction(delta)
	velocity += desired_dir * eff_accel * delta

	var spd := velocity.length()
	if spd > eff_max_speed:
		velocity = velocity * (eff_max_speed / spd)

	global_position += velocity * delta
	_smooth_rotation(delta)

func _check_player_proximity(delta: float) -> void:
	if _damage_cooldown > 0.0:
		return
	if not is_instance_valid(player):
		return
	var collision_radius: float = 30.0
	var dist: float = global_position.distance_to(player.global_position)
	if dist < collision_radius:
		if player.has_method("take_damage"):
			player.take_damage(damage)
		_damage_cooldown = 0.5
		die()

func _compute_direction(delta: float) -> Vector2:
	var player_vel := _get_player_velocity()
	var dist       := global_position.distance_to(player.global_position)

	var target_pos: Vector2
	if dist < ram_distance:
		target_pos = player.global_position
	else:
		target_pos = _solve_intercept(player_vel)

	# NUEVO: Detectar si estamos delante del jugador
	var to_enemy := (global_position - player.global_position).normalized()
	var player_forward := player_vel.normalized() if player_vel.length() > 50 else Vector2.RIGHT.rotated(player.rotation)
	
	var dot_product := to_enemy.dot(player_forward)
	var is_in_front := dot_product > cos(deg_to_rad(front_avoid_angle)) and dist < front_avoid_distance
	
	var chase_dir := (target_pos - global_position).normalized()
	
	# Si estamos delante del jugador, preferir moverse hacia los lados
	if is_in_front:
		# Obtener dirección perpendicular a la velocidad del jugador
		var perpendicular := Vector2(-player_forward.y, player_forward.x)
		
		# Decidir qué lado es mejor (el que nos acerca más al jugador desde el costado)
		var to_player := (player.global_position - global_position)
		var side_sign := 1.0 # o -1.0 guardado como variable del enemigo
		
		# Mezclar dirección de persecución con movimiento lateral
		var lateral_dir := perpendicular * side_sign
		chase_dir = chase_dir.lerp(lateral_dir, side_approach_bias).normalized()

	_wobble_phase += delta * wobble_frequency * TAU
	var wobble_scale := clampf(dist / 800.0, 0.0, 1.0)
	chase_dir = chase_dir.rotated(sin(_wobble_phase) * wobble_strength * wobble_scale)

	var sep_dir := _compute_separation()
	if sep_dir.length() > 0.001:
		chase_dir = chase_dir.lerp(sep_dir, separation_weight).normalized()

	return chase_dir

func _solve_intercept(player_vel: Vector2) -> Vector2:
	var eff_speed: float    = _get_dynamic_max_speed() * (rage_speed_mult if _is_enraged else 1.0)
	var solver_speed: float = lerp(velocity.length(), eff_speed, 0.6)
	solver_speed = maxf(solver_speed, eff_speed * 0.4)

	var w: Vector2 = player.global_position - global_position
	var a: float   = player_vel.dot(player_vel) - solver_speed * solver_speed
	var b: float   = 2.0 * w.dot(player_vel)
	var c: float   = w.dot(w)
	var t: float   = -1.0

	if absf(a) < 0.5:
		if absf(b) > 0.5:
			t = -c / b
	else:
		var disc: float = b * b - 4.0 * a * c
		if disc >= 0.0:
			var sq := sqrt(disc)
			var t1 := (-b - sq) / (2.0 * a)
			var t2 := (-b + sq) / (2.0 * a)
			if t1 > 0.001 and t2 > 0.001:
				t = minf(t1, t2)
			elif t1 > 0.001:
				t = t1
			elif t2 > 0.001:
				t = t2

	if t > 0.001:
		var accel_est := _estimate_player_accel()
		t = minf(t, max_predict_time)
		return player.global_position + player_vel * t + accel_est * 0.5 * t * t
	else:
		return player.global_position + player_vel * fallback_predict_time

func _update_player_history() -> void:
	_player_vel_history.push_back(_get_player_velocity())
	if _player_vel_history.size() > HISTORY_SIZE:
		_player_vel_history.pop_front()

func _get_player_velocity() -> Vector2:
	if "velocity" in player:
		return player.velocity
	if player.has_method("get_velocity"):
		return player.get_velocity()
	return Vector2.ZERO

func _estimate_player_accel() -> Vector2:
	if _player_vel_history.size() < 2:
		return Vector2.ZERO
	return (_player_vel_history[-1] - _player_vel_history[0]) * 0.3

func _compute_separation() -> Vector2:
	var sep   := Vector2.ZERO
	var count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node == self or not is_instance_valid(enemy_node):
			continue
		var diff: Vector2 = global_position - (enemy_node as Node2D).global_position
		var dist: float   = diff.length()
		if dist < separation_radius and dist > 0.001:
			sep += diff.normalized() * (1.0 - dist / separation_radius)
			count += 1
	if count > 0 and sep.length() > 0.001:
		return sep.normalized()
	return Vector2.ZERO

func _update_rage() -> void:
	var max_hp: int = get_meta("max_health", health)
	var was := _is_enraged
	_is_enraged = health <= max_hp / 2
	if _is_enraged and not was:
		modulate = Color(1.0, 0.45, 0.0)
		var tw := create_tween()
		tw.tween_property(self, "modulate", Color.WHITE, 0.4)

func _apply_friction(delta: float) -> void:
	if friction <= 0.0:
		return
	if velocity.length() > friction * delta:
		velocity -= velocity.normalized() * friction * delta
	else:
		velocity = Vector2.ZERO

func _smooth_rotation(delta: float) -> void:
	if velocity.length() < rot_min_speed:
		_angular_vel *= 0.8
		return
	var target: float = velocity.angle()
	var error: float  = wrapf(target - rotation, -PI, PI)
	var force: float  = rot_stiffness * error - rot_damping * _angular_vel
	_angular_vel += force * delta
	rotation     += _angular_vel * delta

func take_damage(amount: int) -> void:
	if not has_meta("max_health"):
		set_meta("max_health", health)
	health -= amount
	flash_effect()
	spawn_hit_particles()
	if health <= 0:
		die()

func die() -> void:
	spawn_death_particles()
	if ScoreManager:
		ScoreManager.add_score(10)
	queue_free()

func flash_effect() -> void:
	modulate = Color(1, 0.2, 0.2)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(self) and not _is_enraged:
		modulate = Color.WHITE

func _make_particles(pos: Vector2, amount: int, lifetime: float,
		vel_min: float, vel_max: float,
		scale_min: float, scale_max: float,
		color: Color) -> void:
	var p := CPUParticles2D.new()
	p.global_position      = pos
	p.emitting             = true
	p.one_shot             = true
	p.amount               = amount
	p.lifetime             = lifetime
	p.explosiveness        = 1.0
	p.spread               = 180
	p.initial_velocity_min = vel_min
	p.initial_velocity_max = vel_max
	p.scale_amount_min     = scale_min
	p.scale_amount_max     = scale_max
	p.color                = color
	get_tree().root.add_child(p)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(p):
		p.queue_free()

func spawn_hit_particles() -> void:
	_make_particles(global_position, 8, 0.5, 100, 220, 2, 4, Color(1, 0.3, 0.1))

func spawn_death_particles() -> void:
	_make_particles(global_position, 22, 0.9, 160, 340, 3, 7, Color(1, 0.5, 0))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		die()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_bullet"):
		var bullet_damage := 1
		if area.has_method("get_damage"):
			bullet_damage = area.get_damage()
		elif area.has_meta("damage"):
			bullet_damage = area.get_meta("damage")
		
		take_damage(bullet_damage)
		area.queue_free()

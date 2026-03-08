extends Area2D

# ─── Stats ───────────────────────────────────────────────────────────────────
@export var acceleration: float       = 500.0
@export var max_speed: float          = 1500.0
@export var friction: float           = 0.0
@export var rotation_speed: float     = 5.0
@export var health: int               = 3
@export var damage: int               = 1

# ─── AI Tuning ────────────────────────────────────────────────────────────────
## Fallback prediction time used only when geometric solver has no solution
@export var fallback_prediction_time: float = 0.3
## How far ahead (in pixels) to aim in CUTOFF mode — hard cap prevents overshooting
@export var cutoff_lead_distance: float = 350.0
## Player speed threshold to enter CUTOFF (only engage cutoff if player moves fast)
@export var cutoff_speed_threshold: float = 600.0
## Wobble injected into direction so enemies don't all arrive from the same angle
@export var wobble_strength: float    = 0.25
## Separation radius from other enemies
@export var separation_radius: float  = 120.0
@export var separation_strength: float = 2000.0

# ─── Juke detection ───────────────────────────────────────────────────────────
## Angle change rate (rad/s) above which we consider the player is juking
@export var juke_threshold: float     = 6.0
## How fast juke confidence decays back to normal (seconds to fully recover)
@export var juke_decay: float         = 0.4
## When juking, prediction blends toward direct aim by this amount (0-1)
@export var juke_direct_blend: float  = 0.85

# ─── Rage mode (triggered below half health) ─────────────────────────────────
@export var rage_speed_multiplier: float  = 1.4
@export var rage_accel_multiplier: float  = 1.6
## Rage makes prediction more aggressive (less juke-reduction)
@export var rage_juke_resistance: float   = 0.5

# ─── Internal state ───────────────────────────────────────────────────────────
enum State { INTERCEPT, CUTOFF }
var state: State = State.INTERCEPT

var player: Node2D    = null
var velocity: Vector2 = Vector2.ZERO
var _wobble_phase: float = 0.0
var _is_enraged: bool    = false

# ─── Player motion tracking ───────────────────────────────────────────────────
var _player_prev_velocity: Vector2  = Vector2.ZERO
var _player_accel_estimate: Vector2 = Vector2.ZERO
var _player_prev_vel_angle: float   = 0.0   # for juke detection
var _juke_intensity: float          = 0.0   # 0 = calm, 1 = full juke

# ─── Rotation spring ──────────────────────────────────────────────────────────
@export var rot_spring_stiffness: float = 18.0
@export var rot_spring_damping: float   = 8.0
@export var rot_min_speed: float        = 60.0
var _angular_velocity: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	player = get_tree().get_first_node_in_group("player")
	_wobble_phase = randf_range(0.0, TAU)

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		_apply_friction(delta)
		return

	_update_rage()
	_update_state()

	var effective_max_speed: float = max_speed * (rage_speed_multiplier if _is_enraged else 1.0)
	var effective_accel: float     = acceleration * (rage_accel_multiplier if _is_enraged else 1.0)

	var desired_dir: Vector2 = _compute_desired_direction(delta)
	velocity += desired_dir * effective_accel * delta

	# Hard clamp — never exceed max speed under any circumstance
	var spd: float = velocity.length()
	if spd > effective_max_speed:
		velocity = velocity * (effective_max_speed / spd)

	global_position += velocity * delta
	_smooth_rotation(delta)

# ─── AI helpers ───────────────────────────────────────────────────────────────

func _update_rage() -> void:
	var was_enraged := _is_enraged
	_is_enraged = health <= (get_meta("max_health", health) / 2.0)
	if _is_enraged and not was_enraged:
		# Flash orange briefly to signal rage
		modulate = Color(1.0, 0.5, 0.0)
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func _update_state() -> void:
	# CUTOFF: player is moving fast AND enemy is roughly behind the player's
	# velocity vector (i.e. chasing from behind) → try to cut ahead instead
	var player_vel: Vector2 = _player_prev_velocity
	var to_enemy: Vector2   = global_position - player.global_position
	var dot: float          = to_enemy.normalized().dot(player_vel.normalized())
	# dot < -0.3 means enemy is roughly in front of the player's movement
	# We only enter CUTOFF when the player is actually moving fast
	var player_fast: bool = player_vel.length() > cutoff_speed_threshold
	state = State.CUTOFF if (player_fast and dot < -0.3) else State.INTERCEPT

func _compute_desired_direction(delta: float) -> Vector2:
	# ── 1. Sample player motion (updates accel estimate + juke intensity) ────
	var player_vel: Vector2 = _sample_player_motion(delta)

	# ── 2. Get intercept target depending on state ───────────────────────────
	var target_pos: Vector2
	match state:
		State.CUTOFF:
			# Lead ahead of the player along their heading by a fixed pixel distance.
			# Using a fixed distance (not speed×time) prevents overshooting at high speeds.
			var player_dir: Vector2 = player_vel.normalized() if player_vel.length() > 10.0 else Vector2.ZERO
			target_pos = player.global_position + player_dir * cutoff_lead_distance
		State.INTERCEPT, _:
			# Geometric intercept: find the exact point in space-time where
			# this enemy (moving at max_speed) and the player meet.
			target_pos = _solve_intercept(player_vel)

	# ── 3. Juke blend: if player is juking, partially ignore prediction ──────
	# When juking, the predicted position is unreliable — blend toward direct.
	var juke_bias: float = _juke_intensity
	if _is_enraged:
		juke_bias *= (1.0 - rage_juke_resistance)   # rage = more stubborn
	target_pos = target_pos.lerp(player.global_position, juke_bias * juke_direct_blend)

	var dir: Vector2 = (target_pos - global_position).normalized()

	# ── 4. Wobble ─────────────────────────────────────────────────────────────
	_wobble_phase += delta * 2.3
	dir = dir.rotated(sin(_wobble_phase) * wobble_strength)

	# ── 5. Separation ─────────────────────────────────────────────────────────
	var sep: Vector2 = _compute_separation()
	dir = (dir * effective_accel_for_blend() + sep * separation_strength).normalized()

	return dir

## Geometric intercept solver.
## Finds the earliest point where an object moving at `enemy_speed` can reach
## the same position as a target moving at constant `player_vel` from `player_pos`.
## Falls back to kinematic prediction if no solution exists.
func _solve_intercept(player_vel: Vector2) -> Vector2:
	var enemy_speed: float = max_speed * (rage_speed_multiplier if _is_enraged else 1.0)
	# Use the enemy's actual current speed as a lower bound so the solver
	# doesn't assume instant direction changes from a standing start
	var effective_speed: float = max(velocity.length() * 0.5 + enemy_speed * 0.5, enemy_speed * 0.4)

	var w: Vector2 = player.global_position - global_position

	# Quadratic: |w + player_vel*t|² = (effective_speed*t)²
	var a: float = player_vel.dot(player_vel) - effective_speed * effective_speed
	var b: float = 2.0 * w.dot(player_vel)
	var c: float = w.dot(w)

	var t: float = -1.0

	if abs(a) < 0.001:
		if abs(b) > 0.001:
			t = -c / b
	else:
		var disc: float = b * b - 4.0 * a * c
		if disc >= 0.0:
			var sqrt_disc: float = sqrt(disc)
			var t1: float = (-b - sqrt_disc) / (2.0 * a)
			var t2: float = (-b + sqrt_disc) / (2.0 * a)
			if t1 > 0.001 and t2 > 0.001:
				t = min(t1, t2)
			elif t1 > 0.001:
				t = t1
			elif t2 > 0.001:
				t = t2

	# Hard cap: never aim more than 1.2 seconds into the future.
	# Beyond that, predictions are unreliable and cause overshooting.
	const MAX_INTERCEPT_TIME: float = 1.2
	if t > 0.0:
		t = min(t, MAX_INTERCEPT_TIME)
		return player.global_position + player_vel * t
	else:
		# Fallback: kinematic prediction
		var pt: float = fallback_prediction_time
		return (player.global_position
			+ player_vel * pt
			+ _player_accel_estimate * 0.5 * pt * pt)

## Sample player velocity, estimate acceleration, and detect jukes
func _sample_player_motion(delta: float) -> Vector2:
	var cur_vel: Vector2 = _read_player_velocity()

	# ── Acceleration estimate (finite differences, smoothed) ─────────────────
	var raw_accel: Vector2 = (cur_vel - _player_prev_velocity) / delta if delta > 0.0 else Vector2.ZERO
	_player_accel_estimate = _player_accel_estimate.lerp(raw_accel, 0.2)

	# ── Juke detection (angular velocity of velocity vector) ─────────────────
	var cur_angle: float = cur_vel.angle() if cur_vel.length() > 50.0 else _player_prev_vel_angle
	var angle_delta: float = abs(wrapf(cur_angle - _player_prev_vel_angle, -PI, PI))
	var angular_rate: float = angle_delta / delta if delta > 0.0 else 0.0

	# Spike up instantly, decay smoothly
	if angular_rate > juke_threshold:
		_juke_intensity = min(_juke_intensity + (angular_rate / juke_threshold) * delta * 4.0, 1.0)
	else:
		_juke_intensity = move_toward(_juke_intensity, 0.0, delta / juke_decay)

	_player_prev_velocity  = cur_vel
	_player_prev_vel_angle = cur_angle
	return cur_vel

func _read_player_velocity() -> Vector2:
	if player.has_method("get_velocity"):
		return player.get_velocity()
	if "velocity" in player:
		return player.velocity
	return Vector2.ZERO

func _compute_separation() -> Vector2:
	var sep := Vector2.ZERO
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node == self or not is_instance_valid(enemy_node):
			continue
		var enemy := enemy_node as Node2D
		if enemy == null:
			continue
		var diff: Vector2 = global_position - enemy.global_position
		var dist: float   = diff.length()
		if dist < separation_radius and dist > 0.0:
			sep += diff.normalized() * (1.0 - dist / separation_radius)
	return sep

## Helper so we can weight separation relative to current acceleration
func effective_accel_for_blend() -> float:
	return acceleration * (rage_accel_multiplier if _is_enraged else 1.0)

func _apply_friction(delta: float) -> void:
	if friction <= 0.0:
		return
	if velocity.length() > friction * delta:
		velocity -= velocity.normalized() * friction * delta
	else:
		velocity = Vector2.ZERO

func _smooth_rotation(delta: float) -> void:
	# Don't rotate when nearly stopped — avoids jitter from noise in velocity
	if velocity.length() < rot_min_speed:
		_angular_velocity *= 0.85   # damp the spring so it settles quietly
		return

	var target_angle: float = velocity.angle()
	# Angular difference in [-PI, PI]
	var angle_error: float  = wrapf(target_angle - rotation, -PI, PI)

	# Critically-damped spring: F = stiffness * error − damping * angular_vel
	var spring_force: float = rot_spring_stiffness * angle_error - rot_spring_damping * _angular_velocity
	_angular_velocity += spring_force * delta
	rotation            += _angular_velocity * delta

# ─── Damage / Death ───────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	# Store max_health on first hit if not set
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

# ─── Visual effects ───────────────────────────────────────────────────────────

func flash_effect() -> void:
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and not _is_enraged:
		modulate = Color.WHITE

func _make_particles(pos: Vector2, amount: int, lifetime: float,
		vel_min: float, vel_max: float,
		scale_min: float, scale_max: float,
		color: Color) -> void:
	var p := CPUParticles2D.new()
	p.global_position    = pos
	p.emitting           = true
	p.one_shot           = true
	p.amount             = amount
	p.lifetime           = lifetime
	p.explosiveness      = 1.0
	p.spread             = 180
	p.initial_velocity_min = vel_min
	p.initial_velocity_max = vel_max
	p.scale_amount_min   = scale_min
	p.scale_amount_max   = scale_max
	p.color              = color
	get_tree().root.add_child(p)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(p):
		p.queue_free()

func spawn_hit_particles() -> void:
	_make_particles(global_position, 8, 0.5, 100, 200, 2, 4, Color(1, 0.3, 0.1))

func spawn_death_particles() -> void:
	_make_particles(global_position, 20, 0.8, 150, 300, 3, 6, Color(1, 0.5, 0))

# ─── Collision callbacks ──────────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		die()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_bullet"):
		take_damage(1)
		area.queue_free()

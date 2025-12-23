extends Area2D

@export var acceleration: float = 300.0
@export var max_speed: float = 800.0
@export var friction: float = 100.0
@export var rotation_speed: float = 3.0
@export var health = 3
@export var damage = 1

var player = null
var velocity = Vector2.ZERO

func _ready():
	add_to_group("enemies")  # Agregar al grupo para minimapa e indicadores
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if player and is_instance_valid(player):
		var direction = (player.global_position - global_position).normalized()
		velocity += direction * acceleration * delta
		
		if velocity.length() > max_speed:
			velocity = velocity.normalized() * max_speed
		
		global_position += velocity * delta
		
		if velocity.length() > 10:
			var target_rotation = velocity.angle()
			rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
	else:
		if velocity.length() > friction * delta:
			velocity -= velocity.normalized() * friction * delta
		else:
			velocity = Vector2.ZERO

func take_damage(amount: int):
	health -= amount
	flash_effect()
	spawn_hit_particles()
	
	if health <= 0:
		die()

func die():
	spawn_death_particles()
	
	if ScoreManager:
		ScoreManager.add_score(10)
	
	queue_free()

func flash_effect():
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1)

func spawn_hit_particles():
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.5
	particles.explosiveness = 1.0
	particles.spread = 180
	particles.initial_velocity_min = 100
	particles.initial_velocity_max = 200
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	particles.color = Color(1, 0.3, 0.1)
	get_tree().root.add_child(particles)
	
	await get_tree().create_timer(particles.lifetime).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func spawn_death_particles():
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.8
	particles.explosiveness = 1.0
	particles.spread = 180
	particles.initial_velocity_min = 150
	particles.initial_velocity_max = 300
	particles.scale_amount_min = 3
	particles.scale_amount_max = 6
	particles.color = Color(1, 0.5, 0)
	get_tree().root.add_child(particles)
	
	await get_tree().create_timer(particles.lifetime).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		die()

func _on_area_entered(area):
	if area.is_in_group("player_bullet"):
		take_damage(1)
		area.queue_free()

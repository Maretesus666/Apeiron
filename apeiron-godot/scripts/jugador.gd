extends CharacterBody2D

@export var speed : float = 300.0
@export var bullet =preload( "res://scenes/bala.tscn")

@onready var puntoDisparo = $PuntoDisparo

func _physics_process(delta):
	_handle_movement(delta)
	_handle_rotation()

	if Input.is_action_just_pressed("shoot"):
		_shoot()

func _handle_movement(delta):
	var dir = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		dir.y -= 1
	if Input.is_action_pressed("move_down"):
		dir.y += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1

	if dir.length() > 0:
		dir = dir.normalized()
	
	velocity = dir * speed
	move_and_slide()

func _handle_rotation():
	look_at(get_global_mouse_position())

func _shoot():
	var newBullet = bullet.instantiate()
	newBullet.rotation = rotation
	newBullet.global_position = puntoDisparo.global_position
	
	get_parent().add_child(newBullet)

extends Area2D

@export var speed: float = 1000.0
 

func _physics_process(delta):
	position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _ready():
	add_to_group("player_bullet")

extends Control

@onready var tab_container = $TabContainer
@onready var clicker_tab = $TabContainer/Clicker
@onready var game_info_tab = $TabContainer/Juego
 
func _ready():
	# Asegurarse de que el tab de clicker use el nuevo script
	if clicker_tab:
		var clicker_script = load("res://scripts/clicker_improved.gd")
		if clicker_script:
			clicker_tab.set_script(clicker_script)

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

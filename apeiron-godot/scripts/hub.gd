extends Control

@onready var scroller: ScrollContainer = $ContenedorBotones/ScrollContainer
@onready var animation_tree: AnimationTree = $AnimationTree

# Ya no necesitás tab_container ni clicker_tab
# El clicker script va directo en la página 1

var is_scrolling: bool = false
var is_manual_scrolling: bool = false
var scroll_to: float = 0.0
var scroll_to_index: int = 0
var page_width: float = 0.0
var scroll_pos: float = 0.0

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame  # segundo frame para que el layout termine
	page_width = scroller.get_child(0).get_child(0).size.x
	scroller.scroll_horizontal = 0

 
func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_scroll_container_scroll_started() -> void:
	is_scrolling = true
	set_process(true)

func _on_scroll_container_scroll_ended() -> void:
	is_scrolling = false
	
	
func _process(delta: float) -> void:
	var max_scroll := scroller.get_h_scroll_bar().max_value
	if max_scroll == 0:
		return

	if is_manual_scrolling:
		scroll_pos = lerp(scroll_pos, scroll_to, 1.0 - pow(0.001, delta))
		scroller.scroll_horizontal = int(scroll_pos)
		animation_tree["parameters/blend_position"] = scroll_pos / max_scroll

		if abs(scroll_pos - scroll_to) < 0.5:
			scroll_pos = scroll_to
			scroller.scroll_horizontal = int(scroll_to)
			animation_tree["parameters/blend_position"] = float(scroll_to_index)
			is_manual_scrolling = false
			set_process(false)
	else:
		var progress := float(scroller.scroll_horizontal) / max_scroll
		var target := float(round(progress))

		if is_scrolling:
			animation_tree["parameters/blend_position"] = progress
		elif abs(target - progress) > 0.01:
			animation_tree["parameters/blend_position"] = lerp(float(animation_tree["parameters/blend_position"]), target, 0.1)
			scroller.scroll_horizontal = int(lerp(float(scroller.scroll_horizontal), max_scroll * target, 0.2))
		else:
			animation_tree["parameters/blend_position"] = target
			scroller.scroll_horizontal = int(max_scroll * target)
			set_process(false)

func _on_button_pressed(extra_arg_0: int) -> void:
	var max_scroll := scroller.get_h_scroll_bar().max_value
	scroll_pos = float(scroller.scroll_horizontal)  # ← esta línea
	scroll_to_index = extra_arg_0
	scroll_to = max_scroll * float(extra_arg_0)
	is_manual_scrolling = true
	set_process(true)

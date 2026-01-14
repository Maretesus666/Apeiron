extends Control

@onready var tab_container = $TabContainer
@onready var clicker_tab = $TabContainer/Clicker
@onready var game_info_tab = $TabContainer/Juego
@onready var scroller: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var animation_tree: AnimationTree = $AnimationTree

var is_scrolling : bool = false 
var is_manual_scrolling : bool = false
var scroll_to :float =0.0
var scroll_to_index :int=0
func _ready():
	await get_tree().process_frame
	@warning_ignore("narrowing_conversion")
	scroller.scroll_horizontal = scroller.size.x


	# Asegurarse de que el tab de clicker use el nuevo script
	if clicker_tab:
		var clicker_script = load("res://scripts/clicker_improved.gd")
		if clicker_script:
			clicker_tab.set_script(clicker_script)

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_scroll_container_scroll_started() -> void:
	is_scrolling = true
	set_process(true)

func _on_scroll_container_scroll_ended() -> void:
	is_scrolling = false

func _process(delta: float) -> void:

	var page_width := scroller.size.x


	if is_manual_scrolling:
		 
		var current_scroll: float = scroller.scroll_horizontal
		var target_scroll: float = scroll_to

		scroller.scroll_horizontal = int(lerp(
			float(current_scroll),
			float(target_scroll),
			1.0 - pow(0.001, delta)
		))


		var blend := scroller.scroll_horizontal / page_width
		animation_tree["parameters/blend_position"] = blend

		 
		if abs(scroller.scroll_horizontal - target_scroll) < 1.0:
			@warning_ignore("narrowing_conversion")
			scroller.scroll_horizontal = target_scroll
			animation_tree["parameters/blend_position"] = float(scroll_to_index)
			is_manual_scrolling = false
			set_process(false)

	else:
		# 🔹 Scroll automático (drag)
		var scroll: float = scroller.scroll_horizontal / page_width
		var target: float = float(round(scroll))

		if is_scrolling:
			animation_tree["parameters/blend_position"] = scroll

		elif abs(target - scroll) > 0.01:
			animation_tree["parameters/blend_position"] = lerp(
				float(animation_tree["parameters/blend_position"]),
				target,
				0.1
			)
			scroller.scroll_horizontal = int(lerp(
				float(scroller.scroll_horizontal),
				page_width * target,
				0.2
			))


		else:
			animation_tree["parameters/blend_position"] = target
			@warning_ignore("narrowing_conversion")
			scroller.scroll_horizontal = page_width * target
			set_process(false)

func _on_button_pressed(extra_arg_0: int) -> void:
	scroll_to_index = extra_arg_0
	scroll_to = scroller.size.x * extra_arg_0
	is_manual_scrolling = true
	set_process(true)

extends Control

@export var debug_effect: Label
@export var debug_effect_location: Label
@export var debug_gesture: Label
@export var debug_hand_location: Label

func _ready() -> void:
    debug_effect.text = "None"
    debug_effect_location.text = "0.02, 0.6, 1.0"
    debug_gesture.text = "Flat"
    debug_hand_location.text = "0.02, 0.6, 1.0"

func _on_exit_button_pressed() -> void:
    get_tree().change_scene_to_file("res://start_menu.tscn")

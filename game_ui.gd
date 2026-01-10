extends Control

@export var debug_effect: Label
@export var debug_effect_location: Label
@export var debug_gesture: Label
@export var debug_hand_location: Label

@export var time_value: Label
@export var enemy_health : TextureProgressBar

func _ready() -> void:
    debug_effect.text = "None"
    debug_effect_location.text = "0.02, 0.6, 1.0"
    debug_gesture.text = "Flat"
    debug_hand_location.text = "0.02, 0.6, 1.0"

func _on_exit_button_pressed() -> void:
    get_tree().change_scene_to_file("res://start_menu.tscn")

func _update_time(time: int) -> void:
    var minutes: int = time / 60
    var seconds: int = time % 60
    time_value.text = "%02d:%02d" % [minutes, seconds]

func _update_enemy_health(health: int) -> void:
    enemy_health.value = health
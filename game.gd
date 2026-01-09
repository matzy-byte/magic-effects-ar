extends Node3D

@export var game_ui : Control
@export var time := 90
@export var timer : Timer
@export var enemy_health := 100
@export var enemy : CharacterBody3D

func _ready() -> void:
	timer.start()

func _on_timer_timeout() -> void:
	time -= 1
	_on_enemy_hit()
	game_ui.call("_update_time", time)

func _on_enemy_hit() -> void:
	enemy_health -= 10
	game_ui.call("_update_enemy_health", enemy_health)
	if enemy_health <= 0:
		enemy.call("_enemy_dead")
	else:
		enemy.call("_enemy_hit")

extends Node3D

@export var game_ui : Control
@export var time := 90
@export var timer : Timer
@export var enemy_health := 100
@export var enemy : CharacterBody3D
@export var enemy_hit_sound : AudioStreamPlayer3D

var spells : Array

func _ready() -> void:
	timer.start()

func _on_timer_timeout() -> void:
	time -= 1
	_on_enemy_hit(Node3D.new())
	game_ui.call("_update_time", time)

func _on_enemy_hit(body: Node3D) -> void:
	enemy_hit_sound.play()
	await get_tree().create_timer(0.1).timeout
	enemy_health -= 10
	game_ui.call("_update_enemy_health", enemy_health)
	if enemy_health <= 0:
		enemy.call("_enemy_dead")
	else:
		enemy.call("_enemy_hit")
	
	if body is Spell:
		var spell := body as Spell
		spell._destroy()


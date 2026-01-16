extends Node3D

@export var game_ui : Control
@export var time := 90
@export var timer : Timer
@export var enemy_health := 100
@export var enemy : CharacterBody3D
@export var enemy_hit_sound : AudioStreamPlayer3D
@export var spell_spawn_sound : AudioStreamPlayer3D

var active_spell : Spell
var spell_active := false
var latest_center_pos: Vector3

var spells : Array
enum EffectType {
	FIRE, 
	WATER,
	LIGHTNING,
	EARTH,
	LIGHT,
	FOG
}

func _ready() -> void:
	timer.start()

func _process(_delta):
	if active_spell:
		active_spell.target_origin = latest_center_pos

func _on_timer_timeout() -> void:
	time -= 1
	#_on_enemy_hit(Node3D.new())
	game_ui.call("_update_time", time)

func _on_enemy_hit(area: Area3D) -> void:
	enemy_hit_sound.play()
	await get_tree().create_timer(0.1).timeout
	enemy_health -= 10
	game_ui.call("_update_enemy_health", enemy_health)
	if enemy_health <= 0:
		enemy.call("_enemy_dead")
	else:
		enemy.call("_enemy_hit")
	
	if area is Spell:
		_deactivate_spell()

func _on_control_effect_triggered(effect_type: EffectType, origin: Vector3):
	if active_spell:
		active_spell.queue_free()

	var scene = load("res://spell/spell.tscn")
	var instance = scene.instantiate() as Spell
	add_child(instance)
	active_spell = instance

	spell_spawn_sound.play()
	
	match effect_type:
		EffectType.FIRE:
			active_spell._initialize(0, origin)
			spell_active = true
			print("fire!")
		EffectType.WATER:
			active_spell._initialize(1, origin)
			spell_active = true
			print("water!")
		EffectType.LIGHTNING:
			active_spell._initialize(2, origin)
			spell_active = true
			print("lightning!")
		EffectType.EARTH:
			active_spell._initialize(3, origin)
			spell_active = true
			print("earth!")
		EffectType.LIGHT:
			active_spell._initialize(4, origin)
			spell_active = true
			print("light!")
		EffectType.FOG:
			active_spell._initialize(5, origin)
			spell_active = true
			print("fog!")

func _deactivate_spell():
	active_spell._destroy()
	active_spell = null
	spell_active = false

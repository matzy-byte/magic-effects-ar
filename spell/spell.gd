class_name Spell
extends Area3D

@export var spell_sound : AudioStreamPlayer3D
@export var spell_type : int

var target_origin: Vector3
var follow_speed := 32.0

var effect : Node = null

func _process(delta):
	position = position.lerp(target_origin, follow_speed * delta)

func _initialize(type: int, origin: Vector3) -> void:
	position = Vector3(origin.x, origin.y, -1.5)
	spell_type = type

	match type:
		0:
			var scene = load("res://spell/fire.tscn")
			var instance = scene.instantiate()
			add_child(instance)
			effect = instance
			spell_sound.stream = load("res://audio/fire_sfx.wav")
		1:
			var scene = load("res://spell/water.tscn")
			var instance = scene.instantiate()
			add_child(instance)
			effect = instance
			spell_sound.stream = load("res://audio/water_sfx.wav")
		2:
			var scene = load("res://spell/lightning.tscn")
			var instance = scene.instantiate()
			add_child(instance)
			effect = instance
			spell_sound.stream = load("res://audio/electrical_sfx.wav")
		3:
			var scene = load("res://spell/earth.tscn")
			var instance = scene.instantiate()
			add_child(instance)
			effect = instance
			spell_sound.stream = load("res://audio/earth_sfx.wav")
		4:
			var scene = load("res://spell/light.tscn")
			var instance = scene.instantiate()
			add_child(instance)
			effect = instance
			spell_sound.stream = load("res://audio/light_sfx.wav")
		5:
			var scene = load("res://spell/fog.tscn")
			var instance = scene.instantiate()
			add_child(instance)
			effect = instance
			spell_sound.stream = load("res://audio/mist_sfx.wav")
	
	spell_sound.play()

func _destroy():
	queue_free()

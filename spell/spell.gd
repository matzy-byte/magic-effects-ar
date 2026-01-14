class_name Spell
extends Area3D

@export var spell_sound : AudioStreamPlayer3D
@export var spell_type : int

var active_spell := false

var target_origin: Vector3
var follow_speed := 30.0

func _process(delta):
    position = position.lerp(target_origin, follow_speed * delta)

func _initialize(type: int, origin: Vector3) -> void:
    active_spell = true
    position = Vector3(origin.x, origin.y, -1.5)
    spell_type = 0
    var stream = AudioStream.new()
    match type:
        0:
            # stream.resource_path = "res://audio/fire_sfx.wav"
            pass
        1:
            stream.resource_path = "res://audio/earth_sfx.wav"
        2:
            stream.resource_path = "res://audio/electrical_sfx.wav"
        3:
            stream.resource_path = "res://audio/light_sfx.wav"
        4:
            stream.resource_path = "res://audio/mist_sfx.wav"
        5:
            stream.resource_path = "res://audio/water_sfx.wav"
    # spell_sound.stream = stream
    # spell_sound.play()

func _destroy():
    active_spell = false
    queue_free()


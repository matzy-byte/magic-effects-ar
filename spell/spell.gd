class_name Spell
extends Area3D

@export var spell_sound : AudioStreamPlayer3D
@export var spell_type : int

func _initialize(type: int) -> void:
    spell_type = 0
    var stream = AudioStream.new()
    match type:
        0:
            stream.resource_path = "res://audio/fire_sfx.wav"
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
    spell_sound.stream = stream
    spell_sound.play()

func _destroy():
    queue_free()

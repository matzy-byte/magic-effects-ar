extends CharacterBody3D

@export var animator : AnimationTree

func _enemy_hit():
	animator.set("parameters/conditions/is_hit", true)
	await get_tree().create_timer(0.1).timeout
	animator.set("parameters/conditions/is_hit", false)

func _enemy_dead():
	animator.set("parameters/conditions/is_dead", true)

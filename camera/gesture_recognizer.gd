extends WebCamera

@onready var game := get_node("/root/game")

var task: MediaPipeGestureRecognizer
var task_file := "camera/gesture_recognizer.task"
var renderer: MediaPipeHandRenderer

var gesture_history: Array[String] = []
var last_effect: EffectType = -1
var max_skips = 5

enum EffectType {
	FIRE,
	WATER,
	LIGHTNING,
	EARTH,
	LIGHT,
	FOG
}

signal effect_triggered(effect_type: EffectType, origin: Vector3)

const EFFECT_PATTERNS := {
	EffectType.FIRE: ["point", "flat", "greetings", "flat"],
	EffectType.WATER: ["heart", "okay", "cross", "flat"],
	EffectType.LIGHTNING: ["point", "okay", "call", "flat"],
	EffectType.EARTH: ["c", "metal", "okay", "flat"],
	EffectType.LIGHT: ["point", "call", "cross", "flat"],
	EffectType.FOG: ["heart", "greetings", "c", "flat"],
}

var center_pos := Vector3.ZERO


func _ready() -> void:
	var file := _get_model(task_file)
	if file == null:
		return

	var base_options := MediaPipeTaskBaseOptions.new()
	base_options.delegate = delegate
	base_options.model_asset_buffer = file.get_buffer(file.get_length())

	task = MediaPipeGestureRecognizer.new()
	task.initialize(base_options, running_mode)
	task.result_callback.connect(_result_callback)

	renderer = MediaPipeHandRenderer.new()
	super ()


func _process_camera(image: MediaPipeImage, timestamp_ms: int) -> void:
	if image:
		task.recognize_async(image, timestamp_ms)


func _result_callback(result: MediaPipeGestureRecognizerResult, image: MediaPipeImage, _timestamp_ms: int) -> void:
	_handle_gestures(result)
	call_deferred("_update_from_mediapipe", result)


func _handle_gestures(result: MediaPipeGestureRecognizerResult) -> void:
	for i in result.gestures.size():
		var gesture_label: String = result.gestures[i].categories[0].category_name
		var gesture_name := gesture_label.split(" ")[0]

		if gesture_history.is_empty() or gesture_history.back() != gesture_name:
			if gesture_history.size() >= 10:
				gesture_history.pop_front()
			gesture_history.append(gesture_name)
			print(gesture_name)

		if gesture_name == "flat":
			_calculate_effect()


func _update_from_mediapipe(result: MediaPipeGestureRecognizerResult) -> void:
	if gesture_history.is_empty():
		return

	var last_gesture = gesture_history.back()

	for i in result.hand_landmarks.size():
		var lms = result.hand_landmarks[i].landmarks
		var hand_points: Array[Vector3] = []

		for lm in lms:
			hand_points.append(Vector3(lm.x, lm.y, lm.z))

		center_pos = _calculate_hand_center(hand_points)
		game.latest_center_pos = center_pos

		if last_gesture == "fist" and game.spell_active:
			game._deactivate_spell()


func _calculate_effect() -> void:
	if gesture_history.is_empty():
		return

	for effect in EFFECT_PATTERNS.keys():
		var pattern: Array = EFFECT_PATTERNS[effect]
		var p_idx := pattern.size() - 1
		var h_idx := gesture_history.size() - 1
		var skips := 0

		while p_idx >= 0 and h_idx >= 0:
			if gesture_history[h_idx] == pattern[p_idx]:
				p_idx -= 1
			else:
				skips += 1
				if skips > max_skips:
					break
			h_idx -= 1

		if p_idx < 0:
			if effect != last_effect or game.spell_active == false:
				last_effect = effect
				call_deferred("_emit_effect", effect, center_pos)
				gesture_history.clear()
			return



func _emit_effect(effect: EffectType, origin: Vector3) -> void:
	effect_triggered.emit(effect, origin)


func _get_model(path: String) -> FileAccess:
	if FileAccess.file_exists(path):
		return FileAccess.open(path, FileAccess.READ)
	return null


func _calculate_hand_center(hand: Array[Vector3]) -> Vector3:
	var palm_indices := [0, 1, 5, 9, 13, 17]
	var center := Vector3.ZERO

	for idx in palm_indices:
		center += hand[idx]

	center /= palm_indices.size()

	var min := Vector3(4, 2.25, -2)
	var max := Vector3(-4, -2.25, -2)

	center.x = min.x + (max.x - min.x) * center.x
	center.y = min.y + (max.y - min.y) * center.y
	center.z = min.z + (max.z - min.z) * center.z

	return center

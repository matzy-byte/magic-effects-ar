extends WebCamera

@onready var game := get_node("/root/game")

var task: MediaPipeGestureRecognizer
var task_file := "camera/gesture_recognizer.task"
var renderer: MediaPipeHandRenderer

var arr_gestures: Array = []
var arr_gestures_name := []
var last_effect = null

var fire_effect := ["metal", "cross", "c", "flat"]
var water_effect := ["heart", "okay", "cross", "flat"]
var lightning_effect := ["point", "okay", "call", "flat"]
var earth_effect := ["c", "metal", "okay", "flat"]
var light_effect := ["point", "call", "cross", "flat"]
var fog_effect := ["heart", "greetings", "c", "flat"]
var ghost := ["call", "greetings", "heart", "flat"]

enum EffectType {
    FIRE, 
    WATER,
    LIGHTNING,
    EARTH,
    LIGHT,
    FOG,
    GHOST
}

signal effect_triggered(effect_type: EffectType)

var center_pos := Vector3.ZERO
var center_vp := Vector2.ZERO
var point_pos := Vector2.ZERO

func _result_callback(result: MediaPipeGestureRecognizerResult, image: MediaPipeImage, _timestamp_ms: int) -> void:
    show_result(image, result)
    call_deferred("_apply_mediapipe_update", result)

func _apply_mediapipe_update(result):    
    update_from_mediapipe(result) 

func _ready() -> void:
    var file := get_model(task_file)
    if file == null:
        return
    var base_options := MediaPipeTaskBaseOptions.new()
    base_options.delegate = delegate
    base_options.model_asset_buffer = file.get_buffer(file.get_length())
    task = MediaPipeGestureRecognizer.new()
    task.initialize(base_options, running_mode)
    task.result_callback.connect(self._result_callback)
    renderer = MediaPipeHandRenderer.new()
    super()

func _process_camera(image: MediaPipeImage, timestamp_ms: int) -> void:
    if image != null:
        task.recognize_async(image, timestamp_ms)

func show_result(_image: MediaPipeImage, result: MediaPipeGestureRecognizerResult) -> void:
    var _gesture_text := ""
    assert(result.gestures.size() == result.handedness.size())
    for i in range(result.gestures.size()):
        var gesture := result.gestures[i]
        var hand := result.handedness[i]
        var classification_gesture := gesture.categories[0]
        var classification_hand := hand.categories[0]
        var gesture_label: String = classification_gesture.category_name
        var gesture_score: float = classification_gesture.score
        
        var gesture_name = gesture_label.split(" ")[0]
        if arr_gestures_name.back() == "flat":
            calcluate_effect()
        if arr_gestures.back() != gesture_label:
            if len(arr_gestures) >= 10:
                arr_gestures.pop_at(0)
            arr_gestures.append(gesture_label)
            arr_gestures_name.append(gesture_name)
            print(arr_gestures_name.back())

        var hand_label: String = classification_hand.category_name
        var hand_score: float = classification_hand.score
        _gesture_text += "%s: %.2f\n%s: %.2f\n\n" % [hand_label, hand_score, gesture_label, gesture_score]
    return

func get_model(path: String) -> FileAccess:
    if FileAccess.file_exists(path):
        return FileAccess.open(path, FileAccess.READ)
    return null

func calcluate_effect() -> void:
    var current_gestures = arr_gestures_name.slice(-4)
    var new_effect = null

    match current_gestures:
        fire_effect: 
            new_effect = EffectType.FIRE
        water_effect:
            new_effect = EffectType.WATER
        lightning_effect: 
            new_effect = EffectType.LIGHTNING
        earth_effect: 
            new_effect = EffectType.EARTH
        light_effect: 
            new_effect = EffectType.LIGHT
        fog_effect: 
            new_effect = EffectType.FOG
        ghost: 
            new_effect = EffectType.GHOST
    
    if new_effect != null and new_effect != last_effect:
        last_effect = new_effect
        call_deferred("_emit_effect", new_effect, center_pos)

func _emit_effect(effect: EffectType, origin: Vector3) -> void:
    effect_triggered.emit(effect, origin)
func update_from_mediapipe(result: MediaPipeGestureRecognizerResult):
    # assert(result.gestures.size() == result.handedness.size())
    for i in range(result.gestures.size()):
        var hand_lms = result.hand_landmarks[i].landmarks

        var hand_array = []
        for j in range(hand_lms.size()):
            var lm = hand_lms[j]
            hand_array.append(Vector3(lm.x, lm.y, lm.z))
        
        if arr_gestures_name.back() == "flat":
            center_pos = calculate_hand_center(hand_array)
            game.latest_center_pos = center_pos

            if viewport is SubViewport:
                center_vp = Vector2((1.0 - center_pos.x) * viewport.size.x, center_pos.y * viewport.size.y) 
                overlay.set_allow_redraw(true)
                overlay.set_center(center_vp) 
        else:
            overlay.set_allow_redraw(false)

func calculate_hand_center(hand_array) -> Vector3: 
    var result := Vector3.ZERO
    var palm := [hand_array[0], hand_array[1], hand_array[5], hand_array[9], hand_array[13], hand_array[17]]
    
    for i in palm:
        result.x += i.x
        result.y += i.y
        result.z += i.z
    
    result.x = result.x / palm.size()
    result.y = result.y / palm.size()
    result.z = result.z / palm.size()

    var minimum := Vector3(1.5, 0.5, -1.5)
    var maximum := Vector3(-1.5, -0.5, -1.5)

    result.x = minimum.x + (maximum.x - minimum.x) * result.x
    result.y = minimum.y + (maximum.y - minimum.y) * result.y
    result.z = minimum.z + (maximum.z - minimum.z) * result.z

    return result

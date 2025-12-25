extends WebCamera

var task: MediaPipeGestureRecognizer
var task_file := "camera/gesture_recognizer.task"
var renderer: MediaPipeHandRenderer

var arr_gestures: Array = []
var arr_gestures_name := []
var left_hand_landmarks = []
var right_hand_landmarks = []

var center_pos := Vector3.ZERO
var center_vp := Vector2.ZERO
var point_pos := Vector2.ZERO

func _draw():
    # print(center_vp)
    draw_circle(center_vp, 75, Color.RED)

func _result_callback(result: MediaPipeGestureRecognizerResult, image: MediaPipeImage, _timestamp_ms: int) -> void:
    show_result(image, result)
    call_deferred("_apply_mediapipe_update", result)

func _apply_mediapipe_update(result):    
    update_from_mediapipe(result)
    queue_redraw() 

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
        if arr_gestures.back() != gesture_label:
            calcluate_effect()
            if len(arr_gestures) > 10:
                arr_gestures.clear()
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
    var fire_effect := ["fist", "point"]

    # print(arr_gestures_name.slice(-2))
    if arr_gestures_name.slice(-2) == fire_effect:
        print("Effect: Fire!")

func update_from_mediapipe(result: MediaPipeGestureRecognizerResult):
    left_hand_landmarks.clear()
    right_hand_landmarks.clear()

    assert(result.gestures.size() == result.handedness.size())
    for i in range(result.gestures.size()):
        var hand_lms = result.hand_landmarks[i].landmarks

        var hand_array = []
        for j in range(hand_lms.size()):
            var lm = hand_lms[j]
            hand_array.append(Vector3(lm.x, lm.y, lm.z))

        var handedness := result.handedness[i] 
        var classification_hand := handedness.categories[0]
        var hand_label: String = classification_hand.category_name
        if hand_label == "Left":
            left_hand_landmarks = hand_array
        else:
            right_hand_landmarks = hand_array
        
        center_pos = calculate_hand_center()
        center_vp = Vector2((1.0 - center_pos.x) * vp.size.x, center_pos.y * vp.size.y)  

func calculate_hand_center() -> Vector3: 
    var result := Vector3.ZERO
    if left_hand_landmarks.size() > 0:
        for i in left_hand_landmarks:
            result.x += i.x
            result.y += i.y
            result.z += i.z

        result.x = result.x / left_hand_landmarks.size()
        result.y = result.y / left_hand_landmarks.size()
        result.z = result.z / left_hand_landmarks.size()
        
        return result
    else:
        for i in right_hand_landmarks:
            result.x += i.x
            result.y += i.y
            result.z += i.z

        result.x = result.x / left_hand_landmarks.size()
        result.y = result.y / left_hand_landmarks.size()
        result.z = result.z / left_hand_landmarks.size()
        
        return result

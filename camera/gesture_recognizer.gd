extends Camera

var task: MediaPipeGestureRecognizer
var task_file := "camera/gesture_recognizer.task"
var renderer: MediaPipeHandRenderer

@onready var lbl_gesture: Label = $Gesture

func _result_callback(result: MediaPipeGestureRecognizerResult, image: MediaPipeImage, _timestamp_ms: int) -> void:
    show_result(image, result)

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
    print("Function to process camera started.")
    if image != null:
        task.recognize_async(image, timestamp_ms)

func show_result(image: MediaPipeImage, result: MediaPipeGestureRecognizerResult) -> void:
    var gesture_text := ""
    assert(result.gestures.size() == result.handedness.size())
    for i in range(result.gestures.size()):
        var gesture := result.gestures[i]
        var hand := result.handedness[i]
        var classification_gesture := gesture.categories[0]
        var classification_hand := hand.categories[0]
        var gesture_label: String = classification_gesture.category_name
        var gesture_score: float = classification_gesture.score
        var hand_label: String = classification_hand.category_name
        var hand_score: float = classification_hand.score
        gesture_text += "%s: %.2f\n%s: %.2f\n\n" % [hand_label, hand_score, gesture_label, gesture_score]
    # lbl_gesture.call_deferred("set_text", gesture_text)
    print("Gesture: ", gesture_text)
    return

func get_model(path: String) -> FileAccess:
    if FileAccess.file_exists(path):
        return FileAccess.open(path, FileAccess.READ)
    return null
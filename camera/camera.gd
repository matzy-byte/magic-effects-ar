class_name WebCamera
extends Control

var frame_skip := 1

var running_mode := MediaPipeVisionTask.RUNNING_MODE_LIVE_STREAM
var delegate := MediaPipeTaskBaseOptions.DELEGATE_CPU

var camera_extension := CameraServerExtension.new()
var camera_feed: CameraFeed

var _frame_counter := 0


@onready var camera_texture: TextureRect = $TextureRect
@onready var viewport := get_parent() as SubViewport
@onready var overlay: Control = $Overlay


func _ready() -> void:
    CameraServer.monitoring_feeds = true

    if camera_extension.permission_granted():
        _init_camera_feed()
    else:
        camera_extension.permission_result.connect(_on_permission_result)
        camera_extension.request_permission()


func _exit_tree() -> void:
    _reset_camera_feed()


func _on_permission_result(granted: bool) -> void:
    if not granted:
        push_error("Camera access permission not granted.")
        return
    _init_camera_feed()


func _reset_camera_feed() -> void:
    if camera_feed == null:
        return

    camera_feed.feed_is_active = false

    if camera_feed.format_changed.is_connected(_camera_format_changed):
        camera_feed.format_changed.disconnect(_camera_format_changed)

    if camera_feed.frame_changed.is_connected(_camera_frame_changed):
        camera_feed.frame_changed.disconnect(_camera_frame_changed)

    camera_feed = null


func _init_camera_feed() -> void:
    _reset_camera_feed()

    if CameraServer.get_feed_count() == 0:
        push_error("No camera feed found.")
        return

    camera_feed = CameraServer.get_feed(0)

    if not (camera_feed is CameraFeedExtension):
        push_error("Camera feed is not a CameraFeedExtension.")
        return

    _select_preferred_format(camera_feed)

    camera_texture.flip_h = camera_feed.get_position() != CameraFeed.FEED_BACK

    camera_feed.format_changed.connect(_camera_format_changed, ConnectFlags.CONNECT_DEFERRED)
    camera_feed.frame_changed.connect(_camera_frame_changed, ConnectFlags.CONNECT_DEFERRED)

    camera_feed.feed_is_active = true
    _camera_format_changed()

    print("Camera feed initialized.")


func _select_preferred_format(feed: CameraFeedExtension) -> void:
    var formats = feed.get_formats()

    for i in formats.size():
        var f = formats[i]
        if f.get("width") == 1280 and f.get("height") == 720 and f.get("format") == "MJPG":
            var success := feed.set_format(i, f)
            print("Setting format:", f, "->", success)
            return


func _camera_format_changed() -> void:
    if camera_feed == null:
        return

    var frame_size := camera_texture.size

    match camera_feed.get_datatype():
        CameraFeed.FEED_RGB:
            var texture := CameraTexture.new()
            texture.camera_feed_id = camera_feed.get_id()
            texture.which_feed = CameraServer.FEED_RGBA_IMAGE
            frame_size = texture.get_size()
            camera_texture.texture = texture

        CameraFeed.FEED_YCBCR, CameraFeed.FEED_YCBCR_SEP:
            print("YCbCr feed type not supported for processing.")
            return

        _:
            return

    var feed_rotation := camera_feed.feed_transform.get_rotation()
    camera_texture.flip_h = true

    var size_rotated := frame_size.rotated(feed_rotation)
    var offset := Vector2(min(size_rotated.x, 0), min(size_rotated.y, 0))

    rotation = feed_rotation
    position = -offset


func _camera_frame_changed() -> void:
    _frame_counter += 1
    if _frame_counter <= frame_skip:
        return
    _frame_counter = 0

    if camera_texture == null:
        return

    await RenderingServer.frame_post_draw

    var texture := camera_texture.texture
    if texture == null:
        return

    var image := texture.get_image()
    if image == null:
        return

    if delegate == MediaPipeTaskBaseOptions.DELEGATE_GPU:
        image.convert(Image.FORMAT_RGBA8)
    else:
        image.convert(Image.FORMAT_RGB8)

    var mp_image := MediaPipeImage.new()
    mp_image.set_image(image)

    _camera_frame(mp_image)


func _camera_frame(image: MediaPipeImage) -> void:
    if delegate == MediaPipeTaskBaseOptions.DELEGATE_CPU and image.is_gpu_image():
        image.convert_to_cpu()

    _process_camera(image, Time.get_ticks_msec())


func _process_camera(_image: MediaPipeImage, _timestamp_ms: int) -> void:
    pass


func _process_image(_image: Image) -> void:
    pass

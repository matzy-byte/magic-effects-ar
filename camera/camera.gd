class_name Camera
extends Control

var camera_extension := CameraServerExtension.new()
var camera_feed
var running_mode := MediaPipeVisionTask.RUNNING_MODE_LIVE_STREAM
var request: HTTPRequest
var delegate := MediaPipeTaskBaseOptions.DELEGATE_CPU

@onready var camera_texture: TextureRect = $TextureRect

func _ready():
    CameraServer.monitoring_feeds = true

    if camera_extension.permission_granted():
        _init_camera_feed()
    else:
        var _on_permission_result = func(granted: bool) -> void:
            if not granted:
                print("Camera access permission not granted")
                return
        _init_camera_feed()
        camera_extension.permission_result.connect(_on_permission_result)
        camera_extension.request_permission()

func _reset() -> void:
    if camera_feed == null:
        return
    camera_feed.feed_is_active = false
    if camera_feed.format_changed.is_connected(self._camera_format_changed):
        camera_feed.format_changed.disconnect(self._camera_format_changed)
    if camera_feed.frame_changed.is_connected(self._camera_frame_changed):
        camera_feed.frame_changed.disconnect(self._camera_frame_changed)

func _init_task() -> void:
    if not OS.get_name() in ["Android", "iOS", "Linux"]:
        print("Cool.")
    else:
        print("Auch cool.")

func _init_camera_feed():
    _reset()
    if CameraServer.get_feed_count() == 0:
        print("No camera feed found")
        return
    
    camera_feed = CameraServer.get_feed(0)

    if typeof(camera_feed) == TYPE_OBJECT and camera_feed is CameraFeedExtension:
        var formats = camera_feed.get_formats()
        # print(formats)

        for i in range(formats.size()):
            var format = formats[i]
            if format["width"] == 1280 and format["height"] == 720 and format["format"] == "MJPG":
                var success = camera_feed.set_format(i, format)
                print("Setting format to: ", format, "-->", success)
                break

        if camera_feed == null:
            return
        if camera_feed.get_position() == CameraFeed.FEED_BACK:
            camera_texture.flip_h = false
        else:
            camera_texture.flip_h = true
        camera_feed.format_changed.connect(self._camera_format_changed, ConnectFlags.CONNECT_DEFERRED)
        camera_feed.frame_changed.connect(self._camera_frame_changed, ConnectFlags.CONNECT_DEFERRED)
        camera_feed.feed_is_active = true
        _camera_format_changed()

        print("Camera feed initialized and applied.")
    else:
        print("CameraFeed Type is not Extension.")

func _camera_format_changed() -> void:
    if camera_feed == null:
        return
    var frame_size := camera_texture.size
    match camera_feed.get_datatype():
        CameraFeed.FEED_RGB:
            print("Type: RGB")
            var texture = CameraTexture.new()
            texture.camera_feed_id = camera_feed.get_id()
            texture.which_feed = CameraServer.FEED_RGBA_IMAGE
            frame_size = texture.get_size()
            print("Frame size: ", frame_size)
            camera_texture.texture = texture
            # flip_h = true  
        CameraFeed.FEED_YCBCR:
            print("Type: YCBCR")
        CameraFeed.FEED_YCBCR_SEP:
            print("Type: YCBR_SEP")
        _:
            return
        
    var feed_rotation: float = camera_feed.feed_transform.get_rotation()
    camera_texture.flip_h = true
    var size_rotated := Vector2(frame_size).rotated(feed_rotation)
    var offset_num := Vector2(min(size_rotated.x, 0), min(size_rotated.y, 0))
    rotation = feed_rotation
    position = offset_num * -1

func _camera_frame_changed() -> void:
    if camera_texture == null:
        return
    await RenderingServer.frame_post_draw
    var texture := camera_texture.get_texture()
    if texture == null:
        return
    var image = texture.get_image()
    if image == null:
        return    
    if delegate == MediaPipeTaskBaseOptions.DELEGATE_GPU:
        image.convert(Image.FORMAT_RGBA8)
    else:
        image.convert(Image.FORMAT_RGB8)
    var img := MediaPipeImage.new()
    img.set_image(image)
    _camera_frame(img)

func _camera_frame(image: MediaPipeImage) -> void:
    if delegate == MediaPipeTaskBaseOptions.DELEGATE_CPU and image.is_gpu_image():
        image.convert_to_cpu()
    _process_camera(image, Time.get_ticks_msec())

func _process_camera(_image: MediaPipeImage, _timestamp_ms: int) -> void:
    pass

func _process_image(_image: Image) -> void:
    pass

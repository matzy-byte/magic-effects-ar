extends Control

var camera_extension := CameraServerExtension.new()
var camera_feed

@onready var camera_texture := $TextureRect

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
    

func _init_camera_feed():
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

        camera_feed.feed_is_active = true
        var frame_size := Vector2i.ZERO
        match camera_feed.get_datatype():
            CameraFeed.FEED_RGB:
                print("Type: RGB")
                var texture = CameraTexture.new()
                texture.camera_feed_id = camera_feed.get_id()
                texture.which_feed = CameraServer.FEED_RGBA_IMAGE
                frame_size = texture.get_size()
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

        print("CameraFeed active:", camera_feed.feed_is_active)
        print("Transform:", camera_feed.feed_transform)
        print("Camera feed initialized and applied.")
    else:
        print("CameraFeed Type is not Extension.")

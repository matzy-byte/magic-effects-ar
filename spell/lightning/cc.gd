@tool
extends EditorScript

const INPUT_DIR := "res://spell/lightning"
const OUTPUT_FILE := "res://spell/lightning/lightning_anim_texture.tres"
const FPS := 12


func _run():
	var dir := DirAccess.open(INPUT_DIR)
	if dir == null:
		push_error("Cannot open directory: " + INPUT_DIR)
		return

	var files: Array[String] = []

	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.to_lower().ends_with(".png"):
			files.append(f)
		f = dir.get_next()
	dir.list_dir_end()

	if files.is_empty():
		push_error("No PNG files found in " + INPUT_DIR)
		return

	files.sort() # works for 00xx.png naming

	var anim := AnimatedTexture.new()
	anim.frames = files.size()

	for i in files.size():
		var path = INPUT_DIR + "/" + files[i]
		var tex: Texture2D = load(path)
		if tex == null:
			push_error("Failed to load: " + path)
			continue
		anim.set_frame_texture(i, tex)
		anim.set_frame_duration(i, 0.01)

	var err = ResourceSaver.save(anim, OUTPUT_FILE)
	if err != OK:
		push_error("Failed to save AnimatedTexture: " + str(err))
	else:
		print("AnimatedTexture created: ", OUTPUT_FILE)

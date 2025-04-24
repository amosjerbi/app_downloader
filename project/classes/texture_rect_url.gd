@tool
class_name TextureRectUrl
extends TextureRect

var http_request := HTTPRequest.new()
var overlay_texture := TextureRect.new()
var overlay_margin := MarginContainer.new()
var file_name := ""
var file_ext := ""

## URL to fetch texture from
@export var texture_url = "":
	set(value):
		texture_url = value
		if autoload:
			load_image()
## Whether to cache downloaded images
@export var store_cache: bool = true
## Whether to autoload the image when url changes
@export var autoload := true:
	set(value):
		autoload = value
		if autoload:
			if !http_request.is_inside_tree():
				http_request.use_threads = true
				http_request.request_completed.connect(_on_request_completed)
				call_deferred("add_child", http_request)
			load_image()
## Texture to show while loading
@export var loading_texture: Texture2D
## Texture to show if loading failed
@export var fail_texture: Texture2D
## Margins on the edges of the overlay texture (loading, failure)
@export var overlay_margins: int = 10

const CACHE_DIR = "user://cache/"

signal load_success(image: Texture, fromCache: bool)
signal load_failed

func _ready():
	if store_cache:
		# Add cache directory
		DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	
	if !http_request.is_inside_tree():
		http_request.use_threads = true
		http_request.request_completed.connect(_on_request_completed)
		add_child(http_request, false, Node.INTERNAL_MODE_FRONT)
	
	resized.connect(_update_overlay)
	if !overlay_margin.is_inside_tree():
		overlay_margin.add_theme_constant_override("margin_left", overlay_margins)
		overlay_margin.add_theme_constant_override("margin_right", overlay_margins)
		overlay_margin.add_theme_constant_override("margin_up", overlay_margins)
		overlay_margin.add_theme_constant_override("margin_down", overlay_margins)
		overlay_margin.custom_minimum_size = size
		add_child(overlay_margin, false, Node.INTERNAL_MODE_FRONT)
	if !overlay_texture.is_inside_tree():
		overlay_texture.texture = loading_texture
		overlay_texture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		overlay_texture.hide()
		overlay_margin.add_child(overlay_texture, false, Node.INTERNAL_MODE_FRONT)
	
	load_image()

func load_image():
	http_request.cancel_request()
	if texture_url == "":
		_load_failed()
		return
	
	overlay_texture.show()
	
	var dt = texture_url.split(":")
	if dt[0] == "data":
		_base64texture(texture_url)
		return

	file_ext = texture_url.get_extension()
	file_name = str(texture_url.hash(),".",file_ext)
	
	if !Engine.is_editor_hint():
	
		if FileAccess.file_exists(str(CACHE_DIR, file_name)):
			var _image = Image.new()
			_image.load(str(CACHE_DIR, file_name))
			var _texture = ImageTexture.create_from_image(_image)
			texture = _texture
			overlay_texture.hide()
			if !Engine.is_editor_hint():
				load_success.emit(_texture, true)
				return
	
	if file_ext != "":
		_download_image()

func _update_overlay() -> void:
	overlay_margin.custom_minimum_size = size

func _download_image():
	texture = null
	http_request.cancel_request()
	if texture_url != "":
		http_request.request(texture_url)
	else:
		_load_failed()

func _on_request_completed(result, response_code, _headers, body):
	if response_code == 200 and result == HTTPRequest.RESULT_SUCCESS:
		var image = Image.new()
		var image_error = null
		
		if file_ext == "png":
			image_error = image.load_png_from_buffer(body)
		elif file_ext == "jpg" or file_ext == "jpeg":
			image_error = image.load_jpg_from_buffer(body)
		elif file_ext == "webp":
			image_error = image.load_webp_from_buffer(body)
			
		if image_error != OK:
			# An error occurred while trying to display the image
			_load_failed()
			return
	
		var _texture: ImageTexture = ImageTexture.create_from_image(image)
		overlay_texture.hide()
		if !Engine.is_editor_hint():
			load_success.emit(_texture, false)
		
		if store_cache:
			match file_ext:
				"png":
					image.save_png(str(CACHE_DIR, file_name))
				"jpg":
					image.save_jpg(str(CACHE_DIR, file_name))
				"jpeg":
					image.save_jpg(str(CACHE_DIR, file_name))
				"webp":
					image.save_webp(str(CACHE_DIR, file_name))
				_:
					print("Failed to save image to cache")
	
		# Assign a downloaded texture
		texture = _texture
	else:
		_load_failed()

func _base64texture(image64: String):
	var image := Image.new()
	var tmp: String = image64.split(",")[1]

	if not image.load_png_from_buffer(Marshalls.base64_to_raw(tmp)) == OK:
		_load_failed()
		return
	var _texture := ImageTexture.create_from_image(image)
	texture = _texture
	overlay_texture.hide()
	if !Engine.is_editor_hint():
		load_success.emit(image, false)

func _load_failed():
	texture = fail_texture
	overlay_texture.hide()
	load_failed.emit()

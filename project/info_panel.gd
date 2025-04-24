extends Control

signal download_pressed
signal closed

const ANIM_DURATION: float = 0.3

@onready var panel_container := %PanelContainer
@onready var color_rect := %ColorRect
@onready var overlay := %Overlay
@onready var download_button: Button = %DownloadButton
@onready var app_desc: RichTextLabel = %AppDesc

var _is_open := false
var _tween: Tween

func _ready() -> void:
	if not _is_open:
		overlay.position.x = panel_container.get_rect().size.x
	show()
	download_button.pressed.connect(func(): download_pressed.emit())

func _process(delta):
	color_rect.modulate = lerp(color_rect.modulate, Color.WHITE if _is_open else Color.TRANSPARENT, delta * 7.0)
	if not _is_open or (_tween and _tween.is_running()):
		return
	if Input.is_action_pressed("ui_down"):
		app_desc.get_v_scroll_bar().value += 1
	elif Input.is_action_pressed("ui_up"):
		app_desc.get_v_scroll_bar().value -= 1

func open() -> void:
	if _is_open:
		return
	_ensure_tween()
	_tween.tween_property(overlay, "position:x", 0, ANIM_DURATION)
	_is_open = true
	download_button.grab_focus()

func close() -> void:
	if not _is_open:
		return
	_ensure_tween()
	_tween.tween_property(overlay, "position:x", panel_container.get_rect().size.x, ANIM_DURATION)
	_is_open = false
	closed.emit()

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func is_open() -> bool:
	return _is_open

func _ensure_tween() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)

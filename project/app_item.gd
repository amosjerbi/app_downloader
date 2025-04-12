@tool
class_name AppItem
extends Container

signal pressed

@onready var texture_rect: TextureRectUrl = %TextureRect
@onready var label: Label = %Label
@onready var highlight = %Highlight

@export var app_title: String:
	set(value):
		app_title = value
		if label:
			label.text = app_title
@export var app_image_url: String:
	set(value):
		app_image_url = value
		if texture_rect:
			texture_rect.texture_url = app_image_url

func _ready():
	app_title = app_title
	app_image_url = app_image_url
	highlight.hide()
	
	focus_entered.connect(_focus_entered)
	focus_exited.connect(_focus_exited)

func _focus_entered():
	highlight.show()

func _focus_exited():
	highlight.hide()

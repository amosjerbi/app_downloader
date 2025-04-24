class_name Main
extends CanvasLayer

const APP_ITEM = preload("res://app_item.tscn")
const APPS_LIST_URL := "https://raw.githubusercontent.com/andersmmg/app_downloader/refs/heads/main/apps_listing.json"
const ALLOWED_EXT := ['muxzip','muxupd','muxapp']
const DISALLOWED_PHRASES := []

var DOWNLOAD_LOCATION: String

@onready var http_downloader: HTTPRequest = $HTTPDownloader
@onready var apps_list: GridContainer = %AppsList
@onready var loading_overlay: Control = %LoadingOverlay
@onready var app_desc: RichTextLabel = %AppDesc
@onready var app_image: TextureRectUrl = %AppImage
@onready var app_title: Label = %AppTitle
@onready var download_overlay: Container = %DownloadOverlay
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_label: Label = %ProgressLabel
@onready var error_label: Label = %ErrorLabel
@onready var success_label: Label = %SuccessLabel
@onready var loading_label: Label = %LoadingLabel
@onready var quit_prompt: Container = %QuitPrompt
@onready var offline_icon: TextureRect = %OfflineIcon
@onready var no_image_label = %NoImageLabel
@onready var info_panel: InfoPanel = $InfoPanel
@onready var loading_icon = %LoadingIcon

var apps: Array[AppItemData]
var selected_app: AppItemData
var download_target: String
var is_downloading: bool = false
var last_selected_app: Control

var message_countdown: float = 0

func _init() -> void:
	if OS.is_debug_build():
		DOWNLOAD_LOCATION = "user://downloads/"
	else:
		DOWNLOAD_LOCATION = "/mnt/mmc/ARCHIVE/"
	print("App is running")

func _ready() -> void:
	quit_prompt.hide()
	offline_icon.hide()
	loading_icon.show()
	error_label.hide()
	success_label.hide()
	no_image_label.hide()
	DirAccess.make_dir_absolute(DOWNLOAD_LOCATION)
	progress_bar.value = 0
	loading_overlay.show()
	download_overlay.hide()
	http_downloader.request_completed.connect(_on_http_downloader_request_completed)
	app_image.load_failed.connect(_image_load_failed)
	app_image.load_success.connect(_image_load_success)
	info_panel.download_pressed.connect(_download_pressed)
	info_panel.closed.connect(_panel_closed)
	_get_store()

func _process(delta) -> void:
	if message_countdown > 0:
		message_countdown -= delta
	else:
		error_label.hide()
		success_label.hide()
	
	if loading_overlay.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			get_tree().quit()
	elif download_overlay.visible:
		_update_download_progress()
	elif info_panel.is_open():
		if Input.is_action_just_pressed("ui_cancel"):
			info_panel.close()
	else:
		if Input.is_action_just_pressed("ui_cancel"):
			get_tree().quit()
		if Input.is_action_just_pressed("ui_select"):
			if selected_app:
				_store_last_selected()
				info_panel.open()

func _panel_closed() -> void:
	if last_selected_app:
		last_selected_app.grab_focus()

func _store_last_selected():
	last_selected_app = null
	for i in apps_list.get_children():
		if i.has_focus():
			last_selected_app = i
			return

func _download_pressed() -> void:
	check_latest_release(selected_app.repo)

func _update_download_progress() -> void:
	if not is_downloading:
		progress_bar.value = 0
		return
	var body_size := http_downloader.get_body_size()
	var downloaded_bytes := http_downloader.get_downloaded_bytes()
	var percent: float = downloaded_bytes*100.0 / body_size
	progress_bar.value = percent

func _get_store() -> void:
	var resp: HTTPResult = await HTTP.async_request(APPS_LIST_URL)
	if resp.success() and resp.status_ok():
		var json = resp.body_as_json()
		if json is Array:
			_show_data(_process_data(json))
	else:
		loading_label.text = "Failed to load data. Are you online?"
		quit_prompt.show()
		offline_icon.show()
		loading_icon.hide()

func _sort_apps(a: AppItemData, b: AppItemData) -> bool:
	return a.title.naturalnocasecmp_to(b.title) < 0

func _process_data(raw_data: Array) -> Array[AppItemData]:
	var new_data: Array[AppItemData] = []
	for i in raw_data:
		if i.has('title'):
			new_data.append(AppItemData.create(i))
	new_data.sort_custom(_sort_apps)
	return new_data

func _show_data(data: Array[AppItemData]) -> void:
	apps = data
	for i in apps_list.get_children():
		i.queue_free()
	for i in data:
		var new_item = APP_ITEM.instantiate()
		new_item.app_image_url = i.image_url
		new_item.app_title = i.title
		apps_list.add_child(new_item)
		new_item.focus_entered.connect(func():
			_show_details(i)
			)
	loading_overlay.hide()
	_focus_first()

func _show_details(app_item: AppItemData):
	no_image_label.hide()
	selected_app = app_item
	app_image.texture_url = app_item.image_url
	app_desc.text = app_item.description
	app_title.text = app_item.title

func _image_load_failed() -> void:
	no_image_label.show()

func _image_load_success(_image: Texture, _from_cache: bool) -> void:
	no_image_label.hide()

func _focus_first() -> void:
	for i in apps_list.get_children():
		if i is AppItem and not i.is_queued_for_deletion():
			i.grab_focus()
			return

func check_latest_release(repo_name: String) -> void:
	set_progress_label("Checking releases...")
	download_overlay.show()
	var github_api_url = "https://api.github.com/repos/" + repo_name + "/releases"
	var resp: HTTPResult = await HTTP.async_request(github_api_url)
	if resp.success() and resp.status_ok():
		set_progress_label("Parsing release...")
		var releases = resp.body_as_json()
		if not releases is Array:
			show_error_message("Invalid API response.")
			return
		
		if releases.size() == 0:
			show_error_message("No releases available.")
			return

		var latest_release = releases[0]  # Get the latest release
		var assets = latest_release["assets"]

		for asset in assets:
			var asset_name: String = asset["name"]
			if _has_bad_phrase(asset_name):
				continue
			if asset_name.get_extension() in ALLOWED_EXT:
				var download_url = asset["browser_download_url"]
				
				if FileAccess.file_exists(str(DOWNLOAD_LOCATION, asset_name)):
					var existing = FileAccess.open(str(DOWNLOAD_LOCATION, asset_name), FileAccess.READ)
					if existing.get_length() == asset["size"]:
						show_success_message("%s already downloaded!" % asset_name)
						download_overlay.hide()
						return
				download_asset(download_url, asset_name)
				return
		show_error_message("No valid asset in release.")
	else:
		show_error_message(str("Failed to get releases for ", repo_name))
		return

func download_asset(url: String, file_name: String) -> void:
	is_downloading = true
	set_progress_label("Downloading %s" % file_name)
	download_target = file_name
	http_downloader.download_file = str(DOWNLOAD_LOCATION, file_name)
	var err = http_downloader.request(url)
	if err != OK:
		show_error_message(str("Failed to make request for asset: ", err))
		return

func _has_bad_phrase(file_name: String) -> bool:
	for i in DISALLOWED_PHRASES:
		if file_name.to_lower().contains(i):
			return true
	return false

func _on_http_downloader_request_completed(_result, response_code, _headers, _body):
	is_downloading = false
	if response_code == 200:
		show_success_message("Downloaded %s" % download_target.get_file())
		download_overlay.hide()
	else:
		show_error_message(str("Failed to download asset: ", response_code))

func set_progress_label(text: String) -> void:
	print("%s" % text)
	progress_label.text = text

func show_success_message(message: String) -> void:
	print("Success: %s" % message)
	success_label.text = message
	success_label.show()
	error_label.hide()
	message_countdown = 5

func show_error_message(message: String) -> void:
	print("Error: %s" % message)
	download_overlay.hide()
	error_label.text = message
	error_label.show()
	success_label.hide()
	message_countdown = 5

extends Control

enum FileMenuId { NEW, OPEN, SAVE, SAVE_AS, QUIT }
enum ViewMenuId { THEME }

const NEW_FILE_PLACEHOLDER = "Untitled"
const EXTENSIONS = {
	"GDScript": ["gd"]
}
const LANG_PLACEFOLDER = "Plain Text"
const THEMES = ["Gessetti", "Pennarelli"]

var current_file : String
var current_lang : String
var current_syntax : String
var current_theme : String
var file_dirty = false

func _ready():
	$TopBar/FileMenu.get_popup().id_pressed.connect(_on_file_menu_selected)
	$TopBar/TestMenu.get_popup().id_pressed.connect(_on_test_menu_selected)
	$BottomBar/IndentSizeMenu.get_popup().id_pressed.connect(_on_indent_changed_from_menu)
	$BottomBar/SyntaxMenu.get_popup().id_pressed.connect(_on_syntax_changed_from_menu)
	generate_theme_menu_items()
	generate_syntax_menu_items()
	$CodeArea.grab_focus()
	new_file()

#エディターからシンタックスのリソースを作成
func _on_test_menu_selected(id: int):
	if id == 0:
		new_file()
		$CodeArea.text = "[gd_resource type=\"Resource\" script_class=\"SyntaxResource\" load_steps=2 format=3 uid=\"uid://" + Resource.generate_scene_unique_id() + "\"]

[ext_resource type=\"Script\" uid=\"uid://" + Resource.generate_scene_unique_id() + "\" path=\"res://resources/SyntaxResource.gd\" " + "id=\"1_3h4hm\"]

[resource]
script = ExtResource(\"1_3h4hm\")
indent_size = 4
regions = {
\"key\": [[\"begin\",\"end\"]]
}
keywords = {
\"keyword\": [\"keyword\"]
}
member_keywords = {
\"member_keyword\": [\"member_keyword\"]
}
completions = [[\"display_text\", \"insert_text\"]]
metadata/_custom_type_script = \"uid://" + Resource.generate_scene_unique_id() + "\""

func update_window_title():
	var title = \
		ProjectSettings.get_setting("application/config/name") \
		+ ' - ' + current_file_name()
	if file_dirty: title += " *"
	get_window().title = title

func current_file_name() -> String:
	if current_file:
		return current_file.get_file()
	else:
		return NEW_FILE_PLACEHOLDER

func new_file():
	current_file = ''
	$CodeArea.text = ''
	$CodeArea.clear_syntax()
	file_dirty = false
	update_window_title()
	
func save_file():
	if current_file:
		var path = current_file
		var f = FileAccess.open(path, FileAccess.WRITE)
		f.store_string($CodeArea.text)
		f.flush()
		f.close()
		current_file = path
		file_dirty = false
		update_window_title()
	else:
		$SaveFileDialog.popup()

func set_code_theme(_theme: String):
	current_theme = _theme
	var resource = load("res://code-themes/%s-theme.tres" % _theme)
	$CodeArea.set_code_theme(resource)

func generate_theme_menu_items():
	var popup = $TopBar/ViewMenu.get_popup()
	var submenu = PopupMenu.new()
	submenu.set_name("ThemeMenu")
	for _name in THEMES:
		submenu.add_radio_check_item(_name)
	popup.add_child(submenu)
	popup.add_submenu_item("Theme", "ThemeMenu", ViewMenuId.THEME)
	submenu.set_item_checked(0, true)
	submenu.id_pressed.connect(_on_code_theme_changed)
	set_code_theme(THEMES[0])

func set_lang(lang: String):
	current_lang = lang
	$BottomBar/SyntaxMenu.text = lang
	if lang == LANG_PLACEFOLDER:
		$CodeArea.clear_syntax()
	else:
		set_syntax(lang)

func guess_syntax():
	var ext = current_file.get_extension()
	for key in EXTENSIONS:
		if EXTENSIONS[key].has(ext):
			set_lang(key)
			return
	set_lang(LANG_PLACEFOLDER)

func set_syntax(lang: String):
	var resource = load("res://code-syntaxes/%s.tres" % lang)
	$CodeArea.set_syntax(resource)

func generate_syntax_menu_items():
	var popup = $BottomBar/SyntaxMenu.get_popup()
	popup.set_item_count(EXTENSIONS.size() + 1)
	var i = 0
	for key in EXTENSIONS:
		popup.set_item_text(i, key)
		i += 1
	popup.set_item_text(i, LANG_PLACEFOLDER)
	set_lang(LANG_PLACEFOLDER)

func _on_file_menu_selected(id: int):
	match id:
		FileMenuId.NEW:
			new_file()
		FileMenuId.OPEN:
			$OpenFileDialog.popup()
		FileMenuId.SAVE:
			save_file()
		FileMenuId.SAVE_AS:
			$SaveFileDialog.popup()
		FileMenuId.QUIT:
			get_tree().quit()

func _on_open_file_dialog_file_selected(path: String) -> void:
	var f = FileAccess.open(path, FileAccess.READ)
	$CodeArea.text = f.get_as_text()
	f.close()
	current_file = path
	file_dirty = false
	update_window_title()

func _on_save_file_dialog_file_selected(path: String) -> void:
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string($CodeArea.text)
	f.flush()
	f.close()
	current_file = path
	file_dirty = false
	update_window_title()

func _on_code_area_text_changed():
	if file_dirty: return
	file_dirty = true
	update_window_title()

func _input(event):
	if event.is_action_pressed("new_file"):
		new_file()
	elif event.is_action_pressed("open_file"):
		$OpenFileDialog.popup()
	elif event.is_action_pressed("save_as"):
		$SaveFileDialog.popup()
	elif event.is_action_pressed("save"):
		save_file()

func _on_indent_changed_from_menu(id_as_indent: int):
	$CodeArea.set_indent(id_as_indent)

func _on_code_area_indent_changed(indent: int):
	var text = $BottomBar/IndentSizeMenu.text
	var regex = RegEx.new()
	regex.compile("\\d+")
	$BottomBar/IndentSizeMenu.text = regex.sub(text, str(indent))

func _on_code_theme_changed(index: int):
	set_code_theme(THEMES[index])
	var popup = $TopBar/ViewMenu.get_popup()
	var submenu_name = popup.get_item_submenu(ViewMenuId.THEME)
	var submenu = popup.get_node(submenu_name)
	for i in submenu.item_count:
		submenu.set_item_checked(i, false)
	submenu.set_item_checked(index, true)

func _on_syntax_changed_from_menu(id_as_index: int):
	var popup = $BottomBar/SyntaxMenu.get_popup()
	var lang = popup.get_item_text(id_as_index)
	set_lang(lang)
	if lang != LANG_PLACEFOLDER: set_syntax(lang)

extends CodeEdit

signal indent_changed

var current_theme : ThemeResource
var current_syntax : SyntaxResource


func _ready() -> void:
	syntax_highlighter = CodeHighlighter.new()

func set_code_theme(_theme: ThemeResource) -> void:
	current_theme = _theme
	add_theme_color_override("background_color", _theme.background_color)
	add_theme_color_override("font_color", _theme.foreground_color)
	syntax_highlighter.set_symbol_color(_theme.symbol_color)
	syntax_highlighter.set_number_color(_theme.number_color)
	syntax_highlighter.set_function_color(_theme.function_color)
	syntax_highlighter.set_member_variable_color(_theme.member_variable_color)
	if current_syntax: set_syntax(current_syntax)


func set_syntax(syntax: SyntaxResource) -> void:
	clear_syntax_highlighter()
	current_syntax = syntax
	set_indent(syntax.indent_size)
	for key in syntax.regions:
		for arr in syntax.regions[key]:
			if current_theme.syntax_colors.has(key):
				syntax_highlighter.add_color_region(
					arr[0], arr[1], current_theme.syntax_colors[key]
				)
	for key in syntax.keywords:
		for value in syntax.keywords[key]:
			if current_theme.syntax_colors.has(key):
				syntax_highlighter.add_keyword_color(
			value, current_theme.syntax_colors[key]
		)
	for key in syntax.member_keywords:
		for value in syntax.member_keywords[key]:
			if current_theme.syntax_colors.has(key):
				syntax_highlighter.add_member_keyword_color(
					value, current_theme.syntax_colors[key]
				)

func clear_syntax() -> void:
	current_syntax = null
	var default = SyntaxResource.new()
	set_indent(default.indent_size)
	clear_syntax_highlighter()

func clear_syntax_highlighter():
	syntax_highlighter.clear_highlighting_cache()
	syntax_highlighter.clear_color_regions()
	syntax_highlighter.clear_keyword_colors()
	syntax_highlighter.clear_member_keyword_colors()

func set_indent(_indent_size: int) -> void:
	indent_size = _indent_size
	emit_signal("indent_changed", _indent_size)

func _on_text_changed() -> void:
	if get_word_at_pos(get_caret_draw_pos()).length() > 0:
		request_code_completion(true)

func _on_code_completion_requested() -> void:
	if !current_syntax: return
	for arr in current_syntax.completions:
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, arr[0], arr[1])
	update_code_completion_options(true)

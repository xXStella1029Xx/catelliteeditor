extends Resource
class_name SyntaxResource

@export var indent_size = 4
@export var regions = {
	"key": [["begin", "end"]]
}
@export var keywords = {
	"key": ["keyword"]
}
@export var member_keywords = {
	"key": ["member_keyword"]
}
@export var completions = [
	["display_text", "insert_text"]
]

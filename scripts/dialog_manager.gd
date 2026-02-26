extends Node

const DIALOG_PATH := "res://data/dialogs.json"

var _dialogs := {}


func _ready() -> void:
	var file := FileAccess.open(DIALOG_PATH, FileAccess.READ)
	if not file:
		push_warning("DialogManager: could not open %s" % DIALOG_PATH)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_warning("DialogManager: JSON parse error: %s" % json.get_error_message())
		return
	_dialogs = json.data


func get_dialog(npc_id: String, key: String = "default") -> Dictionary:
	if npc_id not in _dialogs:
		return {}
	var npc_data: Dictionary = _dialogs[npc_id]
	if key not in npc_data:
		key = "default"
	if key not in npc_data:
		return {}
	var lines: Array = npc_data[key]
	if lines.is_empty():
		return {}
	var portrait: String = npc_data.get("portrait", "")
	return {"line": lines[0].line, "portrait": portrait}

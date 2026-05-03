extends RefCounted
class_name SpikeScenarioCatalog

var _default_scenario_id := ""
var _entries: Array[Dictionary] = []
var _entries_by_id: Dictionary = {}

func load_from_path(index_path: String) -> bool:
	_default_scenario_id = ""
	_entries.clear()
	_entries_by_id.clear()

	if not FileAccess.file_exists(index_path):
		push_error("Missing scenario index data: %s" % index_path)
		return false

	var file := FileAccess.open(index_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Scenario index data must be a JSON object.")
		return false

	var data := parsed as Dictionary
	_default_scenario_id = str(data.get("defaultScenarioId", ""))
	var scenarios_variant: Variant = data.get("scenarios", [])
	if typeof(scenarios_variant) != TYPE_ARRAY:
		push_error("Scenario index scenarios must be an array.")
		return false

	for scenario_variant: Variant in scenarios_variant:
		if typeof(scenario_variant) != TYPE_DICTIONARY:
			continue
		var scenario := scenario_variant as Dictionary
		var id := str(scenario.get("id", ""))
		var path := str(scenario.get("path", ""))
		if id == "" or path == "":
			continue
		if _entries_by_id.has(id):
			push_warning("Skipping duplicate scenario id in index: %s" % id)
			continue
		var entry := {
			"id": id,
			"name": str(scenario.get("name", id)),
			"path": path,
			"summary": str(scenario.get("summary", ""))
		}
		_entries.append(entry)
		_entries_by_id[id] = entry

	if _entries.is_empty():
		push_error("Scenario index must include at least one valid scenario.")
		return false
	if _default_scenario_id == "" or not _entries_by_id.has(_default_scenario_id):
		var first_entry := _entries[0]
		_default_scenario_id = str(first_entry.get("id", ""))

	return true

func entries() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for entry: Dictionary in _entries:
		output.append(entry.duplicate(true))
	return output

func default_scenario_id() -> String:
	return _default_scenario_id

func has_scenario(scenario_id: String) -> bool:
	return _entries_by_id.has(scenario_id)

func entry_for_id(scenario_id: String) -> Dictionary:
	if not _entries_by_id.has(scenario_id):
		return {}
	var entry := _entries_by_id[scenario_id] as Dictionary
	return entry.duplicate(true)

func path_for_id(scenario_id: String) -> String:
	if not _entries_by_id.has(scenario_id):
		return ""
	var entry := _entries_by_id[scenario_id] as Dictionary
	return str(entry.get("path", ""))

func name_for_id(scenario_id: String) -> String:
	if not _entries_by_id.has(scenario_id):
		return ""
	var entry := _entries_by_id[scenario_id] as Dictionary
	return str(entry.get("name", ""))

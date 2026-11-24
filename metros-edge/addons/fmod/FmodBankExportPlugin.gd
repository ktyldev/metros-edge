@tool
class_name FmodBankExportPlugin extends EditorExportPlugin

const BANKS_PATH_SETTING := "Fmod/General/banks_path"


func _get_name() -> String:
	return "FmodBankExportPlugin"


func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	_add_banks(ProjectSettings.get_setting(BANKS_PATH_SETTING, "res://"))


func _add_banks(folder: String) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() == "bank":
			var bank := folder.path_join(file)
			add_file(bank, FileAccess.get_file_as_bytes(bank), false)
	for subfolder in DirAccess.get_directories_at(folder):
		_add_banks(folder.path_join(subfolder))

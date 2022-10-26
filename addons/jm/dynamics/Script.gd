extends GDScript
class_name JGDScript

const _PrintHelper:Dictionary = { "string_conversion": null }


func _to_string() -> String:
	if _PrintHelper.string_conversion:
		return _PrintHelper.string_conversion
	return "JGDScript(%)" % resource_name


func import_gdscript(script:GDScript) -> bool:
	source_code = script.source_code
	resource_local_to_scene = script.resource_local_to_scene
	resource_name = script.resource_name
	resource_path = script.resource_path
	return reload() == OK

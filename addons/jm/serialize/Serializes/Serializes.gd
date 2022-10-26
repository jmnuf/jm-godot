extends Reference
class_name JSerializes

const BaseClassName = "JSerializes"
const _DYNAMICALS_ = {}

var _class_name:String
var _extras = {}
var _exclude:PoolStringArray

func _init(className:String="", exclude:=PoolStringArray([])) -> void:
	_set_class(className)
	_exclude = exclude


func has(property:String) -> bool:
	return get_properties(true).has(property)


func get_properties(with_extras:bool = false) -> PoolStringArray:
	var data := _get_serialized_version({ "extras": with_extras, "saving": false })
	
	var properties := PoolStringArray(data.keys())
	return properties


func _get_serialized_version(cfg:Dictionary = {}) -> Dictionary:
	var with_extras = cfg.get("extras", false)
	var for_saving = cfg.get("saving", true)
	
	var data := inst2dict(self)
	
	data.erase("_class_name")
	data.erase("_extras")
	data.erase("_exclude")
	
	if with_extras:
		for property in _extras.keys():
			data[property] = _extras[property]
	
	if not for_saving:
		data.erase("@path")
		data.erase("@subpath")
		return data
	
	for property in _exclude:
		data.erase(property)
	
	data["__jserializes__"] = __jserializes__()
	
	for property in data.keys():
		var value = get(property)
		if not (value is Object):
			continue
		
		if not value.has_method("__jserializes__"):
			data[property] = _serialized_value(value, with_extras)
			continue
		
		data[property] = value.serialized(with_extras)
	
	return data


func _get_serialized_from_dict(dict:Dictionary, extras:bool) -> Dictionary:
	var data:Dictionary = {}
	
	for property in dict.keys():
		var value = dict.get(property)
		data[property] = _serialized_value(value, extras)
	
	return data


func _get_serialized_from_obj(obj:Object, extras:bool):
	if not is_instance_valid(obj):
		return null
	
	if obj.has_method("__jserializes__"):
		return obj.serialized(extras, true)
	
	if obj.get_script() != null:
		return inst2dict(obj)
	
	var properties := obj.get_property_list()
	var className = obj.get_class()
	assert(className != null, "Unexpected null from get_class")
	var is_GodotObject = ClassDB.class_exists(className)
	is_GodotObject = is_GodotObject and ClassDB.can_instance(className)
	
	assert(is_GodotObject, "Can't serialize %s Object!" % className)
	
	var data:Dictionary = {}
	for prop in properties:
		var pname = prop.name
		var ptype = prop.type
		if ptype == TYPE_NIL:
			continue
		
		var value = obj.get(pname)
		value = _serialized_value(value, extras)
		data[pname] = { "type": ptype, "value": value }
	
	return {
		"_GodotObject_": is_GodotObject,
		"class": className,
		"data": data
	}


func _serialized_value(value, extras:bool = false):
	if value == null:
		return null
	match typeof(value):
		TYPE_STRING, TYPE_INT, TYPE_REAL, TYPE_BOOL:
			return value
		TYPE_VECTOR2:
			return { "x": value.x, "y": value.y }
		TYPE_VECTOR3:
			return { "x": value.x, "y": value.y, "z": value.z }
		TYPE_COLOR:
			return [ value.r, value.g, value.b, value.a ]
		TYPE_RECT2:
			return { "x": value.position.x, "y": value.position.y, "w": value.size.x, "h": value.size.y }
		TYPE_DICTIONARY:
			return _get_serialized_from_dict(value, extras)
		TYPE_ARRAY, TYPE_INT_ARRAY, TYPE_STRING_ARRAY, \
		TYPE_VECTOR2_ARRAY, TYPE_VECTOR3_ARRAY, TYPE_COLOR_ARRAY:
			var new_array = []
			for v in value:
				new_array.append(_serialized_value(v, extras))
			return new_array
		TYPE_OBJECT:
			return _get_serialized_from_obj(value, extras)


func dict(cfg = {}) -> Dictionary:
	if typeof(cfg) == TYPE_BOOL:
		cfg = { "extras": cfg }
	elif typeof(cfg) != TYPE_DICTIONARY:
		cfg = {}
	
	var for_saving = cfg.get("saving", true)
	var data := _get_serialized_version(cfg)
	
	_on_generated_dict(data, for_saving)
	
	if for_saving:
		_on_serialized(data)
	
	return data


func _on_generated_dict(dict:Dictionary, saving:bool) -> void:
	pass


func _on_serialized(dict:Dictionary) -> void:
	pass


func _on_deserialized(from:Dictionary) -> void:
	pass


func string(cfg:Dictionary = {}) -> String:
	return _to_string(cfg)


func _to_string(cfg:Dictionary = {}) -> String:
	var data = dict(cfg)
	var str_data:String = JSON.print(data)
	
	if not cfg.get("saving", true):
		if cfg.get("pretty", false):
			str_data = JSON.print(data, "  ")
		
		str_data = "%s<%s>" % [get_class(), str_data]
	return str_data


func _set(property: String, value) -> bool:
	var existed = _extras.has(property)
	_extras[property] = value
	return existed


func _get(property: String):
	return _extras.get(property)


func __jserializes__() -> String:
	return "0.1.0"


func _set_class(cls:String) -> void:
	_class_name = cls.strip_edges()


func get_class() -> String:
	if _class_name.empty():
		return BaseClassName
	return _class_name


static func createDynamicClass(name:String, properties:Dictionary) -> GDScript:
	var serializables_dir:String = "res://jm/Serializables/"
	var script_file_name:String = "Serialize.gd"
	var script_path:String = serializables_dir.plus_file(script_file_name)
	
	var script := JGDScript.new()
	var class_names:Array
	
	if ResourceLoader.exists(script_path):
		var gds = ResourceLoader.load(script_path)
		if not gds:
			push_error("Error attempting to load existing serial data classes string")
			return null
		if not script.import_gdscript(gds):
			push_error("Error attempting to load existing serial data classes string")
			return null
		class_names = gds.class_names
		var class_names_template:String = "\nconst class_names:Array = %s\n"
		var initial_class_names_string:String = class_names_template % JSON.print(class_names)
		if class_names.has(name):
			push_warning("Class already exists! Please override properties manually.")
			return script
		class_names.append(name)
		var new_class_names_string:String = class_names_template % JSON.print(class_names)
		script.source_code = script.source_code.replace(initial_class_names_string, new_class_names_string)
		script._PrintHelper.string_conversion = new_class_names_string
	else:
		class_names =  [name]
		var dir:Directory = Directory.new()
		dir.make_dir_recursive(serializables_dir)
		
		script.source_code = """extends Object
class_name JM_Serializables

const class_names:Array = <({names})>

func _to_string() -> String:
	var template:String = "JM{Serializables:%s}"
	return template % JSON.print(class_names)

""".format({ "names": JSON.print(class_names) }, "<({_})>")
		
	
	var properties_string:String = "#STRUCTURE%s\n" % JSON.print(properties)
	
	for property in properties.keys():
		var prop = properties[property]
		var type_string:String = ""
		
		match prop.type:
			TYPE_INT:
				type_string = ":int"
			TYPE_REAL:
				type_string = ":float"
			TYPE_DICTIONARY:
				type_string = ":Dictionary"
			TYPE_ARRAY:
				type_string = ":Array"
		
		properties_string += "\tvar %s%s\n" % [property, type_string]
	
	var class_source_code:String = """
class {name} extends JSerializes:
	{variables}
	func _init().("{name}") -> void:
		pass

""".format({ "name":name, "variables":properties_string })
	
	script.source_code += class_source_code
	
	if script.reload() != OK:
		push_error("Couldn't generate script!")
		return null
	
	
	if ResourceSaver.save(script_path, script, ResourceSaver.FLAG_CHANGE_PATH) != OK:
		push_error("Couldn't save script!")
		return null
	
	print(script.new())
	
	_DYNAMICALS_[name] = script
	return script


static func hasDynamicClass(name:String) -> bool:
	if not _DYNAMICALS_.has(name): return false
	if not is_instance_valid(_DYNAMICALS_.get(name)): return _DYNAMICALS_.erase(name) and false
	return true


static func getDynamicClass(name:String) -> GDScript:
	if not hasDynamicClass(name): push_error("Trying to get dynamic class '%s' that doesn't exist" % name)
	return _DYNAMICALS_.get(name)


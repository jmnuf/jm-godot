extends Reference
class_name JDeserializer

func _init() -> void:
	assert(false, "JDeserializer must NOT be instanced!")


static func parse(from) -> JSerializes:
	match typeof(from):
		TYPE_STRING:
			return parse_string(from)
		TYPE_DICTIONARY:
			return parse_dict(from)
		_:
			return null


static func parse_string(from:String) -> JSerializes:
	var json = JSON.parse(from)
	if json.error:
		push_error(json.error_string)
		return null
	if typeof(json.result) != TYPE_DICTIONARY:
		push_error("Expected dictionary for serialized data")
		return null
	
	var parsed = json.result
	
	return parse_dict(parsed)


static func parse_dict(from:Dictionary) -> JSerializes:
	var obj:JSerializes
	
	if not from.has("@path"):
		obj = JSerializes.new()
		from = from.duplicate()
		var base_object:Dictionary = inst2dict(obj)
		from["@subpath"] = base_object["@subpath"]
		from["@path"] = base_object["@path"]
	else:
		obj = dict2inst(from)
	
	if not obj:
		push_error("Failed to parse/generate an instance object")
		return null
	
	# Add extra values to instance
	if typeof(from.get("_extras")) != TYPE_DICTIONARY:
		from["_extras"] = {}
	var properties = obj.get_properties(false)
	var exclusions := ["@subpath", "@path", "_extras", "_exclude", "__jserializes__"]
	for property in from.keys():
		if exclusions.has(property) or properties.has(property):
			continue
		
		var value = from[property]
		if typeof(value) == TYPE_DICTIONARY:
			if value.has("@path"):
				if value.has("__jserializes__"):
					value = parse_dict(value)
				else:
					value = dict2inst(value)
			elif value.has(""):
				pass
		from["_extras"][property] = value
	
	obj = dict2inst(from)
	
	if obj:
		obj._on_deserialized(from)
	
	return obj

static func _parsed_value(prop):
	var value = prop.data
	match prop.type:
		TYPE_VECTOR2:
			return Vector2(value.x, value.y)
		TYPE_VECTOR3:
			return Vector3(value.x, value.y, value.z)
		TYPE_COLOR:
			return Color(value[0], value[1], value[2], value[3])
		TYPE_RECT2:
			return Rect2(value.x, value.y, value.w, value.h)
		TYPE_DICTIONARY:
			var dict = {}
			for k in value.keys():
				dict[k] = _parsed_value(value[k])
			return dict
		TYPE_ARRAY:
			var arr = []
			for v in value:
				arr.append(_parsed_value(v))
			return arr
		TYPE_OBJECT:
			var obj:Object = null
			if value.has("@path"):
				if value.has("__jserializes__"):
					obj = parse_dict(value)
				else:
					obj = dict2inst(value)
			elif value.has("_GodotObject_"):
				var cls = value.class
				obj = ClassDB.instance(cls)
				var data:Dictionary = value.data
				for property in data.keys():
					obj.set(property, _parsed_value(data[property]))
			return obj


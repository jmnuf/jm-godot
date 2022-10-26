extends JSerializes
class_name JDataTable, "res://addons/jm/serialize/Database/DataTable/database_table.png"

signal command_error(message)
signal command_warning(message)

signal added(id)
signal removed(id)
signal updated(id)
signal added_item(id, item)
signal removed_item(id, item)
signal updated_item(id, item)

signal subdata_added(id, property, value)
signal subdata_updated(id, property, value)

var _data:Dictionary = {}
var Type:GDScript = JSerializes setget T
var _next_id:int = 0
var name:String

func _init(table_name:String, T=Type).("JDataTable", ["Type"]) -> void:
	name = table_name
	T(T)


func get_next_id() -> String:
	var template:String = ("%s" % name.to_lower()) + "%d"
	while has_id(template % _next_id): _next_id += 1
	return str(_next_id)


func create(id:String=get_next_id(), item=null) -> JSerializes:
	if typeof(item) != TYPE_DICTIONARY and not (item is Type):
		var err:String = "Invalid initial setting of Table(%s) item(%s)! Passed item must be either a Dictionary or an instance of the Table Model(defaults to JSerializes)"
		err % [name, id]
		push_error(err)
		emit_signal("command_error", err)
		return null
	
	if has_id(id):
		var warning:String
		if typeof(item) == TYPE_DICTIONARY:
			warning = "Table(%s) already has Object(%s)! Updating Object instead" % [name, id]
		else:
			warning = "Table(%s) already has Object(%s)! Canceling Object creation" % [name, id]
		push_warning(warning)
		emit_signal("command_warning", warning)
		if typeof(item) == TYPE_DICTIONARY:
			update(id, item)
		return request(id)
	
	var perfectly_type:bool = item is Type
	var object:JSerializes = item if item is Type else Type.new()
	
	if not perfectly_type:
		if typeof(item) == TYPE_DICTIONARY:
			for k in item.keys():
				object.set(k, item[k])
		elif typeof(item) == TYPE_OBJECT:
			object = Type.new()
			for p in item.get_property_list():
				if p.type == TYPE_NIL:
					continue
				
				object.set(p.name, item.get(p.name))
	
	
	_data[id] = object
	
	emit_signal("added", id, object)
	
	return object


func append(item=null) -> JSerializes:
	
	var id = get_next_id()
	
	return create(id, item)


func update(id:String, changes:Dictionary) -> bool:
	if not has_id(id):
		var err:String = "Attempting to update non-existent Object(%s) in Table(%s)" % [id, name]
		push_error(err)
		emit_signal("command_error", err)
		return false
	
	var obj = request(id)
	var changes_expected:int = changes.keys().size()
	var changes_applied := []
	for property in changes:
		var exist = obj.has(property)
		var value = changes[property]
		obj.set_indexed(property, value)
		
		changes_applied.append([property, value, exist])
	
	for change in changes_applied:
		var property = change[0]
		var value = change[1]
		var exist = change[2]
		
		if exist:
			emit_signal("subdata_updated", id, property, value)
		else:
			emit_signal("subdata_added", id, property, value)
	
	emit_signal("updated", id)
	emit_signal("updated_item", id, obj)
	
	return true


func has_id(id:String) -> bool:
	return _data.has(id)


func update_property(id:String, property:String, value) -> bool:
	update(id, { property: value })
	return true


func request(id:String) -> JSerializes:
	var data = _data.get(id)
	if not data:
		var err:String = "Object(%s) doesn't exist in Table(%s)" % [id, name]
		push_error(err)
		emit_signal("command_error", err)
	
	return data


func _on_generated_dict(dict:Dictionary, saving:bool) -> void:
	if not saving:
		var dt:Dictionary = dict._data
		dict.erase("_data")
		dict.ids = str(dt.keys())
	
	if Type:
		dict.Type = Type.new().get_class()


func T(T):
	if Type != JSerializes or not T or T == Type:
		return Type
	
	if T is String:
		var type_name = T
		T = null
		for script_prop in ProjectSettings.get_setting("_global_script_classes"):
			if not script_prop.get("class"):
				continue
			T = load(script_prop.path)
		
		if not T: return Type
	
	var o = T.new()
	if not (o is JSerializes):
		return Type
	Type = T


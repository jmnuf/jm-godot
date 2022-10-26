extends JSerializes
class_name JDatabase, "res://addons/jm/serialize/Database/database.png"

signal command_error(message, table)
signal command_warning(message, table)

var name:String
var _tables:Dictionary

func _init(db_name:String="JDatabase").("JDatabase") -> void:
	name = db_name
	_tables = {}


func create_table(table_name:String, Template=null) -> JDataTable:
	if has_table(table_name):
		push_error("Table(%s) already exists in DB(%s)!" % [table_name, name])
		return null
	
	var table = JDataTable.new(table_name, Template)
	table.connect("command_error", self, "_on_JDataTable_command_error", [table])
	table.connect("command_warning", self, "_on_JDataTable_command_warning", [table])
	
	_tables[table_name] = table
	
	return table


func has_table(table_name:String) -> bool:
	return _tables.has(table_name)


func table(table_name:String) -> JDataTable:
	var tb = _tables.get(table_name)
	if not tb:
		push_error("Table(%s) doesn't exist in DB(%s)" % [table_name, name])
	
	return tb


func request(table_name:String, id:String) -> JSerializes:
	var tb = table(table_name)
	if not tb:
		return null
	
	var data = tb.request(id)
	if not data:
		push_error("Requesting non-existent data(%s) from DB(%).%s" % [id, name, table_name])
	
	return data


func subrequest(table_name:String, id:String, property:String):
	var data = request(table_name, id)
	
	if not data:
		return null
	
	return data.get(property)


func get_tables() -> PoolStringArray:
	return PoolStringArray(_tables.keys())


func _get(property: String):
	return _tables.get(property)


func get_class() -> String:
	return "JDatabase"



func _on_JDataTable_command_error(message:String, table:JDataTable) -> void:
	emit_signal("command_error", message, table.name)


func _on_JDataTable_command_warning(message:String, table:JDataTable) -> void:
	emit_signal("command_warning", message, table.name)


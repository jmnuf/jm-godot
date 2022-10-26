extends Node

var _databases:Dictionary

func load(saved) -> bool:
	if typeof(saved) == TYPE_STRING:
		var json = JSON.parse(saved)
		if json.error:
			push_error(json.error_string)
			return false
		saved = json.result
	if typeof(saved) != TYPE_DICTIONARY:
		return false
	
	var dict:Dictionary = saved
	var data:Dictionary = {}
	for k in dict.keys():
		var db_dict = dict[k]
		var db = JDeserializer.parse(db_dict)
		if db == null:
			return false
		data[k] = db
	
	_databases = data
	
	return true


func save() -> String:
	var s := {}
	
	for k in _databases.keys():
		var db:JDatabase = _databases[k]
		s[k] = db.string({ "extras": true })
	
	return JSON.print(s)


func create_db(db_name:String, table_names:=PoolStringArray([])) -> bool:
	if _databases.has(db_name):
		push_error("Database '%s' already exists!\nIf you wish to override use override" % db_name)
		return false
	
	_databases[db_name] = JDatabase.new(db_name)
	for table_name in table_names:
		_databases[db_name][table_name] = JDataTable.new(table_name)
	
	return true


func database(db_name:String) -> JDatabase:
	var db = _databases.get(db_name)
	if db == null:
		push_error("Requesting non-existent DB(%s)" % [db_name])
		return null
	return db


func table(db_name:String, table_name:String):
	var db = database(db_name)
	if not db:
		return null
	
	return db.table(table_name)


func request(db_name:String, table_name:String, id:String) -> Object:
	if not _databases.has(db_name):
		push_error("Requesting from non-existent DB(%s) for data(%s.%s)" % [db_name, table_name, id])
		return null
	
	var db:JDatabase = _databases[db_name]
	if not db.has_table(table_name):
		push_error("Requesting from non-existent table(%s) in DB(%s) for data(%s)" % [table_name, db_name, id])
		return null
	
	var data = db.request(table_name, id)
	
	return data


func subrequest(db_name:String, table_name:String, id:String, property:String) -> Object:
	var data = request(db_name, table_name, id)
	if data == null:
		return null
	
	return data.get(property)


func delete(db_name:String, table_name:String, id:String) -> bool:
	if not _databases.has(db_name):
		push_error("Deleting from non-existent DB(%s) for data(%s.%s)" % [db_name, table_name, id])
		return false
	
	var db = _databases[db_name]
	if not db.has_table(table_name):
		push_error("Deleting from non-existent table(%s) in DB(%s) for data(%s)" % [table_name, db_name, id])
		return false
	
	var tb = db[table_name]
	if not tb.has_id(id):
		push_error("Deleting non-existent data(%s) from DB(%).%s" % [id, db_name, table_name])
		return false
	
	tb.erase(id)
	
	return false


func get_databases() -> PoolStringArray:
	return PoolStringArray(_databases.keys())


func get_tables(db_name:String) -> PoolStringArray:
	var db := database(db_name)
	if not db:
		return PoolStringArray()
	
	return db.get_tables()


func get_all_tables() -> Array:
	var all_tables = []
	for db_name in _databases.keys():
		var db := database(db_name)
		var tables = db.get_tables()
		all_tables.append([ db_name, tables ])
	
	return all_tables


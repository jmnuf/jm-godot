extends Node2D

onready var handler := $"%DataHandler"


func _ready() -> void:
	var dir := Directory.new()
	dir.remove("res://jm/Serializables/Serialize.gd")
	dir.remove("res://jm/Serializables/")
	dir.remove("res://jm/")
	yield(get_tree().create_timer(1), "timeout")
	var Dynamicals:GDScript = JSerializes.createDynamicClass("Dynamic", { "my_int": { "type": TYPE_INT } })
	print(Dynamicals)
	print(Dynamicals.class_names)
#	var dynamical = Dynamic.new()
#	print(dynamical.string({ "pretty": true, "saving": false }))
#	print(ClassDB.can_instance("GDScript"))
	yield(get_tree().create_timer(1), "timeout")
	_db_testing()
	yield(get_tree().create_timer(1), "timeout")
	_serializes_testing()
	


func _print_borders(opening:bool) -> void:
	if opening:
		print("============================================")
	else:
		print("--------------------------------------------")


func _db_testing() -> void:
	_print_borders(true)
	print("Database querying!")
	JDH.create_db("Entertainment")
	var db := JDH.database("Entertainment")
	db.create_table("Games", GameData)
	var tb := db.table("Games")
	tb.create("0", { "name": "Growtopia", "rating": "PG" })
	tb.create("1", { "name": "Residency", "rating": "18+" })
	print(
		JDH.request("Entertainment", "Games", "0"), "\n",
		JDH.request("Entertainment", "Games", "1"), "\n"
	)
	_print_borders(false)
	print("Serialize Table")
	print(
		tb.string({ "saving": false, "pretty": true })
	)
	_print_borders(false)


func _serializes_testing() -> void:
	_print_borders(true)
#	print("Global Script Classes")
#	for dict in ProjectSettings.get_setting("_global_script_classes"):
#		if not dict.get("class"):
#			continue
#
#		prints(dict.class, "'%s'" % dict.path)
#	_print_borders(false)
#	print("\n")
	
	print("SubClass testing")
	var subperson = SubClassPerson.new("Josh", "Editron", 41)
	subperson.set("is_subclass", true)
	subperson.set("position", Vector3(5, 2, -10))
	subperson.set("color", Color.blueviolet)
	_print_serialize_and_deserialize(subperson)
	_print_borders(false)


func _print_serialize_and_deserialize(serie:JSerializes) -> void:
	print("Serializing and deserializing an Object(%s)" % serie.get_class())
	var serialized_data := serie.dict({ "extras": true})
	var deserialized_vr := JDeserializer.parse(serie.dict(true))
	
	print(
		serie.get_class(),
		JSON.print(serie.dict(true), "  "), "\n",
		JSON.print(deserialized_vr.dict(true), "  "), "\n"
	)
	var properties := serie.get_properties(true)
	for property in properties:
		var base_value = serie.get(property)
		var desr_value = deserialized_vr.get(property)
		print(
			property, "\n",
			"base(%d):" % typeof(base_value), base_value, "\n",
			"desr(%d):" % typeof(desr_value), desr_value, "\n"
		)


class SubClassPerson extends JSerializes:
	var first_name:String
	var last_name:String
	var age:int
	
	func _init(fname:String="", lname:String="", p_age:int=-1) -> void:
		first_name = fname
		last_name = lname
		age = p_age


class TestResource extends Resource:
	var aaa := 555
	var bbb := "2"


class GameData extends JSerializes:
	var name:String
	var rating:String = "PG+13"
	var demo:bool = false
	
	func _init().("GameData") -> void:
		pass


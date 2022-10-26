extends JSerializes
class_name Person

var first_name:String
var last_name:String
var age:int

func _init(fname:String="???", lname:String="", Age:int=-1) -> void:
	first_name = fname
	last_name
	age = Age

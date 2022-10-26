extends Object
class_name JM_Serializables

const class_names:Array = ["Dynamic"]

func _to_string() -> String:
	var template:String = "JM{Serializables:%s}"
	return template % JSON.print(class_names)


class Dynamic extends JSerializes:
	#STRUCTURE{"my_int":{"type":2}}
	var my_int:int

	func _init().("Dynamic") -> void:
		pass


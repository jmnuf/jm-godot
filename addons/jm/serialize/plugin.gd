tool
extends EditorPlugin

const DataHandler = preload("res://addons/jm/serialize/DataHandler.gd")
const DataHandlerIcon = preload("res://addons/jm/serialize/icon.png")

func _enter_tree() -> void:
	add_custom_type("JDataHandler", "Node", DataHandler, DataHandlerIcon)
	add_autoload_singleton("JDH", "res://addons/jm/serialize/DataHandler.gd")


func _exit_tree() -> void:
	remove_custom_type("JDataHandler")


func get_plugin_icon() -> Texture:
	return preload("res://addons/jm/serialize/JDH.png")


func get_plugin_name() -> String:
	return "JM.DataHandler"


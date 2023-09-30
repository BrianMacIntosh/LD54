extends Control

@onready var listener_label : Label = find_child("ListenerLabel")
@onready var tab_container : TabContainer = find_child("TabContainer")

func _ready():
	visible = false
	RadioManager.on_show_menu.connect(handle_show_menu)

func handle_show_menu(callsign : StringName, category_name : StringName):
	if category_name:
		visible = true
		listener_label.text = "To: %s" % callsign
		tab_container.current_tab = tab_container.get_node(NodePath(category_name)).get_index()
	else:
		visible = false

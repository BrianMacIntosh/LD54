extends Button
## A button that shows a radio menu menu clicked.

## The name of the submenu to show when this button is clicked.
@export var submenu_name : StringName

func _pressed():
	RadioManager.show_menu("", submenu_name)

extends RichTextLabel
## Rich label that shows the text of radio messages as they are sent.

func _ready():
	text = ""
	RadioManager.on_message_sent.connect(handle_message_sent)

func handle_message_sent(_speaker_callsign : StringName, in_text : String):
	text = "[center]%s[/center]" % [ in_text ]
	$HideTimer.start()
	await $HideTimer.timeout
	text = ""

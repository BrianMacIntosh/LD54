extends RichTextLabel
## Rich label that shows the text of radio messages as they are sent.

func _ready():
	visible = false
	RadioManager.on_message_sent.connect(handle_message_sent)

func handle_message_sent(speaker_callsign : StringName, in_text : String):
	text = "[center][b]%s[/b]: %s[/center]" % [ speaker_callsign, in_text ]
	$HideTimer.start()
	await $HideTimer.timeout
	text = ""

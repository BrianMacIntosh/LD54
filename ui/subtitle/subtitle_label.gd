extends Control

func _ready():
	$Label.text = ""
	RadioManager.on_message_sent.connect(handle_message_sent)

func handle_message_sent(speaker_callsign : StringName, in_text : String):
	var is_npc = speaker_callsign != RadioManager.controller_callsign and speaker_callsign != &"TCAS"
	if is_npc:
		$KeyedAudio.play()
		#$NoiseAudio.play()
	$Label.text = "[center]%s[/center]" % [ in_text ]
	$HideTimer.start()
	await $HideTimer.timeout
	if is_npc:
		$NoiseAudio.stop()
		$ClickAudio.play()
	$Label.text = ""

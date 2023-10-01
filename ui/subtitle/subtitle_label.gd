extends Control

func _ready():
	$PlayerLabel.text = ""
	$NpcLabel.text = ""
	RadioManager.on_message_sent.connect(handle_message_sent)

func handle_message_sent(speaker_callsign : StringName, in_text : String):
	var is_npc = speaker_callsign != RadioManager.controller_callsign and speaker_callsign != &"TCAS"
	if is_npc:
		$KeyedAudio.play()
		#$NoiseAudio.play()
		$NpcLabel.text = "[center]%s[/center]" % [ in_text ]
		$NpcHideTimer.start()
		await $NpcHideTimer.timeout
		$NoiseAudio.stop()
		$ClickAudio.play()
		$NpcLabel.text = ""
	else:
		$PlayerLabel.text = "[center]%s[/center]" % [ in_text ]
		$PlayerHideTimer.start()
		await $PlayerHideTimer.timeout
		$NoiseAudio.stop()
		$ClickAudio.play()
		$PlayerLabel.text = ""

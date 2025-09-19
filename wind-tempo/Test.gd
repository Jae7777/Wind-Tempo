extends Node

func _ready():
  OS.open_midi_inputs()
  print(OS.get_connected_midi_inputs())

func _input(event):
  if event is InputEventMIDI:
    print("MIDI button pressed.")
    printt("Channel", event.channel)
    printt("Pitch", event.pitch)
    printt("Velocity", event.velocity)
    printt("Message", event.message)
    printt("Instrument", event.instrument)
    printt("Pressure", event.pressure)
    printt("-=-=-=-=-=-=-=-=-=-=-")

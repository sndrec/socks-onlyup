extends Label

const HOLD_DURATION_TO_RESPAWN := 5.0

@onready var mario := $".."
var respawn_button_hold_time := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("debug_restart"):
		if Input.is_action_pressed(mario.mario_inputs_stick_left) or Input.is_action_pressed(mario.mario_inputs_stick_right) or Input.is_action_pressed(mario.mario_inputs_stick_up) or Input.is_action_pressed(mario.mario_inputs_stick_down) or Input.is_action_pressed(mario.mario_inputs_button_a) or Input.is_action_pressed(mario.mario_inputs_button_b) or Input.is_action_pressed(mario.mario_inputs_button_z):
			respawn_button_hold_time = 0.0
			text = ""
		elif not (mario.action & LibSM64.ACT_FLAG_AIR):
			respawn_button_hold_time += delta
			text = "Keep holding to respawn... %.1f" % [HOLD_DURATION_TO_RESPAWN - respawn_button_hold_time]
			if respawn_button_hold_time > HOLD_DURATION_TO_RESPAWN:
				mario._restore_mario_to_checkpoint()
				respawn_button_hold_time = 0.0
	elif Input.is_action_just_released("debug_restart"):
		respawn_button_hold_time = 0.0
		text = ""

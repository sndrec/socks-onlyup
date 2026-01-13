extends Label

@onready var mario = $".."

func _process(_delta: float) -> void:
	text = "%dm" % [mario.position.y]

class_name Repeater

signal click

var init_delay: float
var step_delay: float
var min_delay: float

var enabled: bool
var timeout: float
var current_delay: float

func _init(_init_delay := 0.25, _step_delay := 0.025, _min_delay := 0.03):
	init_delay = _init_delay
	step_delay = _step_delay
	min_delay = _min_delay

func process(delta):
	if not enabled: return
	timeout -= delta
	
	while timeout <= 0:
		click.emit()
		timeout += current_delay
		current_delay = max(current_delay - step_delay, min_delay)

func enable():
	if not enabled:
		current_delay = init_delay
		timeout = current_delay
		click.emit()
	enabled = true

func disable():
	enabled = false

extends CanvasLayer


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

func _input(event):
	if event.is_action_pressed("enter"):
		get_tree().paused = false
		queue_free()

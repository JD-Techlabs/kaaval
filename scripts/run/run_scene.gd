extends Node
## Root of the run scene: the simulation plus its UI layer.


func _ready() -> void:
	var run: RunManager = RunManager.new()
	run.name = "Run"
	add_child(run)
	var ui: RunUi = RunUi.new()
	ui.name = "Ui"
	ui.run = run
	add_child(ui)

extends "res://tests/base_test.gd"
## System events during a night (focus lost, app backgrounded, back gesture)
## must open a working pause menu, never leave the night paused with no menu.
## Regression for "Parent node is busy setting up children, add_child() failed".


func _new_night() -> RunUi:
	GameState.p["hints_done"] = true
	var holder: Node = Node.new()
	add_child_autofree(holder)
	var run: RunManager = RunManager.new()
	run.set_process(false)
	holder.add_child(run)
	var ui: RunUi = RunUi.new()
	ui.run = run
	holder.add_child(ui)
	return ui


## Delivers a notification the way Godot does for system events: propagated
## down the tree, which marks each parent busy while its children are notified.
func _system_event(ui: RunUi, what: int) -> void:
	ui.get_parent().propagate_notification(what)
	await get_tree().process_frame


func test_losing_focus_opens_a_real_pause_menu() -> void:
	var ui: RunUi = _new_night()
	await _system_event(ui, Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_not_null(ui._pause_modal, "pause menu opened")
	assert_true(ui._pause_modal.is_inside_tree(), "and it is on screen, not orphaned")
	assert_eq(ui.run.mode, RunManager.Mode.PAUSED, "the night is paused behind it")
	ui._resume()
	assert_eq(ui.run.mode, RunManager.Mode.PLAYING, "Resume continues the night")


func test_app_backgrounded_then_back_gesture_resumes() -> void:
	var ui: RunUi = _new_night()
	await _system_event(ui, Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_true(ui._pause_modal != null and ui._pause_modal.is_inside_tree())
	await _system_event(ui, Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_null(ui._pause_modal, "back closes the pause menu")
	assert_eq(ui.run.mode, RunManager.Mode.PLAYING)

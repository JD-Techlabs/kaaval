class_name Main
extends Control
## Splash (spec §10): logo, loading bar, consent flow on launch, then Home.

## True when launched with `-- --screenshot-mode`: hides debug UI for store captures.
static var screenshot_mode: bool = false

const MIN_SPLASH_SECONDS: float = 0.9
## Never let a slow consent/ad network keep the player on the splash.
const CONSENT_TIMEOUT_SECONDS: float = 8.0

var _bar: ProgressBar
var _elapsed: float = 0.0
var _ads_ready: bool = false
var _leaving: bool = false
var _target: String = "home"


func _ready() -> void:
	theme = UiKit.theme()
	var background: ColorRect = ColorRect.new()
	background.color = UiKit.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column: VBoxContainer = UiKit.vbox(30)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.safe_area(self, 120).add_child(column)
	var logo: TextureRect = UiKit.icon("res://icon.svg", 420.0)
	column.add_child(logo)
	var title: Label = UiKit.label("KAAVAL", 120, UiKit.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle: Label = UiKit.label("Guardians of Dawn", UiKit.FONT_BIG, UiKit.TEXT)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	_bar = UiKit.bar(UiKit.AMBER, 28.0)
	_bar.max_value = 1.0
	column.add_child(_bar)

	for arg: String in OS.get_cmdline_user_args():
		if arg == "--screenshot-mode":
			screenshot_mode = true
		elif arg.begins_with("--goto="):
			_target = arg.trim_prefix("--goto=")
	if get_tree().root.get_node_or_null("ScreenshotTool") == null:
		var tool_node: ScreenshotTool = ScreenshotTool.new()
		tool_node.name = "ScreenshotTool"
		get_tree().root.add_child.call_deferred(tool_node)
	AdsService.start(func() -> void: _ads_ready = true)


func _process(delta: float) -> void:
	_elapsed += delta
	_bar.value = minf(_elapsed / MIN_SPLASH_SECONDS, 1.0 if _ads_ready else 0.9)
	var waited_enough: bool = _ads_ready or _elapsed >= CONSENT_TIMEOUT_SECONDS
	if not _leaving and _elapsed >= MIN_SPLASH_SECONDS and waited_enough:
		_leaving = true
		SceneRouter.goto(_target)

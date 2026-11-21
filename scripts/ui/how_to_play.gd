class_name HowToPlay
extends RefCounted
## "How to play": a few short pages with Next and Skip. Opens by itself the
## first time Start Night is pressed, and any time from Settings.

const PAGE_WIDTH: float = 820.0
const ICON_SIZE: float = 220.0


static func seen() -> bool:
	return bool(GameState.p.get("how_to_play_seen", false))


static func mark_seen() -> void:
	GameState.p["how_to_play_seen"] = true
	GameState.save()


## [{"icon", "title", "text"}], filled from game data so times and counts stay true.
static func pages() -> Array[Dictionary]:
	var first: WaveData = NightLogic.nights()[0]
	var first_boss: Dictionary = NightLogic.bosses(first)[0]
	return [
		{"icon": "res://assets/sprites/hero_muthu.svg", "title": "Guard the village",
			"text": "Every night, creatures come out of the dark. Survive until dawn (%s on the timer) to win the night." % NightLogic.clock(first.duration)},
		{"icon": "res://assets/sprites/joy_knob.svg", "title": "Move",
			"text": "Touch and drag anywhere on the lower part of the screen to move. Your weapons attack on their own."},
		{"icon": "res://assets/sprites/ember.svg", "title": "Collect embers",
			"text": "Defeated creatures drop glowing embers. Walk over them to fill the XP bar. Every level up, pick 1 of 3 upgrades."},
		{"icon": GameData.boss(str(first_boss["id"])).texture, "title": "Beat the bosses",
			"text": "Three bosses come each night. In %s: %s. Each one drops a chest with a big upgrade." % [first.display_name, NightLogic.boss_schedule(first)]},
		{"icon": UiKit.ICON_DIR + "coin.svg", "title": "Grow stronger",
			"text": "Spend coins and timber on village buildings to make your hero stronger. Reach dawn to unlock the next night. There are %d nights, each with new bosses." % NightLogic.nights().size()},
		{"icon": UiKit.ICON_DIR + "food.svg", "title": "Grow through the ages",
			"text": "Nights also bring food, stone and more. Upgrade buildings and gather resources to lead the village from the %s to the %s, %d ages in all. Tap the age bar on the home screen to see what the next age needs." % [AgeLogic.ages()[0].display_name, AgeLogic.ages()[-1].display_name, AgeLogic.ages().size()]},
	]


## `on_done` runs after the last page or Skip.
static func open(parent: Node, on_done: Callable = Callable()) -> void:
	var content: VBoxContainer = UiKit.modal(parent, "How to play")
	var list: Array[Dictionary] = pages()
	var page: Array[int] = [0]
	var art: TextureRect = UiKit.icon(str(list[0]["icon"]), ICON_SIZE)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(art)
	var title: Label = UiKit.label("", UiKit.FONT_BIG, UiKit.AMBER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var body: Label = UiKit.label("", UiKit.FONT, UiKit.TEXT, true)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.custom_minimum_size = Vector2(PAGE_WIDTH, 300.0)
	content.add_child(body)
	var counter: Label = UiKit.label("", UiKit.FONT_SMALL, UiKit.MUTED)
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(counter)
	var buttons: HBoxContainer = UiKit.hbox()
	content.add_child(buttons)
	var finish: Callable = func() -> void:
		mark_seen()
		UiKit.close_modal(content)
		if on_done.is_valid():
			on_done.call()
	var skip: Button = UiKit.button("Skip", finish, "secondary")
	skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(skip)
	var next: Button = UiKit.button("Next", Callable())
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(next)
	var show_page: Callable = func() -> void:
		var entry: Dictionary = list[page[0]]
		art.texture = load(str(entry["icon"])) as Texture2D
		title.text = str(entry["title"])
		body.text = str(entry["text"])
		counter.text = "%d / %d" % [page[0] + 1, list.size()]
		var last: bool = page[0] == list.size() - 1
		next.text = "Let's go!" if last else "Next"
		skip.visible = not last
	next.pressed.connect(func() -> void:
		if page[0] >= list.size() - 1:
			finish.call()
		else:
			page[0] += 1
			show_page.call())
	show_page.call()

extends Node2D
export (int) var width = 100
export (int) var height = 100
export (int) var camera_speed = 400

const MAX_WIDTH = 150
const MAX_HEIGHT = 150

var current_generation = 0

var tiles : Array

func _input(_e):
	var camera_dir = Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"),
	Input.get_action_strength("down") - Input.get_action_strength("up")).normalized()
	
	$View.move_and_slide(camera_dir * camera_speed)
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		var pos = $TileMap.world_to_map($View/Camera.get_global_mouse_position())
		if between(pos.x, 0, width) and between(pos.y, 0, height):
			set_tile(pos, not tiles[0][pos])
	if Input.is_action_pressed("ui_accept"):
		toggle_timer()
		update_gui()
	if Input.is_action_pressed("zoom_in"):
		$View/Camera.zoom /= 1.1
	if Input.is_action_pressed("zoom_out"):
		$View/Camera.zoom *= 1.1

func _ready():
	generate_map()
	draw_step()

func generate_map():
	tiles.clear()
	$TileMap.clear()
	tiles.append(new_map())
	tiles.append(new_map())

func new_map():
	var new_map = {}
	for x in width:
		for y in height:
			new_map[Vector2(x,y)] = false
	current_generation = 1
	return new_map

func between(num, start, end):
	var is_between
	if num < start or num >= end:
		is_between = false
	else:
		is_between = true
	return is_between

func count_live_neighbors(pos):
	var count = 0
	var neighbor
	for x in [-1,0,1]:
		for y in [-1,0,1]:
			neighbor = Vector2(x, y)
			if neighbor == Vector2.ZERO:
				continue
			else:
				if between(pos.x + neighbor.x, 0, width) and between(pos.y + neighbor.y, 0, height):
					if tiles[0][Vector2(pos.x + neighbor.x, pos.y + neighbor.y)]:
						count += 1
	return count

func set_tile(pos, tile_state):
	tiles[0][pos] = tile_state
	$TileMap.set_cellv(pos, int(tile_state))

func update_map():
	var pos : Vector2
	var cell_neighbors : int
	for x in width:
		for y in height:
			pos = Vector2(x, y)
			cell_neighbors = count_live_neighbors(pos)
			if tiles[0][pos]:
				if cell_neighbors < 2 or cell_neighbors > 3:
					tiles[1][pos] = false
				else:
					tiles[1][pos] = true
			else:
				if cell_neighbors == 3:
					tiles[1][pos] = true
				else:
					tiles[1][pos] = false
	tiles.invert()

func draw_step():
	var pos : Vector2
	for x in width:
		for y in height:
			pos = Vector2(x,y)
			set_tile(pos, tiles[0][pos])
	update_gui()

func update_gui():
	$GUI/Details/Generation.text = "Generation: " + str(current_generation)
	var timer_str : String
	if $Timer.is_stopped():
		timer_str = "Paused"
	else:
		timer_str = "Running"
	$GUI/Details/TimerStatus.text = timer_str
	$GUI/Details/WidthEdit.text = str(width)
	$GUI/Details/HeightEdit.text = str(height)

func toggle_timer():
	var new_status : bool
	if $Timer.is_stopped():
		$Timer.start()
		new_status = false
	else:
		$Timer.stop()
		new_status = true
	$GUI/Details/WidthEdit.editable = new_status
	$GUI/Details/HeightEdit.editable = new_status
	$GUI/Details/ConfirmButton.visible = new_status

func _on_Timer_timeout():
	current_generation += 1
	update_map()
	draw_step()
	update_gui()

func _on_ConfirmButton_pressed():
	var new_width = int($GUI/Details/WidthEdit.text)
	var new_height = int($GUI/Details/HeightEdit.text)
	if new_width > 1 and new_height > 1:
		if between(new_width, 1, MAX_WIDTH) and between(new_height, 1, MAX_HEIGHT):
			width = new_width
			height = new_height
			generate_map()
			draw_step()
		else:
			print("ERROR: Width must be in range: 1-" + str(MAX_WIDTH) + "; Height must be in range: 1-" + str(MAX_HEIGHT))
	else:
		print("ERROR: Width and height must be greater than 1")

extends Node2D


var cell_res = preload("res://Cell.tscn")
var cells = []
var rng = RandomNumberGenerator.new()
var game_is_running = false
var mine_cell_numbers = []

var alive_icon = preload("res://Assets/smile_alive.png")
var panic_icon = preload("res://Assets/smile_panic.png")
var dead_icon = preload("res://Assets/smile_dead.png")

var open_cells = 0
var guessed_mines = 0

func new_game():
	#clean board if its not first run
	if cells:
		for cell in cells:
			cell.queue_free()
		cells = []
		
	mine_cell_numbers = []
	open_cells = 0
	guessed_mines = 0
	
	$Info/Panel/RestartButton.icon = alive_icon
	
	$Info/Panel/Time.add_color_override("font_color", Color.white)
	$Info/Panel/MineCounter.add_color_override("font_color", Color.white)
	
	#set time and counter to 0 and 10
	$Info/Panel/Time.text = str(0)
	$Info/Panel/MineCounter.text = str(10)
	
	
	#generate cells
	for i in range(8):
		for j in range(8):
			var new_cell = cell_res.instance()
			new_cell.position.x += 64 * j
			new_cell.position.y += 64 * i
			cells.append(new_cell)
			
			new_cell.connect("flag_state", self, "flag_flip")
			new_cell.connect("button_clicked", self, "button_clicked")
			new_cell.connect("mouse_hold", self, "_on_mouse_hold")
			new_cell.connect("mouse_release", self, "_on_mouse_release")
		
	
	#place 10 mines randomly
	while len(mine_cell_numbers) != 10:
		rng.randomize()
		var mine_cell_number = rng.randi_range(0, 63)
		if !(mine_cell_number in mine_cell_numbers):
			mine_cell_numbers.append(mine_cell_number)
	
	for number in mine_cell_numbers:
		cells[number].is_mine = true
		cells[number].connect("BOOM", self, "game_over")
	
	#instance everything
	for cell in cells:
		$Field/Panel.add_child(cell)
		
	print(mine_cell_numbers)

func game_over():
	game_is_running = false
	$Info/Panel/RestartButton.icon = dead_icon
	
	$GameTimer.stop()
	
	$Info/Panel/Time.add_color_override("font_color", Color.red)
	$Info/Panel/MineCounter.add_color_override("font_color", Color.red)
	
	for cell in cells:
		cell.disconnect("button_clicked", self, "button_clicked")
		cell.disconnect("mouse_hold", self, "_on_mouse_hold")
		cell.disconnect("mouse_release", self, "_on_mouse_release")
		cell.get_node("Button").button_mask = 0
		if cell.is_mine:
			cell.get_node("Button").visible = false

func flag_flip(state: bool):
	if state:
		$Info/Panel/MineCounter.text = str(int($Info/Panel/MineCounter.text) - 1)
		guessed_mines += 1
	else:
		$Info/Panel/MineCounter.text = str(int($Info/Panel/MineCounter.text) + 1)
		guessed_mines -= 1

func button_clicked(cell_id: Node2D):
	cell_id.get_node("Mine").visible = false
	# if game is not running (first click on new board)
	if !game_is_running:
		# start timer, flip status game_is_running switch to true
		$GameTimer.start()
		game_is_running = true
	
		# check if first click was on mine
		open_cells += 1
		for cell in cells:
			if cell == cell_id and cell.is_mine:
				#if there was a bomb and it was a first move
				# get random number thats not in mine cells
				while cell.is_mine:
					rng.randomize()
					var mine_cell_number = rng.randi_range(0, 63)
					if !(mine_cell_number in mine_cell_numbers):
						# place mine there, change clicked cell to is_mine = false
						cell.is_mine = false
						cell.get_node("Panel/Label").text = '0'
						mine_cell_numbers.erase(cells.find(cell))
						mine_cell_numbers.append(mine_cell_number)
						cells[mine_cell_number].is_mine = true
						cells[mine_cell_number].get_node("Mine").visible = true
						cells[mine_cell_number].get_node("Mine").texture = cells[mine_cell_number].bomb_texture
						
				
		#run number placement function
		for row in range(8):
			for col in range(8):
				var mine_count = 0
				#current cell is cells[row + 8* col]
				var current_cell = cells[row + col + 7 * row]
				#check for mines around this cell clockwise
				#to the right
					#check if cell is NOT at the right edge
				if !(col == 7):
					if cells[row + col + 1 + 7 * row].is_mine:
						mine_count += 1
				#to the right-bottom
					#check if cell is not on the right edge and not at the last row
				if !(col == 7) and !(row == 7):
					if cells[row + 1 + col + 1 + (7 * (row + 1))].is_mine:
						mine_count += 1
				#to the bottom
					#check if the cell is NOT at the bottom
				if !(row == 7):
					if cells[row + 1 + col + 7 * (row + 1)].is_mine:
						mine_count += 1
				#to the left-bottom
					#check if cell is NOT at the botton and not at the left edge
				if !(col == 0) and !(row == 7):
					if cells[row + 1 + col - 1 + (7 * (row + 1))].is_mine:
						mine_count += 1
				#to the left
					#check if cell is NOT at the left edge
				if !(col == 0):
					if cells[row + col - 1 + 7 * row].is_mine:
						mine_count += 1
				#to the left-top
					#check if cell is NOT at the left edge and not at the top edge
				if !(col == 0) and !(row == 0):
					if cells[row - 1 + col - 1 + (7 * (row - 1))].is_mine:
						mine_count += 1
				#to the top
					#check if cell is not at the top edge
				if !(row == 0):
					if cells[row - 1 + col + 7 * (row - 1)].is_mine:
						mine_count += 1
				#to the right-top
					#check if cell is not at the top edge and not at the right edge
				if !(col == 7) and !(row == 0):
					if cells[row - 1 + col + 1 + (7 * (row - 1))].is_mine:
						mine_count += 1
						
				#apply mine count to cell
				current_cell.get_node("Panel/Label").text = str(mine_count)
		
		
	# else if game is running
	else:
		if !(cell_id.is_mine):
			open_cells += 1
		#check win condition
		# either all non-mine fields should be open
		if open_cells == 54:
			victory()
#		# or all mine fields should be open and all mine cells should be flagged
		elif (open_cells == 54) and (guessed_mines == 10):
			victory()
	# open empty cell
	if cell_id.get_node("Panel/Label").text == '0':
		open_zero(cell_id)

func open_zero(cell_id):
	#get cell id from cells
	var cell_index = cells.find(cell_id)
	#get row and col
	var cell_y = floor(cell_index / 8) #row, y line
	var cell_x = cell_index % 8 #col, x line

	#right
	if !(cell_x == 7):
		if cells[cell_index + 1].get_node("Button").visible:
			cells[cell_index + 1].get_node("Button").visible = false
			open_cells += 1
			if cells[cell_index + 1].get_node("Panel/Label").text == '0':
				open_zero(cells[cell_index + 1])
	#right-bottom
	if !(cell_x == 7) and !(cell_y == 7):
		if cells[cell_index + 9].get_node("Button").visible:
			cells[cell_index + 9].get_node("Button").visible = false
			open_cells += 1
			if cells[cell_index + 9].get_node("Panel/Label").text == '0':
				open_zero(cells[cell_index + 9])
	#bottom
	if !(cell_y == 7):
		if cells[cell_index + 8].get_node("Button").visible:
			cells[cell_index + 8].get_node("Button").visible = false
			open_cells += 1
			if cells[cell_index + 8].get_node("Panel/Label").text == '0':
				open_zero(cells[cell_index + 8])
	#bottom-left
	if !(cell_x == 0) and !(cell_y == 7):
		if cells[cell_index + 7].get_node("Button").visible:
			cells[cell_index + 7].get_node("Button").visible = false
			open_cells += 1
			if cells[cell_index + 7].get_node("Panel/Label").text == '0':
				open_zero(cells[cell_index + 7])
	#left
	if !(cell_x == 0) and !(cell_y == 7):
		if cells[cell_index - 1].get_node("Button").visible:
			cells[cell_index - 1].get_node("Button").visible = false
			open_cells += 1
			if cells[cell_index - 1].get_node("Panel/Label").text == '0':
				open_zero(cells[cell_index - 1])
	#top-left
	if !(cell_x == 0) and !(cell_y == 0):
		if cells[cell_index - 9].get_node("Button").visible:
			cells[cell_index - 9].get_node("Button").visible = false
			open_cells += 1
			if cells[cell_index - 9].get_node("Panel/Label").text == '0':
				open_zero(cells[cell_index - 9])
	#top
	if !(cell_y == 0):
		if cells[cell_index - 8].get_node("Button").visible:
			cells[cell_index - 8].get_node("Button").visible = false
			open_cells += 1
			if cells[cell_index - 8].get_node("Panel/Label").text == '0':
				open_zero(cells[cell_index - 8])
	#top-right
	if !(cell_x == 7) and !(cell_y == 0):
		if cells[cell_index - 7].get_node("Button").visible:
			cells[cell_index - 7].get_node("Button").visible = false
			open_cells += 1
			if cells[cell_index - 7].get_node("Panel/Label").text == '0':
				open_zero(cells[cell_index - 7])

func _ready():
	new_game()


func _on_RestartButton_pressed():
	new_game()


func victory():
	game_is_running = false
	$GameTimer.stop()
	
	$Info/Panel/Time.add_color_override("font_color", Color.green)
	$Info/Panel/MineCounter.add_color_override("font_color", Color.green)
	
	for cell in cells:
		cell.disconnect("button_clicked", self, "button_clicked")
		cell.disconnect("mouse_hold", self, "_on_mouse_hold")
		cell.disconnect("mouse_release", self, "_on_mouse_release")
		cell.get_node("Button").button_mask = 0



func _on_GameTimer_timeout():
	$Info/Panel/Time.text = str(int($Info/Panel/Time.text) + 1)


func _on_mouse_hold():
	$Info/Panel/RestartButton.icon = panic_icon

func _on_mouse_release():
	$Info/Panel/RestartButton.icon = alive_icon

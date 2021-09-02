extends Node2D

var bomb_texture = preload("res://Assets/bomb.png")
var busted_bomb_texture = preload("res://Assets/bomb_busted.png")
signal BOOM
signal flag_state(state)
signal button_clicked(cell_id)
signal mouse_hold
signal mouse_release

var NUM_COLORS =  {
		0: Color.white,
		1: Color.blue,
		2: Color.green,
		3: Color.red,
		4: Color.violet,
		5: Color.maroon,
		6: Color.turquoise,
		7: Color.black,
		8: Color.gray,
	}

var is_mine = false

var button_flagged = false
var is_under_mouse = false

func _ready():
	if is_mine:
		$Panel.visible = false
		$Mine.visible = true
		$Mine.texture = bomb_texture
	else:
		$Panel.visible = true
		$Mine.visible = false

func _physics_process(_delta):
	$Button/Flag.visible = button_flagged
	if !(is_mine):
		$Panel/Label.add_color_override("font_color", NUM_COLORS[int($Panel/Label.text)])
	else:
		$Panel/Label.text = ''
	
	if is_mine:
		$Panel.visible = false
		$Mine.visible = true
	else:
		$Panel.visible = true
		$Mine.visible = false
	
	if Input.is_action_just_pressed("MOUSE_RIGHT") and is_under_mouse:
		button_flagged = !button_flagged
		emit_signal("flag_state", button_flagged)
		$Button.button_mask = 0 if button_flagged else 1
	if Input.is_action_pressed("MOUSE_LEFT"):
		emit_signal("mouse_hold")
	if Input.is_action_just_released("MOUSE_LEFT"):
		emit_signal("mouse_release")


func _on_Button_pressed():
	$Button.visible = false
	emit_signal("button_clicked", self)
	is_under_mouse = false
	if is_mine:
		$Mine.texture = busted_bomb_texture
		emit_signal("BOOM")


func _on_Button_mouse_entered():
	is_under_mouse = true


func _on_Button_mouse_exited():
	is_under_mouse = false

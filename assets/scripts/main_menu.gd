extends Control
class_name MainMenu

signal start_game()

@onready var buttons_v_box: VBoxContainer = %ButtonsVBox
# Called when the node enters the scene tree for the first time.

@warning_ignore("untyped_declaration")
func _ready():
	focus_button()


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("untyped_declaration", "unused_parameter")
func _process(delta):
	pass


func _on_start_game_button_pressed() -> void:
	start_game.emit()
	hide()
	

func _on_options_button_pressed() -> void:
	# add stuff here later
	pass


func _on_visibility_changed() -> void:
	if visible:
		focus_button()
		

func focus_button() -> void:
	if buttons_v_box:
		var button: Button = buttons_v_box.get_child(0)
		if button is Button:
			button.grab_focus()


func _on_quit_game_button_pressed() -> void:
	get_tree().quit()

extends RichTextLabel

func _ready() -> void:
	bbcode_enabled = true
	update_city_display()


func update_city_display() -> void:
	if Data.Current_City != "none":
		text = "Current City: " + Data.Current_City


# If you want to call this from elsewhere when the city changes
func _on_city_changed() -> void:
	update_city_display()

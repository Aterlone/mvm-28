extends Area2D

@export_enum (
	"central",
	"city",
	"wastes",
	"depths"
) var room_name : String
	
@export var room_number : int

@export_enum (
	"up",
	"down",
	"left",
	"right"
   ) var direction : String
	
@export_enum (
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
) var room_char : String


func _ready() -> void:
	name = "Warp" + room_char

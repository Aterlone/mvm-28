extends Node2D

@export var next_level_index = 0

@export_enum (
	"city",
	"central",
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

extends Node

const GlobalGd                 = preload("res://core/GlobalNames.gd")


func deleted(_a):
	assert(false)


func _init():
	add_to_group(GlobalGd.Groups.Agents)


func _process( delta ):
	processMovement( delta )


func processMovement( delta ):
	assert(false)


func assignUnits( units ):
	assert(false)


func unassignUnits( units ):
	assert(false)

extends VBoxContainer

const UnitCreatorName = "UnitCreator"

var _mainMenu


func _ready():
	_mainMenu = get_parent()
	_mainMenu.get_node("Buttons/NewGame").connect("pressed", self, "deleteCreator")


func newCreator():
	var unitCreator = UnitCreator.new()
	unitCreator.name = UnitCreatorName
	$"/root/Connector".connect("newGameSceneConnected", unitCreator, "connectOnReady" )

	deleteCreator()
	$"/root".add_child( unitCreator )


func deleteCreator():
	if not $"/root".has_node( UnitCreatorName ):
		return

	var creator = $"/root".get_node( UnitCreatorName )
	Utility.setFreeing( creator )


func _on_NewCreateButton_pressed():
	newCreator()
	_mainMenu.newGame()


class UnitCreator extends Node:
	var CharacterCreationScn   = preload("res://core/gui/CharacterCreation.tscn")

	func connectOnReady( newGameScene ):
		newGameScene.connect( "ready", self, "createUnit", [newGameScene] )

	func createUnit( newGameScene ):
		if is_queued_for_deletion():
			return

		var characterCreation__ = CharacterCreationScn.instance()
		characterCreation__.initialize( newGameScene._module )
		var characterDatum = characterCreation__.makeCharacter()
		characterCreation__.free()

		newGameScene.get_node( "Lobby" ).createCharacter( characterDatum )
		self.queue_free()

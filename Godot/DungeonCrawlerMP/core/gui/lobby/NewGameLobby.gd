extends "LobbyBase.gd"

const CharacterCreationScn   = preload("res://core/gui/CharacterCreation.tscn")
const UnitLineScn            = preload("UnitLine.tscn")
const UtilityGd              = preload("res://core/Utility.gd")
const GameCreatorGd          = preload("res://core/game/GameCreator.gd")

var m_module                           setget setModule
var m_unitsCreationData = []           setget deleted   # array of dicts
var m_characterCreationWindow          setget deleted


signal unitNumberChanged( unitNumber )


func deleted(_a):
	assert(false)


func _ready():
	connect("unitNumberChanged", self, "onUnitNumberChanged")


func refreshLobby( clientList ):
	.refreshLobby( clientList )
	deleteUnownedUnits( clientList )

	if not Network.isServer():
		return

	for clientId in m_rpcTargets:
		assert( clientId != Network.ServerId )
		if clientId in clientList:
			sendToClient( clientId )


func deleteUnownedUnits( playerIds ):
	var indicesToRemove = []
	for unitIdx in range( m_unitsCreationData.size() ):
		if not m_unitsCreationData[unitIdx].owner in playerIds:
			indicesToRemove.append( unitIdx )
	indicesToRemove.sort_custom(UtilityGd, "greaterThan")

	for idx in indicesToRemove:
		removeUnit( idx )


func clearUnits():
	m_unitsCreationData.clear()
	for child in get_node("Players/Scroll/UnitList").get_children():
		child.queue_free()

	emit_signal("unitNumberChanged", m_unitsCreationData.size())


puppet func addUnit( creationDatum : Dictionary ):
	if m_unitsCreationData.size() >= m_maxUnits:
		return false
	else:
		m_unitsCreationData.append( creationDatum )
		emit_signal("unitNumberChanged", m_unitsCreationData.size())
		return addUnitLine( m_unitsCreationData.size() - 1 )


master func requestAddUnit( creationDatum : Dictionary ):
	if addUnit( creationDatum ):
		Network.RPC( self, ["addUnit", creationDatum] )


func addUnitLine( unitIdx ):
	var unitLine = UnitLineScn.instance()

	get_node("Players/Scroll/UnitList").add_child(unitLine)
	unitLine.initialize( unitIdx, m_unitsCreationData[unitIdx].owner )
	unitLine.setUnit( m_unitsCreationData[unitIdx].name )
	unitLine.connect("deletePressed", self, "onDeleteUnit")
	return true


func createCharacter( creationDatum : Dictionary ):
	if is_network_master():
		if ( addUnit( creationDatum ) ):
			Network.RPC( self, ["addUnit", creationDatum] )
	else:
		Network.RPCmaster( self, ["requestAddUnit", creationDatum] )


puppet func removeUnit( unitIdx ):
	m_unitsCreationData.remove( unitIdx )
	get_node("Players/Scroll/UnitList").get_child( unitIdx ).queue_free()
	emit_signal("unitNumberChanged", m_unitsCreationData.size())


master func requestRemoveUnit( unitIdx ):
	assert( is_network_master() )
	if get_tree().get_rpc_sender_id() != m_unitsCreationData[unitIdx].owner:
		return

	removeUnit( unitIdx )
	Network.RPC( self, ["removeUnit", unitIdx] )


func onDeleteUnit( unitIdx ):
	if Network.isServer():
		removeUnit( unitIdx )
		Network.RPC( self, ["removeUnit", unitIdx] )
	else:
		rpc("requestRemoveUnit", unitIdx)


puppet func receiveState( unitsCreationData ):
	assert( not get_tree().is_network_server() )

	clearUnits()
	for creationDatum in unitsCreationData:
		addUnit( creationDatum )


func sendToClient( id ):
	assert( get_tree().is_network_server() )
	if id != get_tree().get_network_unique_id():
		Network.RPCid( self, id, ["receiveState", m_unitsCreationData] )


func onCreateCharacterPressed():
	if m_characterCreationWindow != null:
		return

	m_characterCreationWindow = CharacterCreationScn.instance()
	add_child(m_characterCreationWindow)
	m_characterCreationWindow.connect("tree_exited", self, "removeCharacterCreationWindow")
	m_characterCreationWindow.connect("madeCharacter", self, "createCharacter")
	m_characterCreationWindow.initialize(m_module)


func removeCharacterCreationWindow():
	if not m_characterCreationWindow.is_queued_for_deletion():
		m_characterCreationWindow.queue_free()

	m_characterCreationWindow = null


func onUnitNumberChanged( unitNumber ):
	get_node("UnitLimit").setCurrent( m_unitsCreationData.size() )
	get_node("CreateCharacter").disabled = m_unitsCreationData.size() == m_maxUnits


func setModule( module ):
	m_module = module


func setMaxUnits( maxUnits ):
	.setMaxUnits( maxUnits )
	get_node("CreateCharacter").disabled = m_unitsCreationData.size() == m_maxUnits


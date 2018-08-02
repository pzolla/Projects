extends Node2D

const UtilityGd              = preload("res://Utility.gd")


var m_rpcTargets = []                  setget deleted # setRpcTargets


func deleted():
	assert(false)
	

signal destroyed()


func _enter_tree():
	if Network.isServer():
		Network.connect("nodeRegisteredClientsChanged", self, "onNodeRegisteredClientsChanged")
	else:
		Network.rpc( "registerNodeForClient", get_path() )


func _exit_tree():
	assert( get_tree().has_network_peer() )
	Network.rpc( "unregisterNodeForClient", get_path() )
		
		
func _ready():
	assert( $"Entrances".get_child_count() > 0 )


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		emit_signal( "destroyed" )


func setGroundTile(tileName, x, y):
	get_node("Ground").setTile(tileName, x, y)


func sendToClient(clientId):
	get_node("Ground").sendToClient(clientId)
	get_node("Units").sendToClient(clientId)


func serialize():
	var saveDict = {
		scene = get_filename(),
		ground = get_node("Ground").serialize(),
		units = get_node("Units").serialize()
	}
	return saveDict


func deserialize(saveDict):
	get_node("Ground").deserialize(saveDict["ground"])
	get_node("Units").deserialize(saveDict["units"])


func removeChildUnit( unitNode ):
	assert( get_node("Units").has_node( unitNode.get_path() ) )
	get_node("Units").remove_child( unitNode )


func onNodeRegisteredClientsChanged( nodePath ):
	if nodePath == get_path():
		setRpcTargets( Network.m_nodesWithClients[nodePath] )


func setRpcTargets( clientIds ):
	assert( Network.isServer() )
	m_rpcTargets = clientIds

	for unit in $"Units".get_children():
		unit.setRpcTargets( clientIds )


func findEntranceWithAllUnits( unitNodes ):
	var entrances = get_node("Entrances").get_children()

	var entranceWithPlayers
	for entrance in entrances:
		if entranceWithPlayers != null:
			break

		for body in entrance.get_overlapping_bodies():
			if unitNodes.has( body ):
				entranceWithPlayers = entrance
				break

	if entranceWithPlayers == null:
		return null

	if UtilityGd.isSuperset( entranceWithPlayers.get_overlapping_bodies(), unitNodes ):
		return entranceWithPlayers
	else:
		return null


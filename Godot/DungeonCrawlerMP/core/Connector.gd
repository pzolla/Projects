extends Node

const GameScenePath          = "res://core/game/GameScene.tscn"
const MainMenuPath           = "res://core/gui/MainMenuScene.tscn"
const GameSceneGd            = preload("./game/GameScene.gd")
const AcceptDialogGd         = preload("./gui/AcceptDialog.gd")

var m_game                             setget setGame


signal newGameSceneConnected( node )


func deleted(_a):
	assert(false)


func _init():
	set_pause_mode(PAUSE_MODE_PROCESS)
	print( "-----\nSTART\n-----" )


func _ready():
	Network.connect("networkError", self, "onNetworkError")


func connectMainMenu():
	Network.connect("serverGameStatus", get_tree().current_scene, "receiveGameStatus")


func toMainMenu():
	SceneSwitcher.connect( "sceneSetAsCurrent", self, "connectMainMenu", [], CONNECT_ONESHOT )
	SceneSwitcher.switchScene( MainMenuPath )


func connectNewGameScene( newGameScene ):
	Network.connect("networkError",       newGameScene, "onNetworkError")
	Network.connect("clientListChanged",  newGameScene.get_node("Lobby"), "refreshLobby")

	newGameScene.connect("readyForGame",  self, "createGame")
	newGameScene.connect("finished",      Network, "endConnection")
	newGameScene.connect("finished",      self, "toMainMenu")

	emit_signal( "newGameSceneConnected", newGameScene )


remote func createGame( module_, playerUnits ):
	if Network.isServer():
		rpc( "createGame", null, null ) # TODO: only for players

	SceneSwitcher.connect( "sceneSetAsCurrent", self, "connectGame", [], CONNECT_ONESHOT )
	SceneSwitcher.switchScene( GameScenePath,
		{
			GameSceneGd.Params.Module : module_,
			GameSceneGd.Params.PlayerUnitsData : playerUnits,
			GameSceneGd.Params.PlayerIds : Network.getOtherClientsIds(),
		} )


func connectGame():
	assert( m_game == null )
	var gameScene = get_tree().current_scene
	assert( gameScene is GameSceneGd )

	setGame( gameScene )


func onGameEnded():
	assert( m_game )

	SceneSwitcher.connect( "sceneSetAsCurrent", Network, "endConnection", [], CONNECT_ONESHOT )
	toMainMenu()
	setGame( null )


func setGame( gameScene : GameSceneGd ):
	assert( gameScene == null or m_game == null )
	m_game = gameScene

	if gameScene:
		gameScene.connect( "gameFinished", self, "onGameEnded", [], CONNECT_ONESHOT )


func loadGame( filePath ):
	if not isGameInProgress():
		SceneSwitcher.switchScene( GameScenePath, {} )
		yield( SceneSwitcher, "sceneSetAsCurrent" )
		connectGame()
		yield( get_tree().current_scene, "readyCompleted" )
	else:
		yield( m_game.get_tree(), "idle_frame" )

	m_game.loadGame( filePath )


func isGameInProgress():
	return m_game != null


func onNetworkError( errorMessage ):
	if errorMessage == Network.ServerDisconnectedError:
		Network.endConnection()
		if m_game:
			setGame( null )
		call_deferred("toMainMenu")

	AcceptDialogGd.new().showAcceptDialog( \
		errorMessage, "Connection error", $"/root" )


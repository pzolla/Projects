extends Reference

const NodeGuardGd            = preload("./NodeGuard.gd")
const SaveGameFileGd         = preload("./SaveGameFile.gd")

const SERIALIZE              = "serialize"
const DESERIALIZE            = "deserialize"
const POST_DESERIALIZE       = "post_deserialize"

enum Index { Name, Scene, OwnData, FirstChild }

var _version : String = "0.0.0"
var _nodesData := {}

var userData := {}
var resourceExtension := ".tres" if OS.has_feature("debug") else ".res"


func addSerialized( key : String, serializedNode : Array ) -> void:
	_nodesData[ key ] = serializedNode


func remove( key : String ) -> bool:
	return _nodesData.erase( key )


func hasKey( key : String ) -> bool:
	return _nodesData.has( key )


func getSerialized( key : String ) -> Array:
	return _nodesData[key]


func getKeys() -> Array:
	return _nodesData.keys()


func getVersion() -> String:
	return _version


func saveToFile( filepath : String ) -> int:
	var baseDirectory = filepath.get_base_dir()

	if not filepath.is_valid_filename() and baseDirectory.empty():
		print("not a valid filepath")
		return ERR_CANT_CREATE

	var dir := Directory.new()
	if not dir.dir_exists( baseDirectory ):
		var error = dir.make_dir_recursive( baseDirectory )
		if error != OK:
			print( "could not create a directory" )
			return error

	var stateToSave = SaveGameFileGd.new()

	var ver = ProjectSettings.get_setting("application/config/version")
	if typeof(ver) == TYPE_STRING:
		_version = ver

	stateToSave.version = _version
	stateToSave.nodesDict = _nodesData
	stateToSave.userDict = userData

	var pathToSave = filepath
	if not filepath.get_extension() in ResourceSaver.get_recognized_extensions(stateToSave):
		pathToSave += resourceExtension

	var error := ResourceSaver.save( pathToSave, stateToSave )
	if error != OK:
		print( "could not save a Resource" )
		return error

	return OK


func loadFromFile( filepath : String ) -> int:
	var pathToLoad = filepath
	if "." + filepath.get_extension() != resourceExtension:
		pathToLoad += resourceExtension

	var file := File.new()
	if not file.file_exists( pathToLoad ):
		print( "files does not exist" )
		return ERR_DOES_NOT_EXIST

	var loadedState : SaveGameFileGd = load( pathToLoad )
	_version = loadedState.version
	_nodesData = loadedState.nodesDict
	userData = loadedState.userDict
	return OK


# returns an Array with: node name, scene, node's own data, serialized children (if any)
func serialize( node : Node ) -> Array:
	var data := [
		node.name,
		node.filename,
		node.serialize() if _isSerializableFn.call_func( node ) else null
	]

	for child in node.get_children():
		var childData = serialize( child )
		if not childData.empty():
			data.append( childData )

	if data[ Index.OwnData ] == null and data.size() <= Index.FirstChild:
		return []
	else:
		return data


# parent can be null
func deserialize( data : Array, parent : Node ) -> NodeGuardGd:
	var nodeName  = data[Index.Name]
	var sceneFile = data[Index.Scene]
	var ownData   = data[Index.OwnData]

	var node : Node
	if not parent:
		if !sceneFile.empty():
			node = load( sceneFile ).instance()
			node.name = nodeName
	else:
		node = parent.get_node_or_null( nodeName )
		if not node:
			if !sceneFile.empty():
				node = load( sceneFile ).instance()
				parent.add_child( node )
				assert( parent.is_a_parent_of( node ) )
				node.name = nodeName

	if not node:
		return NodeGuardGd.new()# node didn't exist and could not be created by serializer

	if node.has_method( DESERIALIZE ):
		# warning-ignore:return_value_discarded
		node.deserialize( ownData )

	for childIdx in range( Index.FirstChild, data.size() ):
		# warning-ignore:return_value_discarded
		deserialize( data[childIdx], node )

	if node.has_method( POST_DESERIALIZE ):
		node.post_deserialize()

	return NodeGuardGd.new( node )


const TilesetScn = preload("res://assets/BattleCityTiles.tscn")
const StageControlGd = preload("res://stages/StageControl.gd")

var m_cellIdMap = {}

func prepareStage(stage):
	assignCellIds(stage)
	var groundTilemap = stage.get_node("Ground")

	if ( TilesetScn != null and groundTilemap != null):
		replaceBrickWallTilesWithNodes(groundTilemap, TilesetScn, stage)
		replaceWaterTilesWithNodes(groundTilemap, TilesetScn, stage)


func assignCellIds(stage):
	var tileNames = [ "Water", "Trees", "Ice", "Grey", 
		"WallSteel", "WallSteel2", "WallSteel4", "WallSteel6", "WallSteel8",
		"WallBrick", "WallBrick2", "WallBrick4", "WallBrick6", "WallBrick8"
		]
	var tileset = stage.get_node("Ground").get_tileset()
	
	for name in tileNames:
		assert( tileset.find_tile_by_name(name) != -1 )
		m_cellIdMap[name] = tileset.find_tile_by_name(name)


# splitting each brick tile into WallBrickSmalls
func replaceBrickWallTilesWithNodes(groundTilemap, packedTilesScene, stage):
	var tilesTree = packedTilesScene.instance()
	var wallBrickSmallPrototype = tilesTree.get_node("WallBrickSmall")
	assert( wallBrickSmallPrototype )
	wallBrickSmallPrototype.add_to_group(StageControlGd.BRICKS_GROUP)
	var wallBrickPositions = []
	
	for cell in groundTilemap.get_used_cells():
		if ( groundTilemap.get_cellv(cell) == m_cellIdMap["WallBrick"] ):
			groundTilemap.set_cellv(cell, -1)
			var cellCoords = groundTilemap.map_to_world( cell )
			wallBrickPositions.append( Vector2(cellCoords.x + 4, cellCoords.y + 4) )
			wallBrickPositions.append( Vector2(cellCoords.x + 4 + 8, cellCoords.y + 4) )
			wallBrickPositions.append( Vector2(cellCoords.x + 4, cellCoords.y + 4 + 8) )
			wallBrickPositions.append( Vector2(cellCoords.x + 4 + 8, cellCoords.y + 4 + 8) )
		elif ( groundTilemap.get_cellv(cell) == m_cellIdMap["WallBrick6"] ):
			groundTilemap.set_cellv(cell, -1)
			var cellCoords = groundTilemap.map_to_world( cell )
			wallBrickPositions.append( Vector2(cellCoords.x + 4 + 8, cellCoords.y + 4) )
			wallBrickPositions.append( Vector2(cellCoords.x + 4 + 8, cellCoords.y + 4 + 8) )
		elif ( groundTilemap.get_cellv(cell) == m_cellIdMap["WallBrick4"] ):
			groundTilemap.set_cellv(cell, -1)
			var cellCoords = groundTilemap.map_to_world( cell )
			wallBrickPositions.append( Vector2(cellCoords.x + 4, cellCoords.y + 4) )
			wallBrickPositions.append( Vector2(cellCoords.x + 4, cellCoords.y + 4 + 8) )
		elif ( groundTilemap.get_cellv(cell) == m_cellIdMap["WallBrick2"] ):
			groundTilemap.set_cellv(cell, -1)
			var cellCoords = groundTilemap.map_to_world( cell )
			wallBrickPositions.append( Vector2(cellCoords.x + 4, cellCoords.y + 4 + 8) )
			wallBrickPositions.append( Vector2(cellCoords.x + 4 + 8, cellCoords.y + 4 + 8) )
		elif ( groundTilemap.get_cellv(cell) == m_cellIdMap["WallBrick8"] ):
			groundTilemap.set_cellv(cell, -1)
			var cellCoords = groundTilemap.map_to_world( cell )
			wallBrickPositions.append( Vector2(cellCoords.x + 4, cellCoords.y + 4) )
			wallBrickPositions.append( Vector2(cellCoords.x + 4 + 8, cellCoords.y + 4) )
	
	for position in wallBrickPositions:
		var wallBrickSmall = wallBrickSmallPrototype.duplicate()
		assert( wallBrickSmall.get_name() == "WallBrickSmall" )
		assert( wallBrickSmall.is_in_group(StageControlGd.BRICKS_GROUP) )
		stage.add_child( wallBrickSmall )
		wallBrickSmall.set_pos( position )

	tilesTree.free()
	
	
func replaceWaterTilesWithNodes(groundTilemap, packedTilesScene, stage):
	var tilesTree = packedTilesScene.instance()
	var waterPrototype = tilesTree.get_node("Water")
	assert( waterPrototype )

	var waterPositions = []
	for cell in groundTilemap.get_used_cells():
		if ( groundTilemap.get_cellv(cell) == m_cellIdMap["Water"] ):
			groundTilemap.set_cellv(cell, -1)
			var cellCoords = groundTilemap.map_to_world( cell )
			waterPositions.append( Vector2(cellCoords.x + 8, cellCoords.y + 8) )

	for position in waterPositions:
		var water = waterPrototype.duplicate()
		assert( water.get_name() == "Water" )
		stage.add_child( water )
		water.set_pos( position )

	tilesTree.free()
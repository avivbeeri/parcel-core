import "./tilesheet" for Tilesheet

var CustomSheet = Tilesheet.new("res/camp-tiles.png")

var TentTile = CustomSheet.getTile(0, 0, 16, 16, false)
var VoidTile = CustomSheet.getTile(40, 8, false)
var DoorTile = CustomSheet.getTile(32, 8, false)
var FireTiles = [ CustomSheet.getTile(16, 0, false), CustomSheet.getTile(24, 0, false) ]
var PlayerStandTiles = [ CustomSheet.getTile(16, 8, false), CustomSheet.getTile(24, 8, false) ]
var PlayerWalkTiles = [ CustomSheet.getTile(32, 0, false), CustomSheet.getTile(40, 0, false) ]

var SmallSheet = Tilesheet.new("res/small.png")
var GrassTile = SmallSheet.getTile(40, 32, false)

var InvertedGrassTile = SmallSheet.getTile(40, 32, true)
var InvertedTentTile = CustomSheet.getTile(0, 0, 16, 16, true)
var InvertedVoidTile = CustomSheet.getTile(40, 8, true)
var InvertedDoorTile = CustomSheet.getTile(32, 8, true)
var InvertedFireTiles = [ CustomSheet.getTile(16, 0, true), CustomSheet.getTile(24, 0, true) ]
var InvertedPlayerStandTiles = [ CustomSheet.getTile(16, 8, true), CustomSheet.getTile(24, 8, true) ]
var InvertedPlayerWalkTiles = [ CustomSheet.getTile(32, 0, true), CustomSheet.getTile(40, 0, true) ]

var StandardSpriteSet = {
  "tent": [ TentTile ],
  "void": [ VoidTile ],
  "door": [ DoorTile ],
  "fire": FireTiles,
  "playerStand": PlayerStandTiles,
  "playerWalk": PlayerWalkTiles,
  "grass": [ GrassTile ],
}

var InvertedSpriteSet = {
  "tent": [ InvertedTentTile ],
  "void": [ InvertedVoidTile ],
  "door": [ InvertedDoorTile ],
  "fire": InvertedFireTiles,
  "playerStand": InvertedPlayerStandTiles,
  "playerWalk": InvertedPlayerWalkTiles,
  "grass": [ InvertedGrassTile ],
}


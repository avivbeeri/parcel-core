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

var StandardSpriteSet = {
  "tent": [ TentTile ],
  "void": [ VoidTile ],
  "door": [ DoorTile ],
  "fire": FireTiles,
  "playerStand": PlayerStandTiles,
  "playerWalk": PlayerWalkTiles,
  "grass": [ GrassTile ],
}


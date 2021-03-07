import "./core/tilesheet" for Tilesheet

var Sheet = Tilesheet.new("res/camp-tiles.png", 8)

var FireTiles = [ Sheet.getTile(10), Sheet.getTile(11) ]
var PlayerStandTiles = [ Sheet.getTile(0), Sheet.getTile(1) ]
var PlayerWalkTiles = [ Sheet.getTile(2), Sheet.getTile(3) ]
var GrassTile = Sheet.getTile(4)

var StandardSpriteSet = {
  "fire": FireTiles,
  "playerStand": PlayerStandTiles,
  "playerWalk": PlayerWalkTiles,
  "grass": [ GrassTile ],
}


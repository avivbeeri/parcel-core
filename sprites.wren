import "graphics" for ImageData
import "./core/tilesheet" for Tilesheet
var scale = 1

var CharSheet = Tilesheet.new("res/img/charsheet.png", 16, scale)
var RoomSheet = Tilesheet.new("res/img/room.png", 16, scale)
var EntitySheet = Tilesheet.new("res/img/entities.png", 16, scale)
var AttackSheet = Tilesheet.new("res/img/attack-swipe.png", 16, scale)
var BasicAttack = (0...6).map {|i| AttackSheet.getTile(i) }.toList
var LightningAttack = (6...12).map {|i| AttackSheet.getTile(i) }.toList
var Buff = (12...18).map {|i| AttackSheet.getTile(i) }.toList
var Debuff = (18...24).map {|i| AttackSheet.getTile(i) }.toList
var Commune = (24...30).map {|i| AttackSheet.getTile(i) }.toList
var Block = (30...36).map {|i| AttackSheet.getTile(i) }.toList
var Inert = (36...42).map {|i| AttackSheet.getTile(i) }.toList

var PlayerStandTiles = [ CharSheet.getTile(0), CharSheet.getTile(1) ]
var PlayerWalkTiles = [ CharSheet.getTile(2), CharSheet.getTile(3) ]

var FloorTile = RoomSheet.getTile(21)
var Icons = (7..9).map {|i| RoomSheet.getTile(i) }.toList
var WallTiles = (0...20).map {|i| RoomSheet.getTile(40 + i) }.toList

var SwordTiles = (0..1).map {|i| EntitySheet.getTile(i) }.toList
var ShieldTiles = (2..3).map {|i| EntitySheet.getTile(i) }.toList
var CardItem = (4..5).map {|i| EntitySheet.getTile(i) }.toList
var ThunderTiles = (6..7).map {|i| EntitySheet.getTile(i) }.toList
var FireballTiles = (8..9).map {|i| EntitySheet.getTile(i) }.toList
var WizardTiles = (10..11).map {|i| EntitySheet.getTile(i) }.toList
var ShadowTiles = (12..13).map {|i| EntitySheet.getTile(i) }.toList
var CardBack = ImageData.loadFromFile("res/img/card-back-small.png")

var StandardSpriteSet = {
  "playerStand": PlayerStandTiles,
  "playerWalk": PlayerWalkTiles,
  "floor": [ FloorTile ],
  "wall": WallTiles,
  "card": CardItem,
  "sword": SwordTiles,
  "shield": ShieldTiles,
  "thunder": ThunderTiles,
  "fireball": FireballTiles,
  "wizard": WizardTiles,
  "cardback": CardBack,
  "basicAttack": BasicAttack,
  "debuff": Debuff,
  "buff": Buff,
  "shadow": ShadowTiles,
  "commune": Commune,
  "lightningAttack": LightningAttack,
  "icons": Icons,
  "blocked": Block,
  "inert": Inert
}


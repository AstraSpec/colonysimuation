class_name RegionDef

var id :int = -1
var cells :Array[Vector2i] = []
var neighbours :Array[RegionDef] = []

var terrain :Array[TileDef] = []
var floor :Array[TileDef] = []
var wall :Array[TileDef] = []
var object :Array[TileDef] = []

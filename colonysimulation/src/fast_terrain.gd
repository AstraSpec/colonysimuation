extends TextureRect

const TILE_SIZE = 16

var terrainImage: Image
var atlasTexture: Texture2D

func set_cells_terrain(cells :Array, terrainData :TileDef, WORLD_SIZE :Vector2i) -> void:
	var atlas: Vector2i = terrainData.atlas
	atlasTexture = terrainData.texture
	
	if not terrainImage:
		terrainImage = Image.create_empty(WORLD_SIZE.x, WORLD_SIZE.y, false, Image.FORMAT_RGB8)
		terrainImage.fill(Color.BLACK)
	
	for i in range(cells.size()):
		var cellPos: Vector2i = cells[i]
		
		if cellPos.x >= 0 and cellPos.x < WORLD_SIZE.x and cellPos.y >= 0 and cellPos.y < WORLD_SIZE.y:
			var variant := Vector2i(cellPos.x % 3, cellPos.y % 3)
			var variantAtlas := Vector2i(atlas.x + variant.x, atlas.y + variant.y)
			
			var tileColor = Color(float(variantAtlas.x) / 255.0, float(variantAtlas.y) / 255.0, 1.0)
			
			terrainImage.set_pixel(cellPos.x, cellPos.y, tileColor)
	
	var terrainTexture = ImageTexture.new()
	terrainTexture.set_image(terrainImage)
	
	material.set_shader_parameter("terrain_data_texture", terrainTexture)
	material.set_shader_parameter("atlas_texture", atlasTexture)
	material.set_shader_parameter("tile_size", TILE_SIZE)
	material.set_shader_parameter("world_size", WORLD_SIZE)
	
	var textureSize = atlasTexture.get_size()
	var tileCount = Vector2(textureSize.x / TILE_SIZE, textureSize.y / TILE_SIZE)
	material.set_shader_parameter("atlas_tile_count", tileCount)
	
	size = Vector2(WORLD_SIZE.x * TILE_SIZE, WORLD_SIZE.y * TILE_SIZE)
	texture = atlasTexture

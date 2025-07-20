#include "fast_tilemap.h"

using namespace godot;

const std::unordered_map<int, Vector2> FastTileMap::autotile_variant_map = {
	{0, Vector2(0, 0)},
	{2, Vector2(0, 3)},
	{8, Vector2(3, 0)},
	{10, Vector2(10, 2)},
	{11, Vector2(3, 3)},
	{16, Vector2(1, 0)},
	{18, Vector2(8, 2)},
	{22, Vector2(1, 3)},
	{24, Vector2(2, 0)},
	{26, Vector2(9, 2)},
	{27, Vector2(6, 3)},
	{30, Vector2(5, 3)},
	{31, Vector2(2, 3)},
	{64, Vector2(0, 1)},
	{66, Vector2(0, 2)},
	{72, Vector2(10, 0)},
	{74, Vector2(10, 1)},
	{75, Vector2(7, 2)},
	{80, Vector2(8, 0)},
	{82, Vector2(8, 1)},
	{86, Vector2(4, 2)},
	{88, Vector2(9, 0)},
	{90, Vector2(9, 1)},
	{91, Vector2(4, 0)},
	{94, Vector2(7, 0)},
	{95, Vector2(12, 2)},
	{104, Vector2(3, 1)},
	{106, Vector2(7, 1)},
	{107, Vector2(3, 2)},
	{120, Vector2(6, 0)},
	{122, Vector2(4, 3)},
	{123, Vector2(11, 1)},
	{126, Vector2(11, 0)},
	{127, Vector2(6, 2)},
	{208, Vector2(1, 1)},
	{210, Vector2(4, 1)},
	{214, Vector2(1, 2)},
	{216, Vector2(5, 0)},
	{218, Vector2(7, 3)},
	{219, Vector2(12, 0)},
	{222, Vector2(12, 1)},
	{223, Vector2(5, 2)},
	{248, Vector2(2, 1)},
	{250, Vector2(11, 2)},
	{251, Vector2(6, 1)},
	{254, Vector2(5, 1)},
	{255, Vector2(2, 2)}
};

void FastTileMap::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_tile", "cellPos", "tile", "TILE_SIZE", "texture"), &FastTileMap::set_tile);
	ClassDB::bind_method(D_METHOD("clear_tiles", "tileRIDs"), &FastTileMap::clear_tiles);
	ClassDB::bind_method(D_METHOD("set_cells_autotile", "cellPositions", "TILE_SIZE", "texture"), &FastTileMap::set_cells_autotile);
}

FastTileMap::FastTileMap() {
}

FastTileMap::~FastTileMap() {
}

void FastTileMap::set_tile(Vector2 cellPos, int tile, int TILE_SIZE, Ref<Texture2D> texture) {
	Vector2 tilePos = cellPos * TILE_SIZE;
	
	RID tileRID = RenderingServer::get_singleton()->canvas_item_create();
	RenderingServer::get_singleton()->canvas_item_set_parent(tileRID, get_canvas_item());
	
	Rect2 src_rect(0, 64, TILE_SIZE, TILE_SIZE);
	Rect2 dst_rect(tilePos.x, tilePos.y, TILE_SIZE, TILE_SIZE);
	
	RenderingServer::get_singleton()->canvas_item_add_texture_rect_region(tileRID, dst_rect, texture->get_rid(), src_rect);
	
	tileRIDs[cellPos] = tileRID;
}

void FastTileMap::clear_tiles(Dictionary tileRIDs) {
	for (int i = 0; i < tileRIDs.size(); i++) {
		RenderingServer::get_singleton()->canvas_item_clear(tileRIDs[i]);
	}
	tileRIDs.clear();
}

void FastTileMap::set_cells_autotile(Array cellPositions, int atlas, int TILE_SIZE, Ref<Texture2D> texture) {
	for (int i = 0; i < cellPositions.size(); i++) {
		Vector2 cellPos = cellPositions[i];
		Vector2 tilePos = cellPos * TILE_SIZE;
		
		Vector2 variant = get_autotile_variant(cellPos, cellPositions);
		
		RID tileRID = RenderingServer::get_singleton()->canvas_item_create();
		RenderingServer::get_singleton()->canvas_item_set_parent(tileRID, get_canvas_item());
		
		Rect2 src_rect(variant.x * TILE_SIZE, (atlas * TILE_SIZE * ATLAS_SIZE) + variant.y * TILE_SIZE, TILE_SIZE, TILE_SIZE);
		Rect2 dst_rect(tilePos.x, tilePos.y, TILE_SIZE, TILE_SIZE);
		
		RenderingServer::get_singleton()->canvas_item_add_texture_rect_region(tileRID, dst_rect, texture->get_rid(), src_rect);
		
		tileRIDs[cellPos] = tileRID;
	}
}

Vector2 FastTileMap::get_autotile_variant(Vector2 cellPos, Array cellPositions) {
	static thread_local std::unordered_set<Vector2> position_set;
    position_set.clear();
    position_set.reserve(cellPositions.size());
	
	for (int j = 0; j < cellPositions.size(); j++) {
        position_set.insert(cellPositions[j]);
    }
	
	const Vector2 neighbors[8] = {
        cellPos + Vector2(-1, -1),
        cellPos + Vector2(0, -1),
        cellPos + Vector2(1, -1),
        cellPos + Vector2(-1, 0),
        cellPos + Vector2(1, 0),
        cellPos + Vector2(-1, 1),
        cellPos + Vector2(0, 1),
        cellPos + Vector2(1, 1)
    };
	
	bool hasTop = position_set.count(neighbors[1]);
    bool hasLeft = position_set.count(neighbors[3]);
    bool hasRight = position_set.count(neighbors[4]);
    bool hasBottom = position_set.count(neighbors[6]);
	
	int bitmask = 0;
	
	if (hasTop) bitmask |= 2;
	if (hasLeft) bitmask |= 8;
	if (hasRight) bitmask |= 16;
	if (hasBottom) bitmask |= 64;
	
	if (hasTop && hasLeft && position_set.count(neighbors[0])) bitmask |= 1;
    if (hasTop && hasRight && position_set.count(neighbors[2])) bitmask |= 4;
    if (hasBottom && hasLeft && position_set.count(neighbors[5])) bitmask |= 32;
    if (hasBottom && hasRight && position_set.count(neighbors[7])) bitmask |= 128;
	
	if (auto it = autotile_variant_map.find(bitmask); it != autotile_variant_map.end()) {
        return it->second;
    }
    return Vector2(0, 0);
}
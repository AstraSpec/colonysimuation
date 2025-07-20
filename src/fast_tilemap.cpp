#include "fast_tilemap.h"

using namespace godot;

void FastTileMap::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_tile", "cellPos", "tile", "TILE_SIZE", "texture"), &FastTileMap::set_tile);
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
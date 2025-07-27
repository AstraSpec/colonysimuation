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
	ClassDB::bind_method(D_METHOD("set_cell", "cellPos", "atlas", "texture", "z_index", "offset", "size"), &FastTileMap::set_cell, DEFVAL(Vector2(0, 0)), DEFVAL(Vector2(1, 1)));
	ClassDB::bind_method(D_METHOD("set_cells", "cellPositions", "config"), &FastTileMap::set_cells);
	ClassDB::bind_method(D_METHOD("clear_cells"), &FastTileMap::clear_cells);
	ClassDB::bind_method(D_METHOD("set_cells_autotile", "cellPositions", "config", "totalPos"), &FastTileMap::set_cells_autotile);
}

FastTileMap::FastTileMap() {
}

FastTileMap::~FastTileMap() {
}

void FastTileMap::set_cell(Vector2 cellPos, Vector2 atlas, Ref<Texture2D> texture, int z_index, Vector2 offset, Vector2 size) {
	Vector2 tilePos = cellPos * TILE_SIZE;

	RID tileRID = RenderingServer::get_singleton()->canvas_item_create();
	RenderingServer::get_singleton()->canvas_item_set_parent(tileRID, get_canvas_item());

	Rect2 src_rect(atlas.x * TILE_SIZE, atlas.y * TILE_SIZE, size.x * TILE_SIZE, size.y * TILE_SIZE);
	Rect2 dst_rect(tilePos.x + offset.x * TILE_SIZE, tilePos.y + offset.y * TILE_SIZE, size.x * TILE_SIZE, size.y * TILE_SIZE);

	RenderingServer::get_singleton()->canvas_item_add_texture_rect_region(tileRID, dst_rect, texture->get_rid(), src_rect);
	RenderingServer::get_singleton()->canvas_item_set_z_index(tileRID, cellPos.y + offset.y + z_index);

	tileRIDs[cellPos] = tileRID;
}

void FastTileMap::set_cells(Array cellPositions, Dictionary config) {
	Vector2 atlas = config["atlas"];
	Ref<Texture2D> texture = config["texture"];
	int z_index = config["z_index"];
	Vector2 offset = config["offset"];
	Vector2 size = config["size"];
	
	for (int i = 0; i < cellPositions.size(); i++) {
		Vector2 cellPos = cellPositions[i];
		set_cell(cellPos, atlas, texture, z_index, offset, size);
	}
}

void FastTileMap::clear_cells() {
    Array keys = tileRIDs.keys();
    for (int i = 0; i < keys.size(); i++) {
		RID rid = tileRIDs[keys[i]];
        RenderingServer::get_singleton()->canvas_item_clear(rid);
	}
    tileRIDs.clear();
}

void FastTileMap::set_cells_autotile(Array cellPositions, Dictionary config, Array totalPos) {
    Vector2 atlas = config["atlas"];
    Ref<Texture2D> texture = config["texture"];
    int z_index = config["z_index"];
    Vector2 offset = config["offset"];
    Vector2 size = config["size"];
    
    std::unordered_set<Vector2> position_set;
    position_set.reserve(totalPos.size());
    for (int i = 0; i < totalPos.size(); i++) {
        position_set.insert(totalPos[i]);
    }

    for (int i = 0; i < cellPositions.size(); i++) {
        Vector2 cellPos = cellPositions[i];
        Vector2 variant = get_autotile_variant(cellPos, position_set) + atlas;
        set_cell(cellPos, variant, texture, z_index);
    }
}

Vector2 FastTileMap::get_autotile_variant(Vector2 cellPos, const std::unordered_set<Vector2>& position_set) {
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
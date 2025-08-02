#include "fast_tilemap.h"
#include <algorithm>

using namespace godot;

const std::unordered_map<int, Vector2i> FastTileMap::autotile_variant_map = {
	{0, Vector2i(0, 0)},
	{2, Vector2i(0, 3)},
	{8, Vector2i(3, 0)},
	{10, Vector2i(10, 2)},
	{11, Vector2i(3, 3)},
	{16, Vector2i(1, 0)},
	{18, Vector2i(8, 2)},
	{22, Vector2i(1, 3)},
	{24, Vector2i(2, 0)},
	{26, Vector2i(9, 2)},
	{27, Vector2i(6, 3)},
	{30, Vector2i(5, 3)},
	{31, Vector2i(2, 3)},
	{64, Vector2i(0, 1)},
	{66, Vector2i(0, 2)},
	{72, Vector2i(10, 0)},
	{74, Vector2i(10, 1)},
	{75, Vector2i(7, 2)},
	{80, Vector2i(8, 0)},
	{82, Vector2i(8, 1)},
	{86, Vector2i(4, 2)},
	{88, Vector2i(9, 0)},
	{90, Vector2i(9, 1)},
	{91, Vector2i(4, 0)},
	{94, Vector2i(7, 0)},
	{95, Vector2i(12, 2)},
	{104, Vector2i(3, 1)},
	{106, Vector2i(7, 1)},
	{107, Vector2i(3, 2)},
	{120, Vector2i(6, 0)},
	{122, Vector2i(4, 3)},
	{123, Vector2i(11, 1)},
	{126, Vector2i(11, 0)},
	{127, Vector2i(6, 2)},
	{208, Vector2i(1, 1)},
	{210, Vector2i(4, 1)},
	{214, Vector2i(1, 2)},
	{216, Vector2i(5, 0)},
	{218, Vector2i(7, 3)},
	{219, Vector2i(12, 0)},
	{222, Vector2i(12, 1)},
	{223, Vector2i(5, 2)},
	{248, Vector2i(2, 1)},
	{250, Vector2i(11, 2)},
	{251, Vector2i(6, 1)},
	{254, Vector2i(5, 1)},
	{255, Vector2i(2, 2)}
};

void FastTileMap::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_cells", "cellPositions", "tileData"), &FastTileMap::set_cells);
	ClassDB::bind_method(D_METHOD("set_cells_autotile", "cellPositions", "tileData", "totalPos"), &FastTileMap::set_cells_autotile);
	ClassDB::bind_method(D_METHOD("flush_batches"), &FastTileMap::flush_batches);
	ClassDB::bind_method(D_METHOD("clear_all"), &FastTileMap::clear_all);
}

FastTileMap::FastTileMap() {
	canvas_item = RenderingServer::get_singleton()->canvas_item_create();
	RenderingServer::get_singleton()->canvas_item_set_parent(canvas_item, get_canvas_item());
}

FastTileMap::~FastTileMap() {
	if (canvas_item.is_valid()) {
		RenderingServer::get_singleton()->free_rid(canvas_item);
	}
}

// TODO:
// Bring back set_cell and clear_cell with improvements

void FastTileMap::set_cells(Array cellPositions, Object* tileData) {
	Vector2i atlas = tileData->get("atlas");
	Ref<Texture2D> texture = tileData->get("texture");
	int z_index = tileData->get("z_index");
	Vector2i offset = tileData->get("offset");
	Vector2i size = tileData->get("size");
	
	auto& texture_batch = texture_batches[texture];
	
	for (int i = 0; i < cellPositions.size(); i++) {
		Vector2i cellPos = cellPositions[i];
		Vector2i tilePos = cellPos * TILE_SIZE;
		
		Rect2 src_rect(atlas.x * TILE_SIZE, atlas.y * TILE_SIZE, size.x * TILE_SIZE, size.y * TILE_SIZE);
		Rect2 dst_rect(tilePos.x + offset.x * TILE_SIZE, tilePos.y + offset.y * TILE_SIZE, size.x * TILE_SIZE, size.y * TILE_SIZE);
		
		texture_batch[z_index].emplace_back(src_rect, dst_rect);
	}
}

void FastTileMap::set_cells_autotile(Array cellPositions, Object* tileData, Array totalPos) {
    Vector2i atlas = tileData->get("atlas");
    Ref<Texture2D> texture = tileData->get("texture");
    int z_index = tileData->get("z_index");
    Vector2i offset = tileData->get("offset");
    Vector2i size = tileData->get("size");
    
    std::unordered_set<Vector2i> position_set;
    position_set.reserve(totalPos.size());
    for (int i = 0; i < totalPos.size(); i++) {
        position_set.insert(totalPos[i]);
    }

    std::unordered_map<Vector2i, Vector2i> variant_cache;
    variant_cache.reserve(cellPositions.size());

    auto& texture_batch = texture_batches[texture];
    
    for (int i = 0; i < cellPositions.size(); i++) {
        Vector2i cellPos = cellPositions[i];
        
        Vector2i variant;
        auto cache_it = variant_cache.find(cellPos);
        if (cache_it != variant_cache.end()) {
            variant = cache_it->second;
        } else {
            variant = get_autotile_variant(cellPos, position_set) + atlas;
            variant_cache[cellPos] = variant;
        }
        
        Vector2i tilePos = cellPos * TILE_SIZE;
        
        Rect2 src_rect(variant.x * TILE_SIZE, variant.y * TILE_SIZE, size.x * TILE_SIZE, size.y * TILE_SIZE);
        Rect2 dst_rect(tilePos.x + offset.x * TILE_SIZE, tilePos.y + offset.y * TILE_SIZE, size.x * TILE_SIZE, size.y * TILE_SIZE);
        
        		texture_batch[z_index].emplace_back(src_rect, dst_rect);
	}
}

void FastTileMap::flush_batches() {
	RenderingServer::get_singleton()->canvas_item_clear(canvas_item);
	
	for (auto& [texture, z_batches] : texture_batches) {
		std::vector<std::pair<Rect2, Rect2>> all_tiles;
		
		for (auto& [z_index, tiles] : z_batches) {
			all_tiles.insert(all_tiles.end(), tiles.begin(), tiles.end());
		}
		
		if (!all_tiles.empty()) {
			for (auto& [src_rect, dst_rect] : all_tiles) {
				RenderingServer::get_singleton()->canvas_item_add_texture_rect_region(canvas_item, dst_rect, texture->get_rid(), src_rect);
			}
		}
	}
	
	texture_batches.clear();
}

void FastTileMap::clear_all() {
	texture_batches.clear();
	RenderingServer::get_singleton()->canvas_item_clear(canvas_item);
}

Vector2i FastTileMap::get_autotile_variant(Vector2i cellPos, const std::unordered_set<Vector2i>& position_set) {
    const Vector2i neighbors[8] = {
        cellPos + Vector2i(-1, -1),
        cellPos + Vector2i(0, -1),
        cellPos + Vector2i(1, -1),
        cellPos + Vector2i(-1, 0),
        cellPos + Vector2i(1, 0),
        cellPos + Vector2i(-1, 1),
        cellPos + Vector2i(0, 1),
        cellPos + Vector2i(1, 1)
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
    return Vector2i(0, 0);
}
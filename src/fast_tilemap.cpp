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
	ClassDB::bind_method(D_METHOD("set_cell", "cellPos", "tileData", "redraw_tiles"), &FastTileMap::set_cell, DEFVAL(true));
	ClassDB::bind_method(D_METHOD("set_cells", "cellPositions", "tileData", "redraw_tiles"), &FastTileMap::set_cells, DEFVAL(true));
	ClassDB::bind_method(D_METHOD("set_cells_autotile", "cellPositions", "tileData", "totalPos", "redraw_tiles"), &FastTileMap::set_cells_autotile, DEFVAL(true));
	ClassDB::bind_method(D_METHOD("clear_cell", "cellPos", "layer", "redraw_tiles"), &FastTileMap::clear_cell, DEFVAL(true));
	ClassDB::bind_method(D_METHOD("clear_all"), &FastTileMap::clear_all);
	ClassDB::bind_method(D_METHOD("redraw_tiles"), &FastTileMap::redraw_tiles);
	ClassDB::bind_method(D_METHOD("update_area", "cellPos", "layer", "radius"), &FastTileMap::update_area, DEFVAL(1));
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

void FastTileMap::set_cell(Vector2i cellPos, Object* tileData, bool redraw) {
	int layer = tileData->get("z_index");
	add_map_tile(cellPos, layer, tileData);
	
	update_area(cellPos, layer, 1);
	
	if (redraw) {
		redraw_tiles();
	}
}

void FastTileMap::set_cells(Array cellPositions, Object* tileData, bool redraw) {
    for (int i = 0; i < cellPositions.size(); i++) {
        Vector2i cellPos = cellPositions[i];
        int layer = tileData->get("z_index");
        add_map_tile(cellPos, layer, tileData);
    }
    
    if (redraw) {
        redraw_tiles();
    }
}

Vector2i FastTileMap::resolve_atlas(Vector2i cellPos, Object* tileData) {
    Variant atlas_data = tileData->get("atlas");
    
    if (atlas_data.get_type() == Variant::ARRAY) {
        Array variants = atlas_data;
        int variant_count = variants.size();
        
        uint32_t hash = (cellPos.x * 73856093) ^ (cellPos.y * 19349663);
        hash = hash ^ (hash >> 16);
        hash = hash * 2654435761U;
        int variant_index = hash % variant_count;
        
        return variants[variant_index];
    } else {
        return atlas_data;
    }
}

void FastTileMap::render_tile(Vector2i cellPos, Vector2i atlas, Vector2i offset, Vector2i size, Ref<Texture2D> texture) {
    Vector2i tilePos = cellPos * TILE_SIZE;
    Rect2 src_rect(atlas.x * TILE_SIZE, atlas.y * TILE_SIZE, size.x * TILE_SIZE, size.y * TILE_SIZE);
    Rect2 dst_rect(tilePos.x + offset.x * TILE_SIZE, tilePos.y + offset.y * TILE_SIZE, size.x * TILE_SIZE, size.y * TILE_SIZE);
    
    RenderingServer::get_singleton()->canvas_item_add_texture_rect_region(canvas_item, dst_rect, texture->get_rid(), src_rect);
}

void FastTileMap::set_cells_autotile(Array cellPositions, Object* tileData, Array totalPos, bool redraw) {
    Vector2i atlas = tileData->get("atlas");
    int layer = tileData->get("z_index");
    
    std::unordered_set<Vector2i> position_set;
    position_set.reserve(totalPos.size());
    for (int i = 0; i < totalPos.size(); i++) {
        position_set.insert(totalPos[i]);
    }

    std::unordered_map<Vector2i, Vector2i> variant_cache;
    variant_cache.reserve(cellPositions.size());

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
        
        add_map_tile(cellPos, layer, tileData, variant);
	}
	
	if (redraw) {
	    redraw_tiles();
	}
}

void FastTileMap::clear_all() {
	RenderingServer::get_singleton()->canvas_item_clear(canvas_item);
	mapTiles.clear();
}

void FastTileMap::add_map_tile(Vector2i cellPos, int layer, Object* tileData, Vector2i variant) {
	for (auto it = mapTiles.begin(); it != mapTiles.end(); ++it) {
		if (it->cellPos == cellPos && it->layer == layer) {
			mapTiles.erase(it);
			break;
		}
	}
	
	mapTiles.emplace_back(cellPos, layer, tileData, variant);
}

void FastTileMap::redraw_tiles() {
	RenderingServer::get_singleton()->canvas_item_clear(canvas_item);
	
	for (const auto& tile : mapTiles) {
		Ref<Texture2D> texture = tile.tileData->get("texture");
		int layer = tile.tileData->get("z_index");
		Vector2i offset = tile.tileData->get("offset");
		Vector2i size = tile.tileData->get("size");
		
		Vector2i atlas;
		if (tile.variant != Vector2i(0, 0)) {
			atlas = tile.variant;
		} else {
			atlas = resolve_atlas(tile.cellPos, tile.tileData);
		}
		
		render_tile(tile.cellPos, atlas, offset, size, texture);
	}
}

void FastTileMap::clear_cell(Vector2i cellPos, int layer, bool redraw) {
	for (auto it = mapTiles.begin(); it != mapTiles.end(); ++it) {
		if (it->cellPos == cellPos && it->layer == layer) {
			mapTiles.erase(it);
			break;
		}
	}
	
	update_area(cellPos, layer, 1);
	
	if (redraw) {
	    redraw_tiles();
	}
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

// Recalculates autotiling in area
void FastTileMap::update_area(Vector2i cellPos, int layer, int radius) {
    // 1. Find tiles in area
    std::vector<size_t> indices_in_area;
    indices_in_area.reserve(mapTiles.size());
    for (size_t i = 0; i < mapTiles.size(); ++i) {
        const auto &t = mapTiles[i];
        if (t.layer != layer) continue;
        if (Math::abs(t.cellPos.x - cellPos.x) <= radius && 
            Math::abs(t.cellPos.y - cellPos.y) <= radius) {
            indices_in_area.push_back(i);
        }
    }
    
    // 2. Group by tileData to avoid redundant work
    std::unordered_map<Object*, std::vector<size_t>> tiles_by_type;
    for (size_t idx : indices_in_area) {
        Object* tileData = mapTiles[idx].tileData;
        
        // Check autotile flag once per tile type
        if (tiles_by_type.find(tileData) == tiles_by_type.end()) {
            Array flags = tileData->get("flags");
            bool is_autotile = false;
            for (int i = 0; i < flags.size(); i++) {
                if (String(flags[i]) == "AUTOTILE") {
                    is_autotile = true;
                    break;
                }
            }
            if (!is_autotile) continue;
        }
        
        tiles_by_type[tileData].push_back(idx);
    }
    
    // 3. Process each tile type once
    for (const auto& [tileData, tile_indices] : tiles_by_type) {
        Vector2i atlas_base = tileData->get("atlas");
        
        // Build position set once per tile type
        std::unordered_set<Vector2i> position_set;
        for (const auto &t : mapTiles) {
            if (t.layer == layer && t.tileData == tileData) {
                position_set.insert(t.cellPos);
            }
        }
        
        // Update variants for this tile type
        for (size_t idx : tile_indices) {
            auto &tref = mapTiles[idx];
            Vector2i v = get_autotile_variant(tref.cellPos, position_set) + atlas_base;
            tref.variant = v;
        }
    }
}

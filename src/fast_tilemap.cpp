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
	ClassDB::bind_method(D_METHOD("redraw_tiles", "mapData"), &FastTileMap::redraw_tiles);
    ClassDB::bind_method(D_METHOD("update_y_canvas_item", "y_level", "mapData"), &FastTileMap::update_y_canvas_item);
    ClassDB::bind_method(D_METHOD("add_autotile_position", "cellPos", "tileData"), &FastTileMap::add_autotile_position);
    ClassDB::bind_method(D_METHOD("clear_autotile_position", "cellPos", "layer"), &FastTileMap::clear_autotile_position);
    ClassDB::bind_method(D_METHOD("add_work_canvas_item", "cellPos", "texture"), &FastTileMap::add_work_canvas_item);
    ClassDB::bind_method(D_METHOD("remove_work_canvas_item", "cellPos"), &FastTileMap::remove_work_canvas_item);
    ClassDB::bind_method(D_METHOD("clear_all_work_canvas_items"), &FastTileMap::clear_all_work_canvas_items);
}

FastTileMap::FastTileMap() {
    for (int y = 0; y < Constants::WORLD_SIZE; y++) {
        RID rid = RenderingServer::get_singleton()->canvas_item_create();
        RenderingServer::get_singleton()->canvas_item_set_parent(rid, get_canvas_item());
        RenderingServer::get_singleton()->canvas_item_set_z_index(rid, y);
        y_level_canvas_items.emplace(y, rid);
    }
}

FastTileMap::~FastTileMap() {
    for (auto &entry : y_level_canvas_items) {
        if (entry.second.is_valid()) {
            RenderingServer::get_singleton()->free_rid(entry.second);
        }
    }
    y_level_canvas_items.clear();
    
    clear_all_work_canvas_items();
}

void FastTileMap::redraw_tiles(Dictionary mapData) {
    // Clear all canvas items first
    for (auto &entry : y_level_canvas_items) {
        RenderingServer::get_singleton()->canvas_item_clear(entry.second);
    }
    
    // Build autotile positions once
    set_autotile_positions(mapData);
    
    // Update each y-level canvas item
    for (auto &entry : y_level_canvas_items) {
        update_y_canvas_item(entry.first, mapData);
    }
}

void FastTileMap::update_y_canvas_item(int y_level, Dictionary mapData) {
    // Get the canvas item for this y-level
    auto it = y_level_canvas_items.find(y_level);
    if (it == y_level_canvas_items.end()) return;
    
    RID target = it->second;
    RenderingServer::get_singleton()->canvas_item_clear(target);

    // Iterate only cells at this y_level
    for (int x = 0; x < Constants::WORLD_SIZE; x++) {
        Vector2i cellPos(x, y_level);
        
        // Check if cell exists in mapData
        if (!mapData.has(cellPos)) continue;
        
        Object* cellData = mapData[cellPos];
        Array tiles = cellData->get("tiles");
        
        // Iterate through each layer in the cell
        for (int j = 1; j < tiles.size(); j++) {
            Object* tileData = tiles[j];

            if (!tileData) continue;
            
            Ref<Texture2D> texture = tileData->get("texture");
            int layer = tileData->get("layer");
            Vector2i offset = tileData->get("offset");
            Vector2i size = tileData->get("size");
            
            Vector2i atlas = resolve_atlas(cellPos, tileData);
            uint32_t flags = tileData->get("flags");
            if (flags & Constants::AUTOTILE_FLAG) {
                atlas = get_autotile_variant(cellPos, layer) + atlas;
            }
            
            render_tile(target, cellPos, atlas, offset, size, texture);
        }
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
    }
    else {
        return atlas_data;
    }
}

void FastTileMap::render_tile(RID target_canvas, Vector2i cellPos, Vector2i atlas, Vector2i offset, Vector2i size, Ref<Texture2D> texture) {
    Vector2i tilePos = cellPos * TILE_SIZE;
    Rect2 src_rect(atlas.x * TILE_SIZE, atlas.y * TILE_SIZE, size.x * TILE_SIZE, size.y * TILE_SIZE);
    Rect2 dst_rect(tilePos.x + offset.x * TILE_SIZE, tilePos.y + offset.y * TILE_SIZE, size.x * TILE_SIZE, size.y * TILE_SIZE);

    RenderingServer::get_singleton()->canvas_item_add_texture_rect_region(target_canvas, dst_rect, texture->get_rid(), src_rect);
}

void FastTileMap::set_autotile_positions(Dictionary mapData) {
    // Clear existing layered autotile positions
    autotile_positions.clear();
    
    // Build position set of all AUTOTILE tiles for autotile variant calculation, organized by layer
    Array keys = mapData.keys();
    for (int i = 0; i < keys.size(); i++) {
        Vector2i cellPos = keys[i];
        Object* cellData = mapData[cellPos];
        Array tiles = cellData->get("tiles");
        
        for (int j = 1; j < tiles.size(); j++) {
            Object* tileData = tiles[j];
            if (tileData) {
                uint32_t flags = tileData->get("flags");
                if (flags & Constants::AUTOTILE_FLAG) {
                    autotile_positions[j].insert(cellPos);
                }
            }
        }
    }
}

bool FastTileMap::add_autotile_position(Vector2i cellPos, Object* tileData) {
    uint32_t flags = tileData->get("flags");
    if (flags & Constants::AUTOTILE_FLAG) {
        int layer = tileData->get("layer");
        autotile_positions[layer].insert(cellPos);
        return true;
    }
    return false;
}

bool FastTileMap::clear_autotile_position(Vector2i cellPos, int layer) {
    auto it = autotile_positions.find(layer);
    if (it != autotile_positions.end() && it->second.erase(cellPos) > 0) {
        return true;
    }
    return false;
}

Vector2i FastTileMap::get_autotile_variant(Vector2i cellPos, int layer) {
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

    // Check if neighbors have autotiles in the same layer
    auto it = autotile_positions.find(layer);
    if (it == autotile_positions.end()) {
        return Vector2i(0, 0);
    }
    
    const auto& layer_positions = it->second;
    
    bool hasTop = layer_positions.count(neighbors[1]);
    bool hasLeft = layer_positions.count(neighbors[3]);
    bool hasRight = layer_positions.count(neighbors[4]);
    bool hasBottom = layer_positions.count(neighbors[6]);

    int bitmask = 0;

    if (hasTop) bitmask |= 2;
    if (hasLeft) bitmask |= 8;
    if (hasRight) bitmask |= 16;
    if (hasBottom) bitmask |= 64;

    if (hasTop && hasLeft && layer_positions.count(neighbors[0])) bitmask |= 1;
    if (hasTop && hasRight && layer_positions.count(neighbors[2])) bitmask |= 4;
    if (hasBottom && hasLeft && layer_positions.count(neighbors[5])) bitmask |= 32;
    if (hasBottom && hasRight && layer_positions.count(neighbors[7])) bitmask |= 128;

    if (auto it = autotile_variant_map.find(bitmask); it != autotile_variant_map.end()) {
        return it->second;
    }
    return Vector2i(0, 0);
}

void FastTileMap::add_work_canvas_item(Vector2i cellPos, Ref<Texture2D> texture) {
    // Check if work canvas item already exists for this cell
    if (work_canvas_items.find(cellPos) != work_canvas_items.end()) {
        return;
    }
    
    RID canvas_item = RenderingServer::get_singleton()->canvas_item_create();
    RID parent_canvas = get_canvas();
    RenderingServer::get_singleton()->canvas_item_set_parent(canvas_item, parent_canvas);
    
    // Set position
    Vector2 world_pos = Vector2(cellPos * TILE_SIZE);
    RenderingServer::get_singleton()->canvas_item_set_transform(canvas_item, Transform2D(0, world_pos));
    RenderingServer::get_singleton()->canvas_item_set_z_index(canvas_item, Constants::WORLD_SIZE + 1);
    
    // Load icons texture
    if (texture.is_valid()) {
        Rect2 src_rect = Rect2(0, 0, TILE_SIZE, TILE_SIZE);
        Rect2 dest_rect = Rect2(0, 0, TILE_SIZE, TILE_SIZE);
        RenderingServer::get_singleton()->canvas_item_add_texture_rect_region(canvas_item, dest_rect, texture->get_rid(), src_rect);
    }
    
    work_canvas_items[cellPos] = canvas_item;
}

void FastTileMap::remove_work_canvas_item(Vector2i cellPos) {
    auto it = work_canvas_items.find(cellPos);
    if (it != work_canvas_items.end()) {
        RenderingServer::get_singleton()->free_rid(it->second);
        work_canvas_items.erase(it);
    }
}

void FastTileMap::clear_all_work_canvas_items() {
    for (auto& pair : work_canvas_items) {
        RenderingServer::get_singleton()->free_rid(pair.second);
    }
    work_canvas_items.clear();
}
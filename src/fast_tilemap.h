#ifndef COLONYSIM_FAST_TILEMAP_H
#define COLONYSIM_FAST_TILEMAP_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include "constants.h"
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace std {
    template<>
    struct hash<godot::Vector2i> {
        size_t operator()(const godot::Vector2i& v) const {
            size_t h1 = hash<int>{}(v.x);
            size_t h2 = hash<int>{}(v.y);
            return h1 ^ (h2 << 1);
        }
    };
}

namespace godot {

class FastTileMap: public Node2D{
    GDCLASS(FastTileMap, Node2D)

protected:
	static void _bind_methods();
    
    private:
    static constexpr int TILE_SIZE = Constants::TILE_SIZE;
    static const std::unordered_map<int, Vector2i> autotile_variant_map;
    
    std::unordered_map<int, RID> y_level_canvas_items;
    std::unordered_map<Vector2i, RID> work_canvas_items;
    std::unordered_map<Vector2i, RID> item_canvas_items;

    std::unordered_map<int, std::unordered_set<Vector2i>> autotile_positions;
    void set_autotile_positions(Dictionary mapData);

    static Vector2i resolve_atlas(Vector2i cellPos, Object* tileData);
    void render_tile(RID target_canvas, Vector2i cellPos, Vector2i atlas, Vector2i offset, Vector2i size, Ref<Texture2D> texture);

public:
    FastTileMap();
    ~FastTileMap();

    void redraw_tiles(Dictionary mapData);

    bool add_autotile_position(Vector2i cellPos, Object* tileData);
    bool clear_autotile_position(Vector2i cellPos, int layer);
    Vector2i get_autotile_variant(Vector2i cellPos, int layer);

    void update_y_canvas_item(int y_level, Dictionary mapData);
    
    void add_work_canvas_item(Vector2i cellPos, Ref<Texture2D> texture, Vector2i atlas);
    void remove_work_canvas_item(Vector2i cellPos);
    void clear_all_work_canvas_items();
    
    void add_item_canvas_item(Vector2i cellPos, Ref<Texture2D> texture, Vector2i atlas);
    void remove_item_canvas_item(Vector2i cellPos);
    void clear_all_item_canvas_items();
};

}

#endif // ! COLONYSIM_FAST_TILEMAP_H
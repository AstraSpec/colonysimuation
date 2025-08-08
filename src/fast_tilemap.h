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
    
    RID canvas_item;

    static Vector2i resolve_atlas(Vector2i cellPos, Object* tileData);
    void render_tile(Vector2i cellPos, Vector2i atlas, Vector2i offset, Vector2i size, Ref<Texture2D> texture);

public:
    FastTileMap();
    ~FastTileMap();

    void set_cells(Array cellPositions, Object* tileData);
    void set_cells_autotile(Array cellPositions, Object* tileData, Array totalPos);
    Vector2i get_autotile_variant(Vector2i cellPos, const std::unordered_set<Vector2i>& position_set);
    
    void clear_all();

};

}

#endif // ! COLONYSIM_FAST_TILEMAP_H
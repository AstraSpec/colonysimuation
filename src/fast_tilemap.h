#ifndef COLONYSIM_FAST_TILEMAP_H
#define COLONYSIM_FAST_TILEMAP_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <unordered_map>
#include <unordered_set>

namespace std {
    template<>
    struct hash<godot::Vector2> {
        size_t operator()(const godot::Vector2& v) const {
            size_t h1 = hash<float>{}(v.x);
            size_t h2 = hash<float>{}(v.y);
            return h1 ^ (h2 << 1);
        }
    };
}

namespace godot {

class FastTileMap: public Node2D{
    GDCLASS(FastTileMap, Node2D)

protected:
	static void _bind_methods();
	Dictionary tileRIDs;

private:
    int ATLAS_SIZE = 4;
    static const std::unordered_map<int, Vector2> autotile_variant_map;

public:
    FastTileMap();
    ~FastTileMap();

    void set_tile(Vector2 cellPos, int tile, int TILE_SIZE, Ref<Texture2D> texture);
    void clear_tiles(Dictionary tileRIDs);
    void set_cells_autotile(Array cellPositions, int atlas, int TILE_SIZE, Ref<Texture2D> texture);
    Vector2 get_autotile_variant(Vector2 cellPos, Array cellPositions);
};

}

#endif // ! COLONYSIM_FAST_TILEMAP_H
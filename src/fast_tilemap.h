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
    
    private:
    static constexpr int TILE_SIZE = 16;
    static constexpr int ATLAS_SIZE = 4;
    static const std::unordered_map<int, Vector2> autotile_variant_map;
    Dictionary tileRIDs;

public:
    FastTileMap();
    ~FastTileMap();

    void set_cell(Vector2 cellPos, Vector2 atlas, Ref<Texture2D> texture, int z_index, const Vector2 offset = Vector2(0, 0), const Vector2 size = Vector2(1, 1));
    void set_cells(Array cellPositions, Dictionary config);
    void clear_cells();
    void set_cells_autotile(Array cellPositions, Dictionary config, Array totalPos);
    void set_terrain_cells(Array cellPositions, Dictionary config);
    Vector2 get_autotile_variant(Vector2 cellPos, const std::unordered_set<Vector2>& position_set);
};

}

#endif // ! COLONYSIM_FAST_TILEMAP_H
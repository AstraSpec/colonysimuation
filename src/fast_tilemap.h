#ifndef COLONYSIM_FAST_TILEMAP_H
#define COLONYSIM_FAST_TILEMAP_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/classes/object.hpp>
#include <unordered_map>
#include <unordered_set>

namespace std {
    template<>
    struct hash<godot::Vector2i> {
        size_t operator()(const godot::Vector2i& v) const {
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
    static const std::unordered_map<int, Vector2i> autotile_variant_map;
    Dictionary tileRIDs;

public:
    FastTileMap();
    ~FastTileMap();

    void set_cell(Vector2i cellPos, Vector2i atlas, Ref<Texture2D> texture, int z_index, const Vector2i offset = Vector2i(0, 0), const Vector2i size = Vector2i(1, 1));
    void set_cells(Array cellPositions, Object* tileData);
    void clear_cells();
    void set_cells_autotile(Array cellPositions, Object* tileData, Array totalPos);
    void set_terrain_cells(Array cellPositions, Object* tileData);
    Vector2i get_autotile_variant(Vector2i cellPos, const std::unordered_set<Vector2i>& position_set);
};

}

#endif // ! COLONYSIM_FAST_TILEMAP_H
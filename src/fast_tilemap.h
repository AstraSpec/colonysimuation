#ifndef COLONYSIM_FAST_TILEMAP_H
#define COLONYSIM_FAST_TILEMAP_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

class FastTileMap: public Node2D{
    GDCLASS(FastTileMap, Node2D)

protected:
	static void _bind_methods();
	Dictionary tileRIDs;

public:
    FastTileMap();
    ~FastTileMap();

    void set_tile(Vector2 cellPos, int tile, int TILE_SIZE, Ref<Texture2D> texture);
};

}

#endif // ! COLONYSIM_FAST_TILEMAP_H
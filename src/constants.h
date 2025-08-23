#ifndef COLONYSIM_CONSTANTS_H
#define COLONYSIM_CONSTANTS_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class Constants : public Object {
    GDCLASS(Constants, Object)

protected:
    static void _bind_methods();

public:
    Constants();
    ~Constants();

    static const int WORLD_SIZE = 256;
    static const int TILE_SIZE = 16;
    static const int CHUNK_SIZE = 16;
    
    static const uint32_t AUTOTILE_FLAG = 1 << 0;
    static const uint32_t WORLDSPAWN_FLAG = 1 << 1;
    
    static int get_world_size();
    static int get_tile_size();
    static int get_chunk_size();
    static Array get_tile_layers();
    static uint32_t flags_to_bits(Array flags);
    
};

}

#endif // COLONYSIM_CONSTANTS_H 
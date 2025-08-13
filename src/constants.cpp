#include "constants.h"

using namespace godot;

void Constants::_bind_methods() {
    ClassDB::bind_static_method("Constants", D_METHOD("get_world_size"), &Constants::get_world_size);
    ClassDB::bind_static_method("Constants", D_METHOD("get_tile_size"), &Constants::get_tile_size);
    ClassDB::bind_static_method("Constants", D_METHOD("get_chunk_size"), &Constants::get_chunk_size);
    ClassDB::bind_static_method("Constants", D_METHOD("flags_to_bits", "flags"), &Constants::flags_to_bits);
}

Constants::Constants() {
}

Constants::~Constants() {
}

int Constants::get_world_size() {
    return WORLD_SIZE;
}

int Constants::get_tile_size() {
    return TILE_SIZE;
} 

int Constants::get_chunk_size() {
    return CHUNK_SIZE;
}

uint32_t Constants::flags_to_bits(Array flags) {
    uint32_t bit_flags = 0;
    
    for (int i = 0; i < flags.size(); i++) {
        String flag = flags[i];
        
        if (flag == "AUTOTILE") {
            bit_flags |= AUTOTILE_FLAG;
        } else if (flag == "WORLDSPAWN") {
            bit_flags |= WORLDSPAWN_FLAG;
        }
    }
    
    return bit_flags;
} 


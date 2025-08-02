#include "constants.h"

using namespace godot;

void Constants::_bind_methods() {
    ClassDB::bind_static_method("Constants", D_METHOD("get_world_size"), &Constants::get_world_size);
    ClassDB::bind_static_method("Constants", D_METHOD("get_tile_size"), &Constants::get_tile_size);
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
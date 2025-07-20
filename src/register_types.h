#ifndef COLONYSIM_REGISTER_TYPES_H
#define COLONYSIM_REGISTER_TYPES_H

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void initialize_fast_tilemap_module(ModuleInitializationLevel p_level);
void uninitialize_fast_tilemap_module(ModuleInitializationLevel p_level);

#endif // ! COLONYSIM_REGISTER_TYPES_H
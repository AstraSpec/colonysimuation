#ifndef COLONYSIM_CONSTANTS_H
#define COLONYSIM_CONSTANTS_H

#include <godot_cpp/classes/node2d.hpp>

namespace godot {

class Constants : public Object {
    GDCLASS(Constants, Object)

protected:
    static void _bind_methods();

public:
    Constants();
    ~Constants();

    static const int WORLD_SIZE = 250;
    static const int TILE_SIZE = 16;
    
    static int get_world_size();
    static int get_tile_size();
};

}

#endif // COLONYSIM_CONSTANTS_H 
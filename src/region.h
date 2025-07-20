#ifndef COLONYSIM_REGION_H
#define COLONYSIM_REGION_H

#include <godot_cpp/classes/node2d.hpp>

namespace godot {

class Region: public Node2D{
    GDCLASS(Region, Node2D)

protected:
	static void _bind_methods();

public:
    Region();
    ~Region();
};

}

#endif // ! COLONYSIM_REGION_H 
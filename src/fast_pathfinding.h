#ifndef COLONYSIM_FAST_PATHFINDING_H
#define COLONYSIM_FAST_PATHFINDING_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/a_star2d.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <array>
#include "constants.h"

namespace godot {

class FastPathfinding : public Node2D {
	GDCLASS(FastPathfinding, Node2D)

protected:
	static void _bind_methods();

public:
	FastPathfinding();
	~FastPathfinding();

	void update_pathfinding(const Dictionary& mapData);
	PackedVector2Array find_path(const Vector2i& start, const Vector2i& end);

private:
	static const std::array<Vector2i, 8> DIRECTIONS;
	
	Dictionary traversable_cells;
	AStar2D* astar;
	
	void set_points(const Dictionary& mapData);
	Array get_neighbour(const Vector2i& cellPos);

};

}

#endif // COLONYSIM_FAST_PATHFINDING_H

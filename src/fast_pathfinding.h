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
#include <unordered_map>
#include <unordered_set>
#include <cstdint>

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
	bool is_cell_accessible(const Vector2i& cellPos);
	bool path_goes_through_solid(const PackedVector2Array& path);
	bool is_end_reachable(const Vector2i& end);
	
	void update_tile_point(const Vector2i& cellPos, const Dictionary& mapData);

private:
	static const std::array<Vector2i, 8> DIRECTIONS;
	
    struct Vector2iHasher {
        size_t operator()(const Vector2i &v) const noexcept {
            // Combine x and y into a 64-bit then fold to size_t
            uint64_t x = static_cast<uint64_t>(static_cast<uint32_t>(v.x));
            uint64_t y = static_cast<uint64_t>(static_cast<uint32_t>(v.y));
            uint64_t mixed = (x << 32) ^ y;
            return static_cast<size_t>(mixed ^ (mixed >> 33));
        }
    };

    // Fast lookup for existing cell -> point id
    std::unordered_map<Vector2i, int, Vector2iHasher> existingCells;
    // Fast lookup for solid cells
    std::unordered_set<Vector2i, Vector2iHasher> solidCells;
	AStar2D* astar;
	
	void set_points(const Dictionary& mapData);
	Array get_neighbour(const Vector2i& cellPos);

};

}

#endif // COLONYSIM_FAST_PATHFINDING_H

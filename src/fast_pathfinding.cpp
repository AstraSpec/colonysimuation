#include "fast_pathfinding.h"
#include <godot_cpp/variant/utility_functions.hpp>
#include <limits>

using namespace godot;

const std::array<Vector2i, 8> FastPathfinding::DIRECTIONS = {
    Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
    Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
};


void FastPathfinding::_bind_methods() {
	ClassDB::bind_method(D_METHOD("update_pathfinding", "map_data"), &FastPathfinding::update_pathfinding);
	ClassDB::bind_method(D_METHOD("find_path", "start", "end"), &FastPathfinding::find_path);
}

FastPathfinding::FastPathfinding() {
	astar = memnew(AStar2D);
}

FastPathfinding::~FastPathfinding() {
	if (astar) {
		memdelete(astar);
	}
}

void FastPathfinding::update_pathfinding(const Dictionary& map_data) {
	traversable_cells.clear();
	
	int i = 0;
	Array used_cells = map_data.keys();
	
	while (used_cells.size() > 0) {
		i++;
		Vector2i cell_position = used_cells.pop_back();
		
		traversable_cells[cell_position] = i;
	}
	
	set_points(map_data);
}

void FastPathfinding::set_points(const Dictionary& map_data) {
	astar->clear();
	
	// Add all traversable cells as points
	Array keys = traversable_cells.keys();
	for (int j = 0; j < keys.size(); j++) {
		Variant key = keys[j];
		Variant value = traversable_cells[key];
		
		if (key.get_type() == Variant::VECTOR2I && value.get_type() == Variant::INT) {
			Vector2i cell_position = key;
			int point_id = value;
			float weight_scale = 1.0;
			Object* cellData = map_data[cell_position];
			if (cellData) {
				Array tiles = cellData->get("tiles");
				for (int t = 0; t < tiles.size(); t++) {
					Object* tileData = tiles[t];
					if (!tileData) continue;
					uint32_t flags = tileData->get("flags");
					if (flags & Constants::SOLID_FLAG) {
						weight_scale = std::numeric_limits<float>::infinity();
						break;
					}
				}
			}
			
			astar->add_point(point_id, cell_position, weight_scale);
		}
	}
	
	// Connect points with their neighbours
	for (int j = 0; j < keys.size(); j++) {
		Variant key = keys[j];
		Variant value = traversable_cells[key];
		
		if (key.get_type() == Variant::VECTOR2I && value.get_type() == Variant::INT) {
			Vector2i cell_position = key;
			int point_id = value;
			
			Array neighbours = get_neighbour(cell_position);
			for (int k = 0; k < neighbours.size(); k++) {
				Variant neighbour_id = neighbours[k];
				if (neighbour_id.get_type() == Variant::INT) {
					astar->connect_points(point_id, neighbour_id);
				}
			}
		}
	}
}

Array FastPathfinding::get_neighbour(const Vector2i& cell_position) {
	Array return_array;
	
	for (int i = 0; i < DIRECTIONS.size(); i++) {
		Vector2i direction = DIRECTIONS[i];
		Vector2i neighbour = cell_position + direction;
			
			if (!traversable_cells.has(neighbour)) {
				continue;
			}
			
			// Check if points are already connected
			Variant current_id_variant = traversable_cells[cell_position];
			Variant neighbour_id_variant = traversable_cells[neighbour];
			
			if (current_id_variant.get_type() == Variant::INT && 
				neighbour_id_variant.get_type() == Variant::INT) {
				
				int current_id = current_id_variant;
				int neighbour_id = neighbour_id_variant;
				
				if (!astar->are_points_connected(current_id, neighbour_id)) {
					return_array.append(neighbour_id);
				}
			}
	}
	
	return return_array;
}

PackedVector2Array FastPathfinding::find_path(const Vector2i& start, const Vector2i& end) {
	if (!traversable_cells.has(start) || !traversable_cells.has(end)) {
		return PackedVector2Array();
	}
	
	Variant start_id_variant = traversable_cells[start];
	Variant end_id_variant = traversable_cells[end];
	
	if (start_id_variant.get_type() != Variant::INT || end_id_variant.get_type() != Variant::INT) {
		return PackedVector2Array();
	}
	
	int start_id = start_id_variant;
	int end_id = end_id_variant;
	
	if (astar->has_point(start_id) && astar->has_point(end_id)) {
		return astar->get_point_path(start_id, end_id);
	} else {
		return PackedVector2Array();
	}
}

#include "fast_pathfinding.h"
#include <godot_cpp/variant/utility_functions.hpp>
#include <limits>

using namespace godot;

const std::array<Vector2i, 8> FastPathfinding::DIRECTIONS = {
    Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
    Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
};


void FastPathfinding::_bind_methods() {
	ClassDB::bind_method(D_METHOD("update_pathfinding", "mapData"), &FastPathfinding::update_pathfinding);
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

void FastPathfinding::update_pathfinding(const Dictionary& mapData) {
	traversableCells.clear();
	
	int i = 0;
	Array usedCells = mapData.keys();
	
	while (usedCells.size() > 0) {
		i++;
		Vector2i cellPos = usedCells.pop_back();
		
		traversableCells[cellPos] = i;
	}
	
	set_points(mapData);
}

void FastPathfinding::set_points(const Dictionary& mapData) {
	astar->clear();
	
	// Add all traversable cells as points
	Array keys = traversableCells.keys();
	for (int j = 0; j < keys.size(); j++) {
		Variant key = keys[j];
		Variant value = traversableCells[key];
		
		if (key.get_type() == Variant::VECTOR2I && value.get_type() == Variant::INT) {
			Vector2i cellPos = key;
			int pointID = value;
			float weightScale = 1.0;
			Object* cellData = mapData[cellPos];
			if (cellData) {
				Array tiles = cellData->get("tiles");
				for (int t = 0; t < tiles.size(); t++) {
					Object* tileData = tiles[t];
					if (!tileData) continue;
					uint32_t flags = tileData->get("flags");
					if (flags & Constants::SOLID_FLAG) {
						weightScale = std::numeric_limits<float>::infinity();
						break;
					}
				}
			}
			
			astar->add_point(pointID, cellPos, weightScale);
		}
	}
	
	// Connect points with their neighbours
	for (int j = 0; j < keys.size(); j++) {
		Variant key = keys[j];
		Variant value = traversableCells[key];
		
		if (key.get_type() == Variant::VECTOR2I && value.get_type() == Variant::INT) {
			Vector2i cellPos = key;
			int pointID = value;
			
			Array neighbours = get_neighbour(cellPos);
			for (int k = 0; k < neighbours.size(); k++) {
				Variant neighbourID = neighbours[k];
				if (neighbourID.get_type() == Variant::INT) {
					astar->connect_points(pointID, neighbourID);
				}
			}
		}
	}
}

Array FastPathfinding::get_neighbour(const Vector2i& cellPos) {
	Array returnArray;
	
	for (int i = 0; i < DIRECTIONS.size(); i++) {
		Vector2i direction = DIRECTIONS[i];
		Vector2i neighbour = cellPos + direction;
			
			if (!traversableCells.has(neighbour)) {
				continue;
			}
			
			// Check if points are already connected
			Variant currentIDvariant = traversableCells[cellPos];
			Variant neightbourIDvariant = traversableCells[neighbour];
			
			if (currentIDvariant.get_type() == Variant::INT && 
				neightbourIDvariant.get_type() == Variant::INT) {
				
				int currentID = currentIDvariant;
				int neighbourID = neightbourIDvariant;
				
				if (!astar->are_points_connected(currentID, neighbourID)) {
					returnArray.append(neighbourID);
				}
			}
	}
	
	return returnArray;
}

PackedVector2Array FastPathfinding::find_path(const Vector2i& start, const Vector2i& end) {
	if (!traversableCells.has(start) || !traversableCells.has(end)) {
		return PackedVector2Array();
	}
	
	Variant startIDvariant = traversableCells[start];
	Variant endIDvariant = traversableCells[end];
	
	if (startIDvariant.get_type() != Variant::INT || endIDvariant.get_type() != Variant::INT) {
		return PackedVector2Array();
	}
	
	int startID = startIDvariant;
	int endID = endIDvariant;
	
	if (astar->has_point(startID) && astar->has_point(endID)) {
		return astar->get_point_path(startID, endID);
	} else {
		return PackedVector2Array();
	}
}

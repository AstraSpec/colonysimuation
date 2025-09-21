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
	ClassDB::bind_method(D_METHOD("is_cell_accessible", "cellPos"), &FastPathfinding::is_cell_accessible);
	ClassDB::bind_method(D_METHOD("path_goes_through_solid", "path"), &FastPathfinding::path_goes_through_solid);
	ClassDB::bind_method(D_METHOD("update_tile_point", "cellPos", "mapData"), &FastPathfinding::update_tile_point);
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
	existingCells.clear();
	solidCells.clear();
	set_points(mapData);
}

void FastPathfinding::set_points(const Dictionary& mapData) {
	astar->clear();
	
	// Process all cells and categorize them
	Array keys = mapData.keys();
	int pointID = 0;
	
	for (int j = 0; j < keys.size(); j++) {
		Vector2i cellPos = keys[j];
		float weightScale = 1.0;
		bool hasSolidFlag = false;
		
		// Check if cell has solid flags
		Object* cellData = mapData[cellPos];
		if (cellData) {
			Array tiles = cellData->get("tiles");
			for (int t = 0; t < tiles.size(); t++) {
				Object* tileData = tiles[t];
				if (!tileData) continue;
				uint32_t flags = tileData->get("flags");
				if (flags & Constants::SOLID_FLAG) {
					weightScale = std::numeric_limits<float>::infinity();
					hasSolidFlag = true;
					break;
				}
			}
		}
		
		existingCells[cellPos] = pointID;
		if (hasSolidFlag) {
			solidCells[cellPos] = pointID;
		}
		
		// Add point to A* graph
		astar->add_point(pointID, cellPos, weightScale);
		pointID++;
	}
	
	// Connect points with their neighbours
	for (int j = 0; j < keys.size(); j++) {
		Vector2i cellPos = keys[j];
		
		if (existingCells.has(cellPos)) {
			int pointID = existingCells[cellPos];
			
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
			
			if (!existingCells.has(neighbour)) {
				continue;
			}
			
			// Check if points are already connected
			Variant currentIDvariant = existingCells[cellPos];
			Variant neightbourIDvariant = existingCells[neighbour];
			
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
	if (!existingCells.has(start) || !existingCells.has(end)) {
		return PackedVector2Array();
	}
	
	Variant startIDvariant = existingCells[start];
	Variant endIDvariant = existingCells[end];
	
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

bool FastPathfinding::is_cell_accessible(const Vector2i& cellPos) {
	if (!existingCells.has(cellPos)) {
		return false;
	}
	
	// Check all 8 surrounding cells for solid cells
	for (int i = 0; i < DIRECTIONS.size(); i++) {
		Vector2i direction = DIRECTIONS[i];
		Vector2i neighbour = cellPos + direction;
		
		if (!solidCells.has(neighbour)) {
			return true;
		}
	}
	
	return false;
}

bool FastPathfinding::path_goes_through_solid(const PackedVector2Array& path) {
	// Check each point in the path to see if it's solid
	for (int i = 0; i < path.size(); i++) {
		Vector2i cellPos = Vector2i(path[i]);
		if (solidCells.has(cellPos)) {
			return true;
		}
	}
	return false;
}

void FastPathfinding::update_tile_point(const Vector2i& cellPos, const Dictionary& mapData) {
	if (!existingCells.has(cellPos)) {
		return;
	}
	
	int pointID = existingCells[cellPos];
	float weightScale = 1.0;
	bool hasSolidFlag = false;
	
	// Check if cell has solid flags
	Object* cellData = mapData[cellPos];
	if (cellData) {
		Array tiles = cellData->get("tiles");
		for (int t = 0; t < tiles.size(); t++) {
			Object* tileData = tiles[t];
			if (!tileData) continue;
			uint32_t flags = tileData->get("flags");
			if (flags & Constants::SOLID_FLAG) {
				weightScale = std::numeric_limits<float>::infinity();
				hasSolidFlag = true;
				break;
			}
		}
	}
	
	// Update solid cells tracking
	if (hasSolidFlag) {
		solidCells[cellPos] = pointID;
	} else {
		solidCells.erase(cellPos);
	}
	
	astar->set_point_weight_scale(pointID, weightScale);
}

#include "fast_pathfinding.h"
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/time.hpp>
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
	ClassDB::bind_method(D_METHOD("is_end_reachable", "end"), &FastPathfinding::is_end_reachable);
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
					hasSolidFlag = true;
					break;
				}
			}
		}
		
		existingCells[cellPos] = pointID;
		if (hasSolidFlag) {
			solidCells.insert(cellPos);
		}
		
		// Add point to A* graph with weight based on solid flag
		float weightScale = hasSolidFlag ? std::numeric_limits<float>::infinity() : 1.0f;
		astar->add_point(pointID, cellPos, weightScale);
		pointID++;
	}
	
	// Connect points with their neighbours
	for (int j = 0; j < keys.size(); j++) {
		Vector2i cellPos = keys[j];
		
		if (existingCells.find(cellPos) != existingCells.end()) {
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
			
			if (existingCells.find(neighbour) == existingCells.end()) {
				continue;
			}
			
			// Check if points are already connected
			int currentID = existingCells[cellPos];
			int neighbourID = existingCells[neighbour];
			
			if (!astar->are_points_connected(currentID, neighbourID)) {
				returnArray.append(neighbourID);
			}
	}
	
	return returnArray;
}

PackedVector2Array FastPathfinding::find_path(const Vector2i& start, const Vector2i& end) {
	auto startIt = existingCells.find(start);
	auto endIt = existingCells.find(end);
	if (startIt == existingCells.end() || endIt == existingCells.end()) {
		return PackedVector2Array();
	}
	
	int startID = startIt->second;
	int endID = endIt->second;
	
	if (astar->has_point(startID) && astar->has_point(endID)) {
		// Store original end point weight
		float originalEndWeight = astar->get_point_weight_scale(endID);
		
		// Set end point weight to 1 for pathfinding
		astar->set_point_weight_scale(endID, 1.0f);
		
		uint64_t start_us = Time::get_singleton()->get_ticks_usec();
		PackedVector2Array result = astar->get_point_path(startID, endID);
		uint64_t end_us = Time::get_singleton()->get_ticks_usec();
		int64_t ms = static_cast<int64_t>((end_us - start_us) / 1000);
		
		
		// Restore original end point weight
		astar->set_point_weight_scale(endID, originalEndWeight);
		
		return result;
	} else {
		return PackedVector2Array();
	}
}

bool FastPathfinding::is_cell_accessible(const Vector2i& cellPos) {
	if (existingCells.find(cellPos) == existingCells.end()) {
		return false;
	}
	
	// Check all 8 surrounding cells for solid cells
	for (int i = 0; i < DIRECTIONS.size(); i++) {
		Vector2i direction = DIRECTIONS[i];
		Vector2i neighbour = cellPos + direction;
		
		if (solidCells.find(neighbour) == solidCells.end()) {
			return true;
		}
	}
	
	return false;
}

bool FastPathfinding::path_goes_through_solid(const PackedVector2Array& path) {
	// Check each point in the path to see if it's solid
	for (int i = 0; i < path.size(); i++) {
		Vector2i cellPos = Vector2i(path[i]);
		if (solidCells.find(cellPos) != solidCells.end()) {
			return true;
		}
	}
	return false;
}

void FastPathfinding::update_tile_point(const Vector2i& cellPos, const Dictionary& mapData) {
	auto it = existingCells.find(cellPos);
	if (it == existingCells.end()) {
		return;
	}
	
	int pointID = it->second;
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
				hasSolidFlag = true;
				break;
			}
		}
	}
	
	// Update solid cells tracking
	if (hasSolidFlag) {
		solidCells.insert(cellPos);
	} else {
		solidCells.erase(cellPos);
	}
	
	// Update point weight
	float weightScale = hasSolidFlag ? std::numeric_limits<float>::infinity() : 1.0f;
	astar->set_point_weight_scale(pointID, weightScale);
}

bool FastPathfinding::is_end_reachable(const Vector2i& end) {
	// Check if end cell exists
	if (existingCells.find(end) == existingCells.end()) {
		return false;
	}
	
	// Check if all 8 surrounding cells of end are solid (unreachable)
	bool allSurroundingSolid = true;
	for (int i = 0; i < DIRECTIONS.size(); i++) {
		Vector2i direction = DIRECTIONS[i];
		Vector2i neighbour = end + direction;
		if (existingCells.find(neighbour) != existingCells.end() && 
			solidCells.find(neighbour) == solidCells.end()) {
			allSurroundingSolid = false;
			break;
		}
	}
	
	return !allSurroundingSolid;
}

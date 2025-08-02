shader_type canvas_item;

uniform sampler2D terrain_data_texture : hint_default_black, filter_nearest;
uniform sampler2D atlas_texture : hint_default_white, filter_nearest;

uniform float tile_size : hint_range(16.0, 16.0) = 16.0;
uniform vec2 world_size = vec2(256.0, 256.0);
uniform vec2 atlas_tile_count = vec2(16.0, 16.0);

varying vec2 world_position;

void vertex() {
	world_position = VERTEX;
}

void fragment() {
	vec2 tile_coord = world_position / tile_size;
	vec2 tile_id = floor(tile_coord);
	
	if (tile_id.x < 0.0 || tile_id.x >= world_size.x || 
		tile_id.y < 0.0 || tile_id.y >= world_size.y) {
		discard;
	}
	
	vec2 data_uv = (tile_id + 0.5) / world_size;
	vec4 terrain_data = texture(terrain_data_texture, data_uv);
	
	float atlas_x = terrain_data.r * 255.0;
	float atlas_y = terrain_data.g * 255.0;
	float tile_exists = terrain_data.b;
	
	if (tile_exists < 0.5) {
		discard;
	}
	
	vec2 tile_uv = fract(tile_coord);
	
	vec2 atlas_pos = vec2(atlas_x, atlas_y);
	vec2 atlas_uv = (atlas_pos + tile_uv) / atlas_tile_count;
	
	COLOR = texture(atlas_texture, atlas_uv);
}
shader_type canvas_item;

const float time_factor = 4.0;
//const vec2 amplitude = vec2(10.0, 0.0);

void vertex(){
	VERTEX.x += cos(TIME * time_factor) * (VERTEX.y - 260.0) * 0.15;
//	VERTEX.y += sin(TIME * time_factor) * amplitude.y;
//	VERTEX.x += cos(TIME + VERTEX.y - 100.0) * 5.0 * 0.5;
}
shader_type canvas_item;

uniform float wave_speed = 5.0;
uniform float wave_frequency = 10.0;
uniform float wave_height = 5.0;

void vertex() {
    // Distorce a posição Y do vértice usando seno e o tempo
    VERTEX.y += sin((VERTEX.x * wave_frequency) + (TIME * wave_speed)) * wave_height;
}

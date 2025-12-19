shader_type canvas_item;

uniform float noise_strength : hint_range(0.0, 0.2) = 0.05;
uniform float noise_speed : hint_range(0.0, 3.0) = 0.3;

float random(vec2 p) {
    return fract( sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453 );
}

void fragment() {
    vec2 uv = FRAGCOORD.xy * 0.005;
    float n = random(uv + TIME * noise_speed);

    // negro base + ruido
    vec3 col = vec3(n * noise_strength);

    COLOR = vec4(col, 1.0);
}

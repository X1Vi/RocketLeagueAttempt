shader_type spatial;

uniform vec3 cloud_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 sky_color : source_color = vec3(0.5, 0.7, 1.0);
uniform float cloud_scale : hint_range(0.1, 10.0) = 1.0;
uniform float cloud_density : hint_range(0.0, 1.0) = 0.5;
uniform float time_scale : hint_range(0.0, 1.0) = 0.1;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.1;

// Noise functions
float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
                   mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
                   mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

float fbm(vec3 x) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; ++i) {
        v += a * noise(x);
        x = x * 2.0 + vec3(100.0);
        a *= 0.5;
    }
    return v;
}

void fragment() {
    // Get the world position of the fragment
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Animate the clouds
    world_pos += TIME * time_scale;
    
    // Generate cloud noise
    float cloud = fbm(world_pos * cloud_scale);
    
    // Apply density and edge softness
    cloud = smoothstep(1.0 - cloud_density, 1.0 - cloud_density + edge_softness, cloud);
    
    // Mix cloud color with sky color
    vec3 final_color = mix(sky_color, cloud_color, cloud);
    
    // Set the final color and alpha
    ALBEDO = final_color;
    ALPHA = cloud;
	
}
shader_type sky;

group_uniforms TimeControl;
uniform bool use_time_of_day = true;
uniform float time_of_day : hint_range(0.0, 24.0) = 12.0; // 0.0 to 24.0 hours

group_uniforms Section_Morning;
uniform vec4 sky_morning : source_color = vec4(0.2, 0.4, 0.7, 1.0);
uniform vec4 horizon_morning : source_color = vec4(0.9, 0.6, 0.4, 1.0);
uniform vec4 cloud_color_morning : source_color = vec4(0.9, 0.85, 0.8, 1.0);

group_uniforms Section_Afternoon_Evening;
uniform vec4 sky_afternoon : source_color = vec4(0.0, 0.3, 0.7, 1.0);
uniform vec4 horizon_afternoon : source_color = vec4(0.75, 0.85, 0.85, 1.0);
uniform vec4 cloud_color_afternoon : source_color = vec4(0.8, 0.8, 0.8, 1.0);

group_uniforms Section_Night;
uniform vec4 sky_night : source_color = vec4(0.02, 0.05, 0.1, 1.0);
uniform vec4 horizon_night : source_color = vec4(0.05, 0.1, 0.15, 1.0);
uniform vec4 cloud_color_night : source_color = vec4(0.2, 0.25, 0.3, 1.0);

group_uniforms Sky_Settings;
uniform float horizon_exponent = 2.0;

group_uniforms Clouds;
uniform sampler2D cloud_tex_01 : hint_default_black;
uniform sampler2D cloud_tex_02 : hint_default_black;
uniform vec2 cloud_tiling = vec2(1.0);
uniform vec2 wind_speed = vec2(0.5);
uniform float cloud_density : hint_range(0.0, 5.0, 0.1) = 0.7;
uniform float cloud_depth = 2.0;
uniform float cloud_shape_exponent = 2.0;
uniform float cloud_occlude_exponent = 1.0;

group_uniforms Stars;
uniform sampler2D night_noise_01 : hint_default_black;
uniform sampler2D night_noise_02 : hint_default_black;

group_uniforms Sun;
uniform float sun_scale = 0.05;
uniform float sun_strength = 15.0;
uniform vec4 sun_color : source_color = vec4(1.0, 0.9, 0.0, 1.0);

float plane_intersection(vec3 origin, vec3 normal, vec3 ray_start, vec3 ray_dir) {
	return dot(origin - ray_start, normal) / dot(ray_dir, normal);
}

float get_cloud_height(sampler2D tex, vec2 uv) {
	float height = texture(tex, uv).r;
	height = clamp((height - (1.0 - cloud_density)) / max(cloud_density, 0.001), 0.0, 1.0);
	return pow(height, cloud_shape_exponent);
}

void sky() {
	float t = plane_intersection(vec3(0.0, 1.0, 0.0), vec3(0.0, -1.0, 0.0), vec3(0.0), EYEDIR);
	
	// Calculate Sun Direction based on time_of_day
	vec3 light_dir = LIGHT0_DIRECTION;
	if (length(light_dir) < 0.001) {
		light_dir = vec3(0.0, 1.0, 0.0);
	}

	if (use_time_of_day) {
		float sun_angle = (time_of_day / 24.0) * 6.28318530718; // 2 * PI
		light_dir = normalize(vec3(sin(sun_angle), -cos(sun_angle), 0.2));
	}

	// Smooth 3-way time weights based on 24-hour clock
	float w_night = smoothstep(19.0, 22.0, time_of_day) + (1.0 - smoothstep(5.0, 7.0, time_of_day));
	w_night = clamp(w_night, 0.0, 1.0);
	
	float w_morning = smoothstep(5.0, 7.5, time_of_day) * (1.0 - smoothstep(11.0, 13.0, time_of_day));
	float w_afternoon = smoothstep(11.0, 13.5, time_of_day) * (1.0 - smoothstep(19.5, 21.5, time_of_day));

	float total_w = w_night + w_morning + w_afternoon + 0.0001;
	w_night /= total_w;
	w_morning /= total_w;
	w_afternoon /= total_w;

	// Blend colors across the 3 sections
	vec3 sky_color = (sky_night.rgb * w_night) + (sky_morning.rgb * w_morning) + (sky_afternoon.rgb * w_afternoon);
	vec3 horizon_color = (horizon_night.rgb * w_night) + (horizon_morning.rgb * w_morning) + (horizon_afternoon.rgb * w_afternoon);
	vec3 active_cloud_color = (cloud_color_night.rgb * w_night) + (cloud_color_morning.rgb * w_morning) + (cloud_color_afternoon.rgb * w_afternoon);

	vec3 sky = vec3(0.0);

	// Cloud calculations
	float cloud_value = 0.0;
	if(t >= 0.0){
		vec3 wind = vec3(wind_speed.x, 0.0, wind_speed.y) * TIME * 0.1;
		vec3 tiling = vec3(cloud_tiling.x, 1.0, cloud_tiling.y) * 0.2;
		vec3 cloud_pos1 = EYEDIR * t * tiling + wind;
		vec3 cloud_pos2 = EYEDIR * t * tiling + (wind * 0.5);

		float height1 = get_cloud_height(cloud_tex_01, cloud_pos1.xz);
		float height2 = get_cloud_height(cloud_tex_02, cloud_pos2.xz);
		cloud_pos1 += EYEDIR * height1 * cloud_depth * 0.1;
		cloud_pos2 += EYEDIR * height2 * cloud_depth * 0.1;
		height1 = get_cloud_height(cloud_tex_01, cloud_pos1.xz);
		height2 = get_cloud_height(cloud_tex_02, cloud_pos2.xz);
		cloud_value = min(height1, height1 * height2);

		cloud_value *= smoothstep(0.0, 0.2, EYEDIR.y);
	}

	// Sun calculation
	float sun_distance = clamp(1.0 - distance(EYEDIR, light_dir) - pow(cloud_value, cloud_occlude_exponent), 0.0, 1.0);
	float sun_disc = clamp(smoothstep(1.0 - sun_scale, 1.0, sun_distance), 0.0, 1.0);
	float sun_glow = clamp(0.0, 1.0, (pow(sun_distance, 4.0) * 0.07));
	vec3 sun = mix(vec3(0.0), sun_color.rgb * sun_strength, max(sun_disc, sun_glow));

	// Star calculations (only visible at night)
	float night_noise = texture(night_noise_02, (EYEDIR / ((1.0 - abs(t) * 0.05))).xz).r;
	float stars = smoothstep(0.9, 0.95, texture(night_noise_01, (EYEDIR / ((1.0 - abs(t) * 0.05))).xz).r);
	stars = clamp(clamp((stars - cloud_value * 2.0), 0.0, 1.0) * w_night, 0.0, 1.0) + (night_noise * 0.01);

	// Assemble final sky gradient
	sky = mix(sky_color, horizon_color, pow(1.0 - abs(EYEDIR.y), horizon_exponent));
	sky = mix(sky, active_cloud_color * 1.0, pow(cloud_value, 0.8));

	sky += stars * 1.0;

	sky = mix(sky, mix(sky_color * 0.5, horizon_color, clamp(EYEDIR.y + 1.0, 0.0, 1.0)).rgb, clamp(pow(1.0 - EYEDIR.y, 2.0), 0.0, 1.0));
	
	// Only show sun when it's above the horizon or during day/morning phases
	sky += sun * clamp(pow(EYEDIR.y + 1.0, 16.0), 0.0, 1.0) * (1.0 - (w_night * 0.95));

	COLOR = sky;
}
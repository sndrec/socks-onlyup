shader_type canvas_item;

uniform sampler2D in_mask;
uniform float in_time;

void fragment() {
	if (in_time <= 0.001)
	{
		COLOR = vec4(0);
		COLOR.a = 1.0;
	}else{
		vec2 use_uv = SCREEN_UV;
		
		use_uv -= 0.5;
		use_uv /= max(0.001, in_time * in_time);
		use_uv += 0.5;
		float ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
		use_uv.x *= ratio;
		use_uv.x -= ratio * 0.5;
		use_uv.x += 0.5;
		float mask = texture(in_mask, use_uv).r;
		COLOR = vec4(0);
		COLOR.a = 1.0 - mask;
	}
}
